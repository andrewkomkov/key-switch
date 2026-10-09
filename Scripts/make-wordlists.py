#!/usr/bin/env python3
"""Build the word lists from the FrequencyWords full lists (content/2018, CC BY-SA 4.0).

Usage: make-wordlists.py <dir with ru_full.txt and en_full.txt> <repository root>
The first words of each language go to Resources/, the next HELD_OUT go to the test fixtures.
"""
import re
import sys
from pathlib import Path

LANGS = {
    "ru": (re.compile(r"^[а-яё]+$"), 100_000),
    "en": (re.compile(r"^[a-z]+$"), 50_000),
}
HELD_OUT = 10_000


def main() -> None:
    src, root = Path(sys.argv[1]), Path(sys.argv[2])
    for lang, (pattern, dict_size) in LANGS.items():
        words = []
        with open(src / f"{lang}_full.txt", encoding="utf-8") as f:
            for line in f:
                word, _, count = line.strip().partition(" ")
                if pattern.match(word):
                    words.append(f"{word} {count}\n")
                if len(words) == dict_size + HELD_OUT:
                    break
        (root / "Resources" / f"{lang}.txt").write_text("".join(words[:dict_size]), encoding="utf-8")
        fixtures = root / "Tests" / "KeySwitchCoreTests" / "Fixtures"
        (fixtures / f"{lang}-heldout.txt").write_text("".join(words[dict_size:]), encoding="utf-8")


if __name__ == "__main__":
    main()
