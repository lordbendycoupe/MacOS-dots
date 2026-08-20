#!/usr/bin/env zsh

# Carried over from ~/dotfiles/.config/sketchybar/plugins-laptop/spotify.sh,
# with each state now given its own solid box to match the other modules.
MAX_LENGTH=30
HALF_LENGTH=$(((MAX_LENGTH + 1) / 2))
SPOTIFY_JSON="$INFO"
DARK=0xff24273a
IDLE_BOX=0xff5b6078

update_track() {
    if [[ -z $SPOTIFY_JSON ]]; then
        sketchybar --set $NAME icon.color=0xffcad3f5 label.drawing=off background.color=$IDLE_BOX
        return
    fi

    PLAYER_STATE=$(echo "$SPOTIFY_JSON" | jq -r '.["Player State"]')

    if [ "$PLAYER_STATE" = "Playing" ]; then
        TRACK="$(echo "$SPOTIFY_JSON" | jq -r .Name)"
        ARTIST="$(echo "$SPOTIFY_JSON" | jq -r .Artist)"

        TRACK_LENGTH=${#TRACK}
        ARTIST_LENGTH=${#ARTIST}

        if [ $((TRACK_LENGTH + ARTIST_LENGTH)) -gt $MAX_LENGTH ]; then
            if [ $TRACK_LENGTH -gt $HALF_LENGTH ] && [ $ARTIST_LENGTH -gt $HALF_LENGTH ]; then
                TRACK="${TRACK:0:$((MAX_LENGTH % 2 == 0 ? HALF_LENGTH - 2 : HALF_LENGTH - 1))}…"
                ARTIST="${ARTIST:0:$((HALF_LENGTH - 2))}…"
            elif [ $TRACK_LENGTH -gt $HALF_LENGTH ]; then
                TRACK="${TRACK:0:$((MAX_LENGTH - ARTIST_LENGTH - 1))}…"
            elif [ $ARTIST_LENGTH -gt $HALF_LENGTH ]; then
                ARTIST="${ARTIST:0:$((MAX_LENGTH - TRACK_LENGTH - 1))}…"
            fi
        fi
        sketchybar --set $NAME label="${TRACK}  ${ARTIST}" label.drawing=on label.color=$DARK icon.color=$DARK background.color=0xffa6da95

    elif [ "$PLAYER_STATE" = "Paused" ]; then
        sketchybar --set $NAME icon.color=0xffcad3f5 label.drawing=off background.color=$IDLE_BOX
    else
        sketchybar --set $NAME icon.color=0xffcad3f5 label.drawing=off background.color=$IDLE_BOX
    fi
}

case "$SENDER" in
"mouse.clicked")
    osascript -e 'tell application "Spotify" to playpause' 2>/dev/null
    ;;
*)
    update_track
    ;;
esac
