#!/bin/sh
dir_path=${1:-.}

find "$dir_path" -type f | while read -r file; do
    # Check if the file is a text file
    if file "$file" | grep -q 'text'; then
        echo "### $file ###"
        echo
        cat "$file"
        echo -e "\n\n"
    else
        # For binary files, display only the filename
        echo "### $(basename "$file") ###"
        echo
        echo "[Binary file content omitted]"
        echo -e "\n\n"
    fi
done | xclip -selection clipboard
# find . -type f | while read -r file; do
#     # Check if the file is a text file
#     if file "$file" | grep -q 'text'; then
#         echo "### $(basename "$file") ###"
#         echo
#         cat "$file"
#         echo -e "\n\n"
#     else
#         # For binary files, display only the filename
#         echo "### $(basename "$file") ###"
#         echo
#         echo "[Binary file content omitted]"
#         echo -e "\n\n"
#     fi
# done | xclip -selection clipboard
# find . -type f | while read -r file; do echo "### $(basename "$file") ###"; echo; cat "$file"; echo -e "\n\n"; done | xclip -selection clipboard
