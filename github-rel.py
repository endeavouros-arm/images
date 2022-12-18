#!/usr/bin/env python3

import subprocess
import argparse
import datetime

today = datetime.date.today()

DATE = today.strftime("%Y%m%d")


def parse_function():
    global platform
    global itype
    global mod_rel
    parser = argparse.ArgumentParser(
        description="Python script to upload EndeavourOS ARM images/rootfs to GitHub")
    parser.add_argument(
        "--platform",
        "-p",
        required=True,
        choices=["rpi", "odn", "pbp"],
        help="Choose platform",
    )
    parser.add_argument(
        "--type",
        "-t",
        choices=["rootfs", "ddimg", "server"],
        default="rootfs",
        help="Choose image type",
    )
    # parser.add_argument(
    #     "--mod",
    #     action=argparse.BooleanOptionalAction,
    #     default=False,
    #     help="Upload new image on same day",
    # )
    args = parser.parse_args()

    platform = args.platform
    itype = args.type
    # mod_rel = args.mod


def releases_parse(text: list[str]) -> list[str]:
    "function to parse the output of github release list"
    rel = []
    for line in text:
        word = line.split("\t")[0]
        # print(word)
        rel.append(word)
    return rel


def device_releases(dev: str, rel: list[str]) -> list[str]:
    "function to filter parsed output by device"
    dev_rel = []
    print("List of older images")
    if itype == "ddimg":
        for release in rel:
            if release.startswith(f"ddimg-{dev}-"):
                dev_rel.append(release)
                print(f"    {release}")
    else:
        for release in rel:
            if release.startswith(f"rootfs-{dev}-"):
                dev_rel.append(release)
                print(f"    {release}")
    return dev_rel


def modify_release(img_name, rel_name):
    cmd = [
        "gh",
        "release",
        "upload",
        rel_name,
        img_name,
        img_name + ".sha512sum",
        "--clobber",
    ]
    subprocess.run(cmd, check=True)


def create_release(img_name, rel_name, rel_note):
    cmd = [
        "gh",
        "release",
        "create",
        rel_name,
        img_name,
        img_name + ".sha512sum",
        "-t",
        rel_name,
        "-F",
        rel_note,
        "-d",
    ]
    out = subprocess.run(cmd, check=True)
    cmd = ["gh", "release", "edit", rel_name, "--draft=false"]
    subprocess.run(cmd, check=True)


def main():
    parse_function()
    print(platform)
    plat = platform
    if platform == "odn":
        plat = "odroid-n2"
    if itype == "ddimg":
        rel_name = f"ddimg-{plat}-{DATE}"
        img_name = f"enosLinuxARM-{plat}-latest.img.xz"
    else:
        rel_name = f"rootfs-{plat}-{DATE}"
        img_name = f"enosLinuxARM-{plat}-latest.tar.zst"
    rel_note = f"release-note-{plat}.md"

    command = ["gh", "release", "list"]
    out = subprocess.check_output(command).decode("utf-8")
    text = out.split("\n")
    releases = releases_parse(text)
    out = device_releases(plat, releases)
    # print(out)
    if not out:
        print("Image being created. Can take 10-20 minutes")
        create_release(img_name, rel_name, rel_note)
    elif DATE in out[0] and itype in out[0]:
        print("An image was already released today")
        print("Modifying the existing release. Can take 10-20 minutes")
        modify_release(img_name, rel_name)
    else:
        print("Image being created. Can take 10-20 minutes")
        create_release(img_name, rel_name, rel_note)


if __name__ == "__main__":
    main()
