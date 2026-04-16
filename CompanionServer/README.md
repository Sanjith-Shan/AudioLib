# AudioLib Companion Server

A lightweight Flask server that runs on your Mac and resolves YouTube audio stream URLs using yt-dlp. The AudioLib iOS app can call this server instead of (or as a fallback to) the on-device resolver.

## Requirements

- Python 3.9+
- pip

## Setup

```bash
cd CompanionServer
pip install -r requirements.txt
python companion_server.py
```

The server starts on port **8787** by default. Override with the `PORT` environment variable:

```bash
PORT=9000 python companion_server.py
```

## Endpoints

### `POST /resolve`

Resolves a YouTube URL into audio stream metadata.

**Request body (JSON):**
```json
{ "url": "https://www.youtube.com/watch?v=XXXXXXXXXXX" }
```

**Response (JSON):**
```json
{
  "videoID": "XXXXXXXXXXX",
  "title": "Video Title",
  "uploader": "Channel Name",
  "durationSeconds": 123.0,
  "thumbnailURL": "https://i.ytimg.com/vi/XXXXXXXXXXX/maxresdefault.jpg",
  "audioStreamURL": "https://...",
  "fileExtension": "m4a",
  "chapters": [
    { "title": "Introduction", "startSeconds": 0.0 },
    { "title": "Chapter 2",    "startSeconds": 65.0 }
  ]
}
```

### `GET /health`

Returns `{"status": "ok"}` — use this to verify the server is running.

## Configuring the iOS App

In the AudioLib app Settings screen, switch the resolver mode to **Companion Server** and enter your Mac's local IP address and port (default 8787).

The UserDefaults keys used by the app are:
- `audiolib.resolverMode` — `"onDevice"` (default) or `"companion"`
- `audiolib.companionHost` — hostname or IP of the Mac running this server
- `audiolib.companionPort` — port (default 8787)

## Notes

- YouTube audio stream URLs expire after a few hours; resolve immediately before downloading.
- The server prefers m4a (AAC) streams. If unavailable, it returns the best available audio-only format (often webm/opus).
- Keep your Mac awake and on the same network as your iPhone, or use a tunneling tool (e.g. ngrok) for remote access.
