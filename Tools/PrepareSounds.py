#!/usr/bin/env python3
"""Builds the app's coin sounds from public-domain field recordings.

Both sources are real coin recordings by "ezwa", originally published on
pdsounds.org and mirrored on Wikimedia Commons, released into the public
domain (no attribution required — we credit them anyway in CREDITS.md).

The recordings are long and mostly silence, so this script extracts the two
moments the app actually needs: a handful of coins jingling as the toss starts,
and a single coin striking a wooden floor and bouncing to rest.

Usage:
    python3 Tools/PrepareSounds.py ["CoinToss Watch App/Sounds"]

Requires only macOS stock tools (curl, afconvert) and Python 3.
"""

import array
import os
import struct
import subprocess
import sys
import tempfile
import urllib.request

SAMPLE_RATE = 44100

SOURCES = {
    "palm": "https://upload.wikimedia.org/wikipedia/commons/4/46/Shaking_coins_in_palm.ogg",
    "land": "https://upload.wikimedia.org/wikipedia/commons/c/c5/Coin_dropped_on_wooden_floor.ogg",
}

# (source, start, end) in seconds, chosen by inspecting the amplitude envelope.
CLIPS = {
    # A couple of coins chinking together as they leave the hand.
    "coin-toss.wav": ("palm", 0.38, 0.78),
    # The strike, then the bounces settling out. This is the payoff sound.
    "coin-land.wav": ("land", 0.84, 1.72),
}

FADE_IN = 0.008
FADE_OUT = 0.060
PEAK_TARGET = 0.94


def read_wav(path):
    """Reads a mono/stereo 16-bit RIFF file, including WAVE_FORMAT_EXTENSIBLE."""
    with open(path, "rb") as handle:
        blob = handle.read()

    if blob[:4] != b"RIFF" or blob[8:12] != b"WAVE":
        raise ValueError(f"{path} is not a RIFF/WAVE file")

    fmt = data = None
    pos = 12
    while pos + 8 <= len(blob):
        chunk_id = blob[pos:pos + 4]
        size = struct.unpack("<I", blob[pos + 4:pos + 8])[0]
        body = blob[pos + 8:pos + 8 + size]
        if chunk_id == b"fmt ":
            fmt = body
        elif chunk_id == b"data":
            data = body
        pos += 8 + size + (size & 1)

    if fmt is None or data is None:
        raise ValueError(f"{path} is missing a fmt or data chunk")

    channels, rate = struct.unpack("<HI", fmt[2:8])
    samples = array.array("h")
    samples.frombytes(data[: len(data) // 2 * 2])

    if channels > 1:  # keep the left channel only
        samples = array.array("h", samples[::channels])

    return samples, rate


def write_wav(samples, rate, path):
    payload = samples.tobytes()
    header = b"".join([
        b"RIFF", struct.pack("<I", 36 + len(payload)), b"WAVE",
        b"fmt ", struct.pack("<IHHIIHH", 16, 1, 1, rate, rate * 2, 2, 16),
        b"data", struct.pack("<I", len(payload)),
    ])
    with open(path, "wb") as handle:
        handle.write(header + payload)


def fetch(url, destination):
    print(f"  fetching {os.path.basename(url)}")
    # Wikimedia rejects requests that do not identify themselves.
    request = urllib.request.Request(
        url,
        headers={"User-Agent": "CoinToss-SoundPrep/1.0 (https://github.com/batflarrow/coin-toss)"},
    )
    with urllib.request.urlopen(request) as response, open(destination, "wb") as handle:
        handle.write(response.read())


def decode_to_wav(source, destination):
    subprocess.run(
        ["afconvert", "-f", "WAVE", "-d", f"LEI16@{SAMPLE_RATE}", "-c", "1",
         source, destination],
        check=True,
    )


def shape(samples, rate):
    """Normalises the clip and applies short fades so edits are inaudible."""
    peak = max((abs(s) for s in samples), default=0)
    gain = (PEAK_TARGET * 32767 / peak) if peak else 0.0

    fade_in = max(1, int(FADE_IN * rate))
    fade_out = max(1, int(FADE_OUT * rate))
    count = len(samples)

    shaped = array.array("h", bytes(2 * count))
    for i, sample in enumerate(samples):
        envelope = 1.0
        if i < fade_in:
            envelope *= i / fade_in
        if i > count - fade_out:
            envelope *= max(0.0, (count - i) / fade_out)
        value = int(sample * gain * envelope)
        shaped[i] = max(-32767, min(32767, value))

    return shaped


def main():
    out_dir = sys.argv[1] if len(sys.argv) > 1 else "CoinToss Watch App/Sounds"
    os.makedirs(out_dir, exist_ok=True)

    with tempfile.TemporaryDirectory() as work:
        decoded = {}
        for name, url in SOURCES.items():
            ogg = os.path.join(work, f"{name}.ogg")
            wav = os.path.join(work, f"{name}.wav")
            fetch(url, ogg)
            decode_to_wav(ogg, wav)
            decoded[name] = read_wav(wav)

        for filename, (source, start, end) in CLIPS.items():
            samples, rate = decoded[source]
            clip = samples[int(start * rate):int(end * rate)]
            shaped = shape(clip, rate)

            path = os.path.join(out_dir, filename)
            write_wav(shaped, rate, path)
            print(f"  wrote {filename}  ({len(shaped) / rate:.2f}s, "
                  f"{os.path.getsize(path)} bytes)")


if __name__ == "__main__":
    main()
