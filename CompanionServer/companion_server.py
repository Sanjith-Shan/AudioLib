#!/usr/bin/env python3
"""
AudioLib Companion Server
Runs on your Mac; the iOS app calls this to resolve YouTube audio streams.
Usage: pip install -r requirements.txt && python companion_server.py
"""
import os, json
import subprocess
try:
    subprocess.run(['pip', 'install', '-q', '-U', 'yt-dlp'], timeout=30, capture_output=True)
except Exception:
    pass
from flask import Flask, request, jsonify, abort, after_this_request, send_file
import yt_dlp

import uuid, threading
from pathlib import Path

app = Flask(__name__)

YDL_OPTS = {
    'format': 'bestaudio[ext=m4a]/bestaudio[ext=webm]/bestaudio',
    'quiet': True,
    'no_warnings': True,
    'extract_flat': False,
    # As of mid-2025, `web`, `ios`, and `android` clients require PO Tokens and return 403.
    # `android_vr`, `tv`, and `web_safari` remain unthrottled and PO-Token-free.
    'extractor_args': {'youtube': {'player_client': ['android_vr', 'tv', 'web_safari']}},
}

DOWNLOAD_DIR = Path('/tmp/audiolib_downloads')
DOWNLOAD_DIR.mkdir(exist_ok=True)

# job_id -> dict with status, percent, speed, eta, filepath, error, title, ext
_jobs: dict = {}
_jobs_lock = threading.Lock()


@app.route('/resolve', methods=['POST'])
def resolve():
    data = request.get_json()
    if not data or 'url' not in data:
        abort(400, 'Missing "url" in request body')

    url = data['url']

    try:
        with yt_dlp.YoutubeDL(YDL_OPTS) as ydl:
            info = ydl.extract_info(url, download=False)
    except yt_dlp.utils.DownloadError as e:
        abort(500, f'yt-dlp extraction failed: {str(e)}')

    if not info:
        abort(404, 'No info returned by yt-dlp')

    video_id = info.get('id', '')
    audio_url = None
    file_ext = 'm4a'
    http_headers = {}

    formats = sorted(
        info.get('formats', []),
        key=lambda x: x.get('abr') or x.get('tbr') or 0,
        reverse=True
    )

    # First pass: prefer m4a
    for fmt in formats:
        if fmt.get('vcodec') == 'none' and fmt.get('acodec') not in (None, 'none') and fmt.get('ext') == 'm4a':
            audio_url = fmt.get('url')
            file_ext = 'm4a'
            http_headers = fmt.get('http_headers', {})
            break

    # Second pass: any audio-only
    if not audio_url:
        for fmt in formats:
            if fmt.get('vcodec') == 'none' and fmt.get('acodec') not in (None, 'none'):
                audio_url = fmt.get('url')
                file_ext = fmt.get('ext', 'webm')
                http_headers = fmt.get('http_headers', {})
                break

    if not audio_url:
        abort(404, 'No audio stream found')

    chapters = []
    for ch in info.get('chapters') or []:
        chapters.append({
            'title': ch.get('title', ''),
            'startSeconds': float(ch.get('start_time', 0))
        })

    return jsonify({
        'videoID': video_id,
        'title': info.get('title', 'Unknown'),
        'uploader': info.get('uploader', 'Unknown'),
        'durationSeconds': float(info.get('duration') or 0),
        'thumbnailURL': f'https://i.ytimg.com/vi/{video_id}/maxresdefault.jpg',
        'audioStreamURL': audio_url,
        'fileExtension': file_ext,
        'httpHeaders': http_headers,
        'chapters': chapters
    })


# -----------------------------------------------------------------------------
# Full-download endpoints — yt-dlp runs on the Mac (unthrottled), then the
# iPhone downloads the finished file from here over local WiFi.
# -----------------------------------------------------------------------------

def _run_job(job_id: str, url: str):
    """Worker thread body. Runs yt-dlp to completion, updating _jobs as we go."""

    def progress_hook(d):
        with _jobs_lock:
            if job_id not in _jobs:
                return
            if d['status'] == 'downloading':
                total = d.get('total_bytes') or d.get('total_bytes_estimate') or 0
                downloaded = d.get('downloaded_bytes', 0)
                _jobs[job_id]['percent'] = round((downloaded / total * 100), 1) if total > 0 else 0
                _jobs[job_id]['speed'] = d.get('speed') or 0
                _jobs[job_id]['eta'] = d.get('eta')
                _jobs[job_id]['status'] = 'downloading'
            elif d['status'] == 'finished':
                _jobs[job_id]['percent'] = 100

    opts = dict(YDL_OPTS)
    opts['outtmpl'] = str(DOWNLOAD_DIR / f'{job_id}.%(ext)s')
    opts['concurrent_fragment_downloads'] = 16
    opts['progress_hooks'] = [progress_hook]

    try:
        with yt_dlp.YoutubeDL(opts) as ydl:
            info = ydl.extract_info(url, download=True)

        ext = info.get('ext', 'm4a')
        actual = DOWNLOAD_DIR / f'{job_id}.{ext}'
        # yt-dlp might postprocess to a different ext; scan for the file
        for f in DOWNLOAD_DIR.glob(f'{job_id}.*'):
            actual = f
            ext = f.suffix.lstrip('.')
            break

        with _jobs_lock:
            if job_id in _jobs:
                _jobs[job_id].update({
                    'status': 'done',
                    'percent': 100.0,
                    'filepath': str(actual),
                    'ext': ext,
                    'title': info.get('title', '')
                })
    except Exception as e:
        with _jobs_lock:
            if job_id in _jobs:
                _jobs[job_id]['status'] = 'failed'
                _jobs[job_id]['error'] = str(e)


