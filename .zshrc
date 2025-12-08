COMPLETION_WAITING_DOTS="true"
DISABLE_UNTRACKED_FILES_DIRTY="true" # disable marking untracked files under VCS as dirty
HIST_STAMPS="mm/dd/yyyy" # timestamp format in zsh history

# use starhsip
eval "$(starship init zsh)"

# set up fzf key bindings and fuzzy completion
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
source <(fzf --zsh)

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completio

alias vivaldi='open /Applications/Vivaldi.app'

autoload -U compinit; compinit # autocomplete

####
####
####

make_video() {
    local file_ext
    local frame_rate=30
    local remove_frames=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            [0-9]*)
                frame_rate=$1
                ;;
            rm)
                remove_frames=true
                ;;
            *)
                echo "Invalid argument: $1"
                echo "Usage: make_video [frame_rate] [rm]"
                return 1
                ;;
        esac
        shift
    done

    # Detect file extension
    if [[ -n $(find . -maxdepth 1 -type f -name "*.jpg") ]]; then
        file_ext="jpg"
    elif [[ -n $(find . -maxdepth 1 -type f -name "*.png") ]]; then
        file_ext="png"
    elif [[ -n $(find . -maxdepth 1 -type f -name "*.jpeg") ]]; then
        file_ext="jpeg"
    else
        echo "No supported (.jpg, .jpeg, .png) image files found in the current directory."
        return 1
    fi

    # Create video using ffmpeg
    ffmpeg -framerate $frame_rate -pattern_type glob -i "*.$file_ext" \
           -c:v libx264 -pix_fmt yuv420p out.mp4

    if [[ $? -eq 0 ]]; then
        echo "Video created successfully: out.mp4 with frame rate $frame_rate fps"

        # Remove frames if requested
        if $remove_frames; then
            rm *.$file_ext
            echo "Source image files have been removed."
        fi
    else
        echo "Error creating video. Please check if ffmpeg is installed and the image files are valid."
    fi
}

extract_frames() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: extract_frames <video.mp4>"
        return 1
    fi

    local video_path="$1"
    local video_name=$(basename "$video_path" .mp4)
    local output_dir="${video_name}_frames"

    if [[ ! -f "$video_path" ]]; then
        echo "Error: Video file '$video_path' not found."
        return 1
    fi

    mkdir -p "$output_dir"

    ffmpeg -i "$video_path" -q:v 1 -start_number 0 "$output_dir/%04d.png"

    echo "Frames extracted to $output_dir"
}

remove_white_background() {
    local output_dir="transparent_images"
    mkdir -p "$output_dir"

    for img in *.png; do
        if [[ -f "$img" ]]; then
            local basename=$(basename "$img")
            local filename="${basename%.*}"
            local extension="${basename##*.}"

            echo "Processing $img..."
            magick "$img" -fuzz 20% -transparent white "$output_dir/${filename}_transparent.png"
        fi
    done

    echo "Processed images are saved in the '$output_dir' directory."
}


# Function to extract a portion of a video
extract() {
    if [[ $# -ne 2 ]]; then
        echo "Usage: extract <direction> <path to mp4>"
        echo "Directions: left, right, top, bottom"
        return 1
    fi

    local direction="$1"
    local input_file="$2"
    local dir_name=$(dirname "$input_file")
    local file_name=$(basename "$input_file")
    local name_without_ext="${file_name%.*}"
    local output_file="${dir_name}/${name_without_ext}_${direction}.mp4"

    if [[ ! -f "$input_file" ]]; then
        echo "Error: File '$input_file' not found."
        return 1
    fi

    local filter=""
    case "$direction" in
        "left")
            filter="crop=iw/2:ih:0:0"
            ;;
        "right")
            filter="crop=iw/2:ih:iw/2:0"
            ;;
        "top")
            filter="crop=iw:ih/2:0:0"
            ;;
        "bottom")
            filter="crop=iw:ih/2:0:ih/2"
            ;;
        *)
            echo "Error: Invalid direction. Use left, right, top, or bottom."
            return 1
            ;;
    esac

    ffmpeg -i "$input_file" -filter:v "$filter" "$output_file"

    if [[ $? -eq 0 ]]; then
        echo "${direction^} portion of video extracted successfully. Output: $output_file"
    else
        echo "Error occurred while extracting ${direction} portion of the video."
    fi
}


