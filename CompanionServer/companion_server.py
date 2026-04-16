#!/usr/bin/env python3
"""
AudioLib Companion Server
Runs on your Mac; the iOS app calls this to resolve YouTube audio streams.
Usage: pip install -r requirements.txt && python companion_server.py
"""
import os, json
from flask import Flask, request, jsonify, abort
import yt_dlp

app = Flask(__name__)


@app.route('/resolve', methods=['POST'])
def resolve():
    data = request.get_json()
    if not data or 'url' not in data:
        abort(400, 'Missing "url" in request body')

    url = data['url']

    ydl_opts = {
        'format': 'bestaudio[ext=m4a]/bestaudio',
        'quiet': True,
        'no_warnings': True,
        'extract_flat': False,
    }

    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        info = ydl.extract_info(url, download=False)

    video_id = info.get('id', '')
    audio_url = None
    file_ext = 'm4a'

    # Find best audio format — prefer m4a, fall back to any audio-only
    formats = sorted(
        info.get('formats', []),
        key=lambda x: x.get('abr', 0) or 0,
        reverse=True
    )

    # First pass: prefer m4a
    for fmt in formats:
        if fmt.get('vcodec') == 'none' and fmt.get('acodec') != 'none' and fmt.get('ext') == 'm4a':
            audio_url = fmt.get('url')
            file_ext = 'm4a'
            break

    # Second pass: any audio-only
    if not audio_url:
        for fmt in formats:
            if fmt.get('vcodec') == 'none' and fmt.get('acodec') != 'none':
                audio_url = fmt.get('url')
                file_ext = fmt.get('ext', 'webm')
                break

    if not audio_url:
        abort(404, 'No audio stream found')

    # Parse chapters from yt-dlp chapter metadata
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
        'durationSeconds': float(info.get('duration', 0)),
        'thumbnailURL': f'https://i.ytimg.com/vi/{video_id}/maxresdefault.jpg',
        'audioStreamURL': audio_url,
        'fileExtension': file_ext,
        'chapters': chapters
    })


@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'ok', 'service': 'AudioLib Companion Server'})


if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8787))
    print(f'AudioLib Companion Server running on http://0.0.0.0:{port}')
    app.run(host='0.0.0.0', port=port)
