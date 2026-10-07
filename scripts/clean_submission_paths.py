"""Keep exported verification logs portable by using relative project paths."""
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
variants = [
    str(ROOT).replace('\\', '\\\\'),
    str(ROOT),
    ROOT.as_posix(),
    ROOT.as_uri(),
]
for path in (ROOT / 'docs' / 'evidence').iterdir():
    if path.suffix.lower() not in {'.txt', '.json'}:
        continue
    text = path.read_text(encoding='utf-8-sig')
    for prefix in variants:
        text = text.replace(prefix, '.')
    if path.suffix.lower() == '.json':
        json.loads(text)
    path.write_text(text, encoding='utf-8')
print('Verification logs use relative project paths.')

