#!/data/data/com.termux/files/usr/bin/bash

# ======================================================
# Termux Live HLS Broadcaster Script
# Turns a local MP4 into a public IPTV (HLS) link
# ======================================================

# -------- CONFIG --------
VIDEO="$HOME/storage/shared/Download/input.mp4"   # Change if needed
OUTDIR="$HOME/hlsstream"
NGROK_ZIP="ngrok-stable-linux-arm.zip"
NGROK_URL="https://bin.equinox.io/c/4VmDzA7iaHb/$NGROK_ZIP"

# -------- FUNCTIONS --------
install_packages() {
    echo "📦 Installing dependencies..."
    pkg update -y && pkg upgrade -y
    pkg install ffmpeg python wget unzip -y
}

install_ngrok() {
    if ! command -v ngrok &>/dev/null; then
        echo "⬇️ Downloading ngrok..."
        wget "$NGROK_URL" -O $NGROK_ZIP
        unzip -o $NGROK_ZIP
        mv ngrok $PREFIX/bin/
        rm -f $NGROK_ZIP
        echo "✅ ngrok installed!"
    else
        echo "✅ ngrok already installed."
    fi
}

setup_ngrok_token() {
    if [ ! -f "$HOME/.ngrok2/ngrok.yml" ]; then
        echo "⚠️ You need an ngrok authtoken."
        echo "👉 Get it free from https://dashboard.ngrok.com/get-started/your-authtoken"
        read -p "Paste your ngrok authtoken here: " TOKEN
        ngrok config add-authtoken $TOKEN
        echo "✅ ngrok authtoken configured!"
    else
        echo "✅ ngrok already configured."
    fi
}

start_stream() {
    mkdir -p "$OUTDIR"
    cd "$OUTDIR"

    echo "🎥 Starting FFmpeg live stream from $VIDEO ..."
    ffmpeg -re -stream_loop -1 -i "$VIDEO" \
      -c:v libx264 -preset veryfast -c:a aac -ar 44100 -f hls \
      -hls_time 4 -hls_list_size 6 -hls_flags delete_segments \
      stream.m3u8 >/dev/null 2>&1 &

    sleep 3

    echo "🌍 Starting local HTTP server..."
    nohup python3 -m http.server 8080 >/dev/null 2>&1 &

    sleep 3

    echo "🚀 Starting ngrok tunnel..."
    echo "---------------------------------------------"
    echo "💡 Your IPTV link will appear below:"
    echo "---------------------------------------------"
    ngrok http 8080
}

# -------- MAIN --------
install_packages
install_ngrok
setup_ngrok_token
start_stream
