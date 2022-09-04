#!/usr/bin/env python3

import subprocess

command = ["gh", "release", "list"]
out = subprocess.check_output(command)

text = out
text = text.decode('utf-8')
print(text)
text = text.split('\n')

devices = ['rpi', 'odroid', 'pbp']

releases = {}

for dev in devices:
    idx = 0
    releases[dev] = {}
    for line in text:
        if dev in line:
            word = line.split('\t')
            releases[dev][idx] = word[0]
            idx += 1

for dev in devices:
    for cnt in range(len(releases[dev])):
        if cnt > 1:
            cmd = ["gh", "release", "delete", releases[dev][cnt]]
            subprocess.call(cmd)
