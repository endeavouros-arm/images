#!/usr/bin/env python3

import subprocess

command = ["gh","release","list"]
out = subprocess.check_output(command)

t= out
t=t.decode('utf-8')
print(t)
t=t.split('\n')

devices = ['rpi','odroid','pbp']

dct = dict(zip(devices, [None]*len(devices)))

for dev in devices:
    ii=0
    dct[dev]={}
    for tt in t:
        if dev in tt:
            ttt = tt.split('\t')
            dct[dev][ii]=ttt[0]
            ii+=1

for dev in devices:
    for ii in range(len(dct[dev])):
        if ii > 1:
            cmd = ["gh","release","delete",dct[dev][ii]]
            subprocess.call(cmd)
