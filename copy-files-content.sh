#!/bin/sh

usage() {
    echo "Usage: $(basename "$0") [-i DIR]... [-x PATTERN]... [DIR]" >&2
    echo "  -i DIR       Ignore directories named DIR. Can be used multiple times." >&2
    echo "               Defaults: node_modules, target." >&2
    echo "  -x PATTERN   Ignore files matching PATTERN, such as '*.svg'." >&2
    echo "               Can be used multiple times." >&2
}

dir_path=.
dir_path_set=0
ignored_dirs='node_modules
target'
ignored_file_patterns=''

while [ "$#" -gt 0 ]; do
    case "$1" in
        -i)
            if [ "$#" -lt 2 ]; then
                echo "Error: -i requires a directory name." >&2
                usage
                exit 1
            fi
            ignored_dirs="${ignored_dirs}
$2"
            shift 2
            ;;
        -x|--exclude|--ignore-file)
            if [ "$#" -lt 2 ]; then
                echo "Error: $1 requires a file pattern." >&2
                usage
                exit 1
            fi
            ignored_file_patterns="${ignored_file_patterns}
$2"
            shift 2
            ;;
        --exclude=*|--ignore-file=*)
            ignored_file_patterns="${ignored_file_patterns}
${1#*=}"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
        -*)
            echo "Error: unknown option: $1" >&2
            usage
            exit 1
            ;;
        *)
            if [ "$dir_path_set" -eq 1 ]; then
                echo "Error: only one directory path can be provided." >&2
                usage
                exit 1
            fi
            dir_path=$1
            dir_path_set=1
            shift
            ;;
    esac
done

while [ "$#" -gt 0 ]; do
    if [ "$dir_path_set" -eq 1 ]; then
        echo "Error: only one directory path can be provided." >&2
        usage
        exit 1
    fi
    dir_path=$1
    dir_path_set=1
    shift
done

set -- "$dir_path" -type d "("
first_ignore=1
while IFS= read -r ignored_dir; do
    [ -z "$ignored_dir" ] && continue

    if [ "$first_ignore" -eq 1 ]; then
        set -- "$@" -name "$ignored_dir"
        first_ignore=0
    else
        set -- "$@" -o -name "$ignored_dir"
    fi
done <<EOF
$ignored_dirs
EOF

if [ "$first_ignore" -eq 1 ]; then
    set -- "$dir_path" -type f
else
    set -- "$@" ")" -prune -o -type f
fi

first_pattern=1
while IFS= read -r ignored_file_pattern; do
    [ -z "$ignored_file_pattern" ] && continue

    if [ "$first_pattern" -eq 1 ]; then
        set -- "$@" "!" "(" -name "$ignored_file_pattern"
        first_pattern=0
    else
        set -- "$@" -o -name "$ignored_file_pattern"
    fi
done <<EOF
$ignored_file_patterns
EOF

if [ "$first_pattern" -eq 0 ]; then
    set -- "$@" ")"
fi

set -- "$@" -print

find "$@" | while IFS= read -r file; do
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

#!/bin/sh
# dir_path=${1:-.}
#
# find "$dir_path" -type f | while read -r file; do
#     # Check if the file is a text file
#     if file "$file" | grep -q 'text'; then
#         echo "### $file ###"
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