@app.route('/download/start', methods=['POST'])
def download_start():
    data = request.get_json()
    if not data or 'url' not in data:
        abort(400, 'Missing "url" in request body')

    url = data['url']
    job_id = uuid.uuid4().hex

    with _jobs_lock:
        _jobs[job_id] = {
            'status': 'pending',
            'percent': 0.0,
            'speed': 0,
            'eta': None,
            'filepath': None,
            'ext': None,
            'title': '',
            'error': None,
        }

    thread = threading.Thread(target=_run_job, args=(job_id, url), daemon=True)
    thread.start()

    return jsonify({'jobID': job_id})


@app.route('/download/<job_id>/progress', methods=['GET'])
def download_progress(job_id):
    with _jobs_lock:
        job = _jobs.get(job_id)
        if job is None:
            abort(404, 'Unknown job')
        return jsonify({
            'status': job.get('status', 'unknown'),
            'percent': job.get('percent', 0.0),
            'speedBytesPerSec': job.get('speed') or 0,
            'etaSeconds': job.get('eta'),
            'title': job.get('title', ''),
            'fileExtension': job.get('ext') or 'm4a',
            'error': job.get('error'),
        })


@app.route('/download/<job_id>/file', methods=['GET'])
def download_file(job_id):
    with _jobs_lock:
        job = _jobs.get(job_id)
        if job is None:
            abort(404, 'Unknown job')
        if job.get('status') != 'done':
            abort(404, 'Job not complete')
        filepath = job.get('filepath')

    if not filepath or not Path(filepath).exists():
        abort(404, 'File missing')

    @after_this_request
    def cleanup(response):
        try:
            Path(filepath).unlink(missing_ok=True)
            with _jobs_lock:
                _jobs.pop(job_id, None)
        except Exception:
            pass
        return response

    return send_file(filepath, as_attachment=True)


# ---------------------------------------------------------------------------
# Sync endpoints — progress hub shared between Mac and iPhone
# ---------------------------------------------------------------------------

SYNC_STATE_FILE = Path.home() / '.audiolib_sync.json'
_sync_lock = threading.Lock()


def _load_sync():
    if SYNC_STATE_FILE.exists():
        try:
            with open(SYNC_STATE_FILE) as f:
                return json.load(f)
        except Exception:
            pass
    return {'books': {}}


def _save_sync(state):
    with open(SYNC_STATE_FILE, 'w') as f:
        json.dump(state, f)


@app.route('/sync/state', methods=['GET'])
def sync_state():
    with _sync_lock:
        return jsonify(_load_sync())


@app.route('/sync/progress', methods=['POST'])
def sync_progress():
    data = request.get_json(force=True, silent=True) or {}
    book_id = data.get('bookID')
    if not book_id:
        return jsonify({'error': 'missing bookID'}), 400

    with _sync_lock:
        state = _load_sync()
        existing = state['books'].get(book_id, {})
        incoming_ts = data.get('lastPlayedAt', '')
        existing_ts = existing.get('lastPlayedAt', '')
        if incoming_ts >= existing_ts:
            state['books'][book_id] = {
                'bookID': book_id,
                'progressSeconds': data.get('progressSeconds', 0),
                'lastPlayedAt': incoming_ts,
                'title': data.get('title') or existing.get('title', ''),
                'sourceURL': data.get('sourceURL') or existing.get('sourceURL', ''),
                'durationSeconds': data.get('durationSeconds') or existing.get('durationSeconds', 0),
                'audioFilename': data.get('audioFilename') or existing.get('audioFilename', ''),
                'artFilename': data.get('artFilename') or existing.get('artFilename', ''),
            }
            _save_sync(state)
    return jsonify({'ok': True})


@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'ok', 'service': 'AudioLib Companion Server'})


if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8787))
    print(f'AudioLib Companion Server running on http://0.0.0.0:{port}')
    app.run(host='0.0.0.0', port=port, threaded=True)
