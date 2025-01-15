#!/bin/bash

function find_word_in_directory() {
    local word=$1
    local directory=$2
    grep -rl "$word" "$directory" | sort -u | sed 's://*:/:g'
}

function output_file_content() {
    local file=$1
    echo "# $file"
    cat "$file"
    echo -e "\n# END"
}

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <word> <directory>"
    exit 1
fi

# Find files and output their content
files=($(find_word_in_directory "$1" "$2"))
for ((i=0; i<${#files[@]}; i++)); do
    output_file_content "${files[i]}"
    if [ $i -lt $((${#files[@]} - 1)) ]; then
        echo -e "\n# NEXT_FILE"
    fi
done
