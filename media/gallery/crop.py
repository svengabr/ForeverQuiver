"""Cuts the five pictures of /fq shots down to 1920x1080 gallery images.

    python media/gallery/crop.py "<World of Warcraft>/_forever_/Screenshots"

Takes the five newest screenshots in that folder, in the order /fq shots makes them. The boxes below fit a
3440x1440 screen with the displays at their default positions; on another screen or layout, adjust them.
Needs Pillow.
"""
import glob
import os
import sys

from PIL import Image

# name, box (left, top, right, bottom) in the 3440x1440 screenshot; every box is 16:9
SHOTS = [
    ("01-world", (920, 230, 2520, 1130)),
    ("02-displays", (1000, 260, 2440, 1070)),
    ("03-options-general", (1002, 312, 2442, 1122)),
    ("04-options-autoshot", (1002, 312, 2442, 1122)),
    ("05-options-range", (1002, 312, 2442, 1122)),
]


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    files = sorted(glob.glob(os.path.join(sys.argv[1], "WoWScrnShot_*.jpg")), key=os.path.getmtime)[-len(SHOTS):]
    if len(files) != len(SHOTS):
        sys.exit("Need %d screenshots, found %d." % (len(SHOTS), len(files)))
    out = os.path.dirname(os.path.abspath(__file__))
    for path, (name, box) in zip(files, SHOTS):
        image = Image.open(path).convert("RGB")
        if image.size != (3440, 1440):
            sys.exit("%s is %dx%d, the boxes are for 3440x1440." % (os.path.basename(path), *image.size))
        image.crop(box).resize((1920, 1080), Image.LANCZOS).save(os.path.join(out, name + ".jpg"), quality=92)
        print(name + ".jpg", "<-", os.path.basename(path))


if __name__ == "__main__":
    main()
