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

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <path_to_prompt> <path_to_files_list>"
    exit 1
fi

# Call the function with the command-line arguments
prepare_request "$1" "$2"
