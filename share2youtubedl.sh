#!/bin/bash
clear

DOWNLOAD_PATH="~/home/Downloads/"
PLAYLIST="%(extractor)s/playlists/%(playlist_title)s_%(playlist_id)s/%(n_entries-playlist_index)03d - %(uploader)s - %(title)s [%(id)s].%(ext)s"
CHANNEL="%(extractor)s/channel/%(uploader)s_%(channel_id)s/%(title)s [%(id)s].%(ext)s"
CONFIG_PATH="${HOME}/.config/yt-dlp/"

function echo_bold() { echo -ne "\033[0;1;34m${*}${NC}\n"; }
function echo_success() { echo -ne "\033[1;32m${*}${NC}\n"; }
function echo_warning() { echo -ne "\033[1;33m${*}${NC}\n"; }
function echo_danger() { echo -ne "\033[1;31m${*}${NC}\n"; }
function echo_error() { echo -ne "\033[0;1;31merror:\033[0;31m\t${*}${NC}\n"; }

function isSponsorblockAlive() {
    #* HTTP/2 400 = bad request = api is working 1
    #* HTTP/2 200 = ok = api is working 1
    #! HTTP/2 404 = not found = api is not working 0
    #! HTTP/2 500 = internal server error = api is not working 0
    res=$(curl -Is https://sponsor.ajay.app/api/skipSegments | grep "HTTP" | awk '{print $2}')
    if [ "$res" == "200" ] || [ "$res" == "400" ]; then
        echo_success "sponsorblock api is working"
        return 1
    else
        echo_warning "sponsorblock api is not working"
        return 0
    fi
}

function downloadVideo() {
    echo -e "\\nDownloading video...\\n"
    yt-dlp --config-locations "${CONFIG_PATH}ytdl.config" -F "$1"
    echo_warning "Choose your video quality (<enter> for: 'best'):"
    read -p "" video
    echo_warning "Choose your audio quality (<enter> for: 'best'):"
    read -p "" audio
    echo_warning "Input video name:"
    read -p "" name

    if [[ "$video" = "" ]]; then
        video="best"
    fi
    if [[ "$audio" = "" ]]; then
        audio="best"
    fi
    if [[ "$name" = "" ]]; then
        name="%(title).40s [%(id)s].%(ext)s"
    fi
        yt-dlp --config-locations "${CONFIG_PATH}ytdl.config" -o "$name" -f "$video"+"$audio" "$1"
}

function downloadChannel() {
    echo "Downloading channel..."
        yt-dlp --config-locations "${CONFIG_PATH}ytdl.config" -o "$CHANNEL" "$1"

}

function downloadPlaylist() {
    echo "Downloading playlist..."
        yt-dlp --config-locations "${CONFIG_PATH}ytdl.config" -P $DOWNLOAD_PATH -o "$PLAYLIST" "$1"
}

function downloadAudio() {
    echo "Downloading audio..."
        yt-dlp --config-locations "${CONFIG_PATH}ytdl.config" -P $DOWNLOAD_PATH -x "$1"
}

# If shared element is a youtube link
if [[ "$1" =~ ^.*youtu.*$ ]] || [[ "$1" =~ ^.*youtube.*$ ]]; then
    echo_bold "Downloading...\\n>URL: ${1}"
    echo_warning "Choose between the following options:"
    echo_bold "1. Video mode (choose quality and name)"
    echo_bold "2. Playlist mode"
    echo_bold "3. Channel mode"
    echo_bold "4. Audio only mode"

    echo_warning "Enter your choice:"
    read -p "" choice

    case $choice in
    1)
        downloadVideo "$1"
        ;;
    2)
        downloadPlaylist "$1"
        ;;
    3)
        downloadChannel "$1"
        ;;
    4)
        downloadAudio "$1"
        ;;
    *)
        echo_error "\\nInvalid choice!\\n"
        ;;
    esac

# Weird case i don't know when it happens
elif [[ "$1" =~ ^.*nourlselected.*$ ]]; then
    echo "There was an error"

# If shared element is NOT a youtube link
else
    yt-dlp --config-locations "${CONFIG_PATH}ytdl.config" -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best' "$1"
fi

read -p "Press enter to continue"