# Function to extract the left half of a video
extract_left() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: extract_left <path to mp4>"
        return 1
    fi

    local input_file="$1"
    local dir_name=$(dirname "$input_file")
    local file_name=$(basename "$input_file")
    local name_without_ext="${file_name%.*}"
    local output_file="${dir_name}/${name_without_ext}_left.mp4"

    if [[ ! -f "$input_file" ]]; then
        echo "Error: File '$input_file' not found."
        return 1
    fi

    ffmpeg -i "$input_file" -filter:v "crop=iw/2:ih:0:0" "$output_file"

    if [[ $? -eq 0 ]]; then
        echo "Left half of video extracted successfully. Output: $output_file"
    else
        echo "Error occurred while extracting left half of the video."
    fi
}

# Function to extract the right half of a video
extract_right() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: extract_right <path to mp4>"
        return 1
    fi

    local input_file="$1"
    local dir_name=$(dirname "$input_file")
    local file_name=$(basename "$input_file")
    local name_without_ext="${file_name%.*}"
    local output_file="${dir_name}/${name_without_ext}_right.mp4"

    if [[ ! -f "$input_file" ]]; then
        echo "Error: File '$input_file' not found."
        return 1
    fi

    ffmpeg -i "$input_file" -filter:v "crop=iw/2:ih:iw/2:0" "$output_file"

    if [[ $? -eq 0 ]]; then
        echo "Right half of video extracted successfully. Output: $output_file"
    else
        echo "Error occurred while extracting right half of the video."
    fi
}

