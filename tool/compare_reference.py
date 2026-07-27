#!/usr/bin/env python3
from pathlib import Path
import argparse
from PIL import Image, ImageChops, ImageStat

parser = argparse.ArgumentParser()
parser.add_argument('reference')
parser.add_argument('actual')
parser.add_argument('--diff', default='reference-diff.png')
args = parser.parse_args()
ref = Image.open(args.reference).convert('RGB')
actual = Image.open(args.actual).convert('RGB')
if actual.size != ref.size:
    raise SystemExit(f'Image size mismatch: reference={ref.size}, actual={actual.size}')
diff = ImageChops.difference(ref, actual)
stat = ImageStat.Stat(diff)
mean = sum(stat.mean) / 3
rms = (sum(v*v for v in stat.rms) / 3) ** .5
diff.save(args.diff)
print(f'mean_absolute_channel_error={mean:.3f}')
print(f'rms_channel_error={rms:.3f}')
print(f'diff={Path(args.diff).resolve()}')
