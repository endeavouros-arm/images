#!/usr/bin/env python3

import subprocess


def releases_parse(text: list[str]) -> list[str]:
    "function to parse the output of github release list"
    rel = []
    for line in text:
        word = line.split("\t")[0]
        print(word)
        rel.append(word)
    return rel


def device_releases(dev: str, rel: list[str]) -> list[str]:
    "function to filter parsed output by device"
    dev_rel = []
    for release in rel:
        if release.startswith(f"image-{dev}-"):
            dev_rel.append(release)
    return dev_rel


def main():
    command = ["gh", "release", "list"]
    out = subprocess.check_output(command).decode("utf-8")
    print(out)
    text = out.split("\n")
    releases = releases_parse(text)
    devices = ["rpi", "odroid", "pbp"]
    for dev in devices:
        for i, release in enumerate(device_releases(dev, releases)):
            if i > 1:
                cmd = ["gh", "release", "delete", release]
                subprocess.call(cmd)


if __name__ == "__main__":
    main()
