#!/usr/bin/env python3
"""Makes Resources/emoji.txt from db/emoji.json of github/gemoji.

Usage: make-emoji-list.py emoji.json Resources/emoji.txt
Each line of the output is a code, a tab and the emoji.
"""
import json
import sys

with open(sys.argv[1], "rb") as source:
    items = json.load(source)

lines = []
seen = set()
for item in items:
    for alias in item["aliases"]:
        if alias not in seen:
            seen.add(alias)
            lines.append(f"{alias}\t{item['emoji']}")

with open(sys.argv[2], "wb") as target:
    target.write(("\n".join(lines) + "\n").encode())
print(len(lines))
