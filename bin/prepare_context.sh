#!/bin/bash

# Define the function
prepare_request() {
    local prompt_path="$1"
    local files_list_path="$2"

    # Output the prompt
    cat "$prompt_path"

    # Iterate over each file path in files.txt
    while IFS= read -r file_path; do
        echo "<FILE>"
        echo "# $file_path"
        cat "$file_path"
        echo "</FILE>"
    done < "$files_list_path"
}

# Function to display help
show_help() {
    echo "Usage: $0 <path_to_prompt> <path_to_files_list>"
    echo
    echo "This script reads a prompt from a specified file and iterates over a list of file paths,"
    echo "outputting the contents of each file wrapped in <FILE> tags."
    echo
    echo "Options:"
    echo "  --help    Display this help message and exit"
}

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    if [ "$1" == "--help" ]; then
        show_help
        exit 0
    else
        echo "Error: Incorrect number of arguments."
        show_help
        exit 1
    fi
fi

# Call the function with the command-line arguments
prepare_request "$1" "$2"