# Function to add a caption to a video
add_caption() {
    if [[ $# -ne 2 ]]; then
        echo "Usage: add_caption <video.mp4> <\"caption text\">"
        return 1
    fi

    local input_video="$1"
    local caption_text="$2"
    local dir_name=$(dirname "$input_video")
    local base_name=$(basename "$input_video" .mp4)
    local output_file="${dir_name}/${base_name}_captioned.mp4"

    # Check if input file exists
    if [[ ! -f "$input_video" ]]; then
        echo "Error: Video file '$input_video' not found."
        return 1
    fi

    # Get video dimensions
    local width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$input_video")
    local height=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$input_video")

    # Calculate text size (about 1/20th of video height)
    local font_size=$((height / 20))

    # Add caption using drawtext filter
    ffmpeg -i "$input_video" \
        -vf "drawtext=text='${caption_text}': \
            fontcolor=white: \
            fontsize=${font_size}: \
            box=1: \
            boxcolor=black@0.5: \
            boxborderw=5: \
            x=(w-text_w)/2: \
            y=10" \
        -codec:a copy \
        -c:v libx264 \
        "$output_file"

    if [[ $? -eq 0 ]]; then
        echo "Caption added successfully. Output: $output_file"
    else
        echo "Error occurred while adding caption."
    fi
}

# Function to concatenate two videos horizontally with height alignment
concat_horizontal() {
    if [[ $# -ne 2 ]]; then
        echo "Usage: concat_horizontal <left_video.mp4> <right_video.mp4>"
        return 1
    fi
    local left_video="$1"
    local right_video="$2"
    local dir_name=$(dirname "$left_video")
    local left_name=$(basename "$left_video" .mp4)
    local right_name=$(basename "$right_video" .mp4)
    local output_file="${dir_name}/${left_name}_${right_name}_combined.mp4"

    # Check if input files exist
    if [[ ! -f "$left_video" ]]; then
        echo "Error: Left video file '$left_video' not found."
        return 1
    fi
    if [[ ! -f "$right_video" ]]; then
        echo "Error: Right video file '$right_video' not found."
        return 1
    fi

    # Get video heights using ffprobe
    local height1=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$left_video")
    local height2=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$right_video")

    # Determine which video needs scaling
    if [ "$height1" -gt "$height2" ]; then
        # First video is taller, scale it down
        local scale_cmd="[0:v]scale=-1:${height2}[left];[1:v]setpts=PTS-STARTPTS[right];[left][right]"
    elif [ "$height1" -lt "$height2" ]; then
        # Second video is taller, scale it down
        local scale_cmd="[0:v]setpts=PTS-STARTPTS[left];[1:v]scale=-1:${height1}[right];[left][right]"
    else
        # Heights are equal, no scaling needed
        local scale_cmd="[0:v][1:v]"
    fi

    # Concatenate videos with scaling
    ffmpeg -i "$left_video" -i "$right_video" \
        -filter_complex "${scale_cmd}hstack=inputs=2[v]" \
        -map "[v]" \
        -c:v libx264 \
        "$output_file"

    if [[ $? -eq 0 ]]; then
        echo "Videos concatenated horizontally with height alignment. Output: $output_file"
    else
        echo "Error occurred while concatenating videos."
    fi
}

# Function to concatenate two videos vertically
concat_vertical() {
    if [[ $# -ne 2 ]]; then
        echo "Usage: concat_vertical <top_video.mp4> <bottom_video.mp4>"
        return 1
    fi
    local top_video="$1"
    local bottom_video="$2"
    local dir_name=$(dirname "$top_video")
    local top_name=$(basename "$top_video" .mp4)
    local bottom_name=$(basename "$bottom_video" .mp4)
    local output_file="${dir_name}/${top_name}_${bottom_name}_combined.mp4"

    if [[ ! -f "$top_video" ]]; then
        echo "Error: Top video file '$top_video' not found."
        return 1
    fi
    if [[ ! -f "$bottom_video" ]]; then
        echo "Error: Bottom video file '$bottom_video' not found."
        return 1
    fi

    # Get video dimensions using ffprobe
    local top_width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$top_video")
    local bottom_width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$bottom_video")

    if [[ $top_width -gt $bottom_width ]]; then
        # Scale top video to match bottom video width, ensuring even dimensions
        ffmpeg -i "$top_video" -i "$bottom_video" -filter_complex \
            "[0:v]scale='if(mod(${bottom_width},2),${bottom_width}+1,${bottom_width})':2*trunc(ih*${bottom_width}/${top_width}/2)[top]; \
             [top][1:v]vstack=inputs=2[v]" \
            -map "[v]" -c:v libx264 "$output_file"
    else
        # Scale bottom video to match top video width, ensuring even dimensions
        ffmpeg -i "$top_video" -i "$bottom_video" -filter_complex \
            "[1:v]scale='if(mod(${top_width},2),${top_width}+1,${top_width})':2*trunc(ih*${top_width}/${bottom_width}/2)[bottom]; \
             [0:v][bottom]vstack=inputs=2[v]" \
            -map "[v]" -c:v libx264 "$output_file"
    fi

    if [[ $? -eq 0 ]]; then
        echo "Videos concatenated vertically. Output: $output_file"
    else
        echo "Error occurred while concatenating videos."
    fi
}

change_fps() {
    local video="$1"
    local fps="$2"
    local new=$(basename "$video" .mp4)
    local output_file="${new}_${fps}.mp4"
    ffmpeg -i $video -filter:v fps=$fps $output_file
}

####
####
####


function make_videos() {
 for dir in "$@"; do
   (cd "$dir" && make_video && mv out.mp4 "../$dir.mp4")
 done
}
#

add_frames() { ffmpeg -i "$1" -vf "drawtext=text='%{frame_num}':x=10:y=(h-text_h)/2:fontcolor=white:fontsize=48:box=1:boxcolor=black@0.5" -codec:a copy -c:v libx264 "${1%.*}_numbered.mp4"; }

# ATUIN
# . "$HOME/.atuin/bin/env"
# eval "$(atuin init zsh)"

# EZA
alias l="eza -l --icons --git -a"
alias lt="eza --tree --level=2 --long --icons --git"
alias ltree="eza --tree --level=2  --icons --git"
cx() { cd "$@" && l; }

# add texpresso && texpresso-tonic to PATH, s.t. it's automatically detected by ZED
# export PATH="/Users/mizeller/texpresso/build:$PATH"

alias goldeneye="ssh goldeneye"

alias scratchpad="nvim ~/scratch/.scratch.md"
alias scratchslides="open ~/scratch/.scratch.key"

source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

if type brew &>/dev/null; then
FPATH=$(brew --prefix)/share/zsh-completions:$FPATH

autoload -Uz compinit
compinit
fi


zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'



# create placeholder .png of certain dimension w/ random color/name
placeholder() {
  local h=$1
  local w=$2
  local text=${3:-"Placeholder ${h}x${w}"}
  local color=$(openssl rand -hex 3 | sed 's/^/#/')
  local clean_color=$(echo "$color" | tr -d '#')   # strip '#' for filename
  local filename="placeholder_${h}_${w}_${clean_color}.png"

  magick -size ${w}x${h} xc:"$color" \
    -gravity center \
    -pointsize $(( (h<w?h:w) / 10 )) \
    -fill white -annotate 0 "$text" \
    "$filename"

  echo "Created $filename with background $color"
}


# aliases for whitebook tunnel 
alias wb_tunnel='~/projects/whitebook/tunnel.sh'

# alias to start python base environment
alias python-init='source ~/.python-base/bin/activate'


# open excalidraw in a private vivaldi window and move to second monitor (ipad)
alias sketchpad='open -na "Vivaldi" --args --incognito "https://excalidraw.com" && sleep 1 && aerospace focus --window-id $(aerospace list-windows --focused | awk "{print \$1}") && aerospace move-node-to-monitor --wrap-around next --focus-follows-window'
alias scratchdrawing="vivaldi \"https://excalidraw.com/#json=\$(cat ~/scratch/.scratch.excalidraw | jq -sRr @uri)\""
export PATH="$HOME/.cargo/bin:$PATH"
