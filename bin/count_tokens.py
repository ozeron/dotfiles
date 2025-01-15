#!/usr/bin/env python3

import tiktoken

def count_tokens_in_file(file_path):
    # Initialize the tokenizer
    tokenizer = tiktoken.get_encoding("gpt2")

    # Read the file content
    with open(file_path, 'r', encoding='utf-8') as file:
        content = file.read()

    # Tokenize the content
    tokens = tokenizer.encode(content)

    # Return the number of tokens
    return len(tokens)

if __name__ == "__main__":
    import sys

    if len(sys.argv) != 2:
        print("Usage: python count_tokens.py <file_path>")
        sys.exit(1)

    file_path = sys.argv[1]
    token_count = count_tokens_in_file(file_path)
    print(f"Number of tokens in the file: {token_count}")
