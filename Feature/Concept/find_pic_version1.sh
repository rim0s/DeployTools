#!/bin/bash

find_pic() {
    local ltmp_width_range=""
    local ltmp_height_range=""
    local ltmp_from_dir=""
    local ltmp_action=""
    local ltmp_target_dir=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -w)
                ltmp_width_range="$2"
                shift 2
                ;;
            -h)
                ltmp_height_range="$2"
                shift 2
                ;;
            --mv)
                ltmp_action="mv"action
                shift 2
                ;;
            --cp)
                ltmp_action="cp"
                ltmp_target_dir="$2"
                shift 2
                ;;
            *)
                if [[ -z "$ltmp_from_dir" ]]; then
                    ltmp_from_dir="$1"
                    shift
                else
                    echo "Usage: find_pic -w ltmp_width_range -h ltmp_height_range ltmp_from_dir [--mv|--cp ltmp_target_dir]"
                    return 1
                fi
                ;;
        esac
    done


    # Check if required arguments are provided
    if [[ -z "$ltmp_width_range" || -z "$ltmp_height_range" || -z "$ltmp_from_dir" ]]; then
        echo "Usage: find_pic -w ltmp_width_range -h ltmp_height_range ltmp_from_dir [--mv|--cp ltmp_target_dir]"
        return 1
    fi

    # Extract width and height ranges
    IFS='-' read -r width_min width_max <<< "$ltmp_width_range"
    IFS='-' read -r height_min height_max <<< "$ltmp_height_range"
    
    echo "width_min=$width_min,width_max=$width_max,height_min=$height_min,height_max=$height_max,ltmp_from_dir=$ltmp_from_dir,ltmp_action=$ltmp_action,ltmp_target_dir=$ltmp_target_dir"
    # Find and process images
    #find "$ltmp_from_dir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" \) | while read -r file; do
    find "$ltmp_from_dir" -type f | while read -r file; do
        width=$(identify -format "%W" "$file" 2> /dev/null)
        height=$(identify -format "%H" "$file" 2> /dev/null)

        if [[ "$width" -ge "$width_min" && "$width" -le "$width_max" && "$height" -ge "$height_min" && "$height" -le "$height_max" ]]; then
            
            # Process the image
            if [[ -n "$ltmp_action" ]]; then
                echo "Fond: $file, width: $width, height: $height"
                if [[ "$ltmp_action" == "mv" ]]; then
                    #mv "$file" "$ltmp_target_dir" || { echo "Failed to move $file"; return 1; }
                    echo "Moveing: $file to $ltmp_target_dir"
                    mv "$file" "$ltmp_target_dir" || { echo "Failed to move $file"; }
                elif [[ "$ltmp_action" == "cp" ]]; then
                    #cp "$file" "$ltmp_target_dir" || { echo "Failed to copy $file"; return 1; }
                    echo "Copying: $file to $ltmp_target_dir"
                    cp "$file" "$ltmp_target_dir" || { echo "Failed to copy $file"; }
                fi
            fi
        fi
    done

    # Check if any images were found
    #if [[ -z "$(find "$ltmp_from_dir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" \))" ]]; then
    if [[ -z "$(find "$ltmp_from_dir" -type f )" ]]; then
        echo "No images found in $ltmp_from_dir" 
    fi

    return 0
}

find_pic "$@"

# Example usage:
# find_pic -w "500-600" -h "780-790" "/home/saint/Pictures"
# find_pic -w "500-600" -h "780-790" "/home/saint/Pictures" --mv "/home/saint/backup/myPicture"
