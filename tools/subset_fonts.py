"""Cut the big CJK fonts down to the characters the decks use (a full CJK font is 6-26 MB, too heavy for the device).

    uv run --with fonttools --with brotli tools/subset_fonts.py <folder with the full .ttf files>

Full fonts (not in the repo, OFL): LXGWWenKai-Medium.ttf (github.com/lxgw/LxgwWenKai), MaShanZheng-Regular.ttf
(github.com/google/fonts, ofl/mashanzheng). Writes assets/fonts/hanzi/*.subset.ttf. Rerun after editing a deck TSV.
"""
import csv
import string
import sys
from pathlib import Path

from fontTools import subset

ROOT = Path(__file__).resolve().parent.parent
DECKS = ROOT / "data" / "hanzi"
OUT = ROOT / "assets" / "fonts" / "hanzi"


def deck_text() -> tuple[str, str]:
    """(hanzi only, everything shown on a card)."""
    hanzi: set[str] = set()
    shown: set[str] = set(string.printable)
    for tsv in sorted(DECKS.glob("*.tsv")):
        with tsv.open(encoding="utf-8") as f:
            for row in csv.DictReader(f, delimiter="\t"):
                hanzi.update(row["hanzi"])
                for value in row.values():
                    shown.update(value)
    return "".join(sorted(hanzi)), "".join(sorted(shown))


def cut(source: Path, target: Path, text: str) -> None:
    options = subset.Options()
    options.layout_features = ["*"]
    options.name_IDs = ["*"]
    font = subset.load_font(str(source), options)
    subsetter = subset.Subsetter(options)
    subsetter.populate(text=text)
    subsetter.subset(font)
    subset.save_font(font, str(target), options)
    print(f"{target.name}: {len(text)} chars, {target.stat().st_size // 1024} KB")


def main() -> None:
    full = Path(sys.argv[1])
    hanzi, shown = deck_text()
    OUT.mkdir(parents=True, exist_ok=True)
    # Kaiti: hanzi, pinyin with tone marks, meanings. Brush: hanzi only (it has no tone-mark letters).
    cut(full / "LXGWWenKai-Medium.ttf", OUT / "lxgw_wenkai.subset.ttf", shown)
    cut(full / "MaShanZheng-Regular.ttf", OUT / "ma_shan_zheng.subset.ttf", hanzi)


if __name__ == "__main__":
    main()
