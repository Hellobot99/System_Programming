import random
import argparse
import urllib.request
import os

LOCAL_WORD_FILE = "words.txt"

SEPARATORS = [" ", " ", " ", " ", "\t", "\n"]

def load_words():
    with open(LOCAL_WORD_FILE, "r", encoding="utf-8") as f:
        return [line.strip() for line in f if line.strip().isalpha()]

def generate_text(num_words, output_file, word_list):
    with open(output_file, "w", encoding="utf-8") as f:
        for _ in range(num_words):
            word = random.choice(word_list)
            sep = random.choice(SEPARATORS)
            f.write(word + sep)
    print(f"Generated {num_words} words in '{output_file}'")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate large word-count test file.")
    parser.add_argument("num_words", type=int, help="Number of words to generate")
    parser.add_argument("output_file", help="Output file path")
    args = parser.parse_args()

    word_list = load_words()
    generate_text(args.num_words, args.output_file, word_list)

