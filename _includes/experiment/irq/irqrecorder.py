#!/bin/python3

import argparse
import atexit
import csv
import re
import signal
import sys
import time


parser = argparse.ArgumentParser()
parser.add_argument("limit", type=int, default=0, nargs="?",
                    help="Number of repetitions (or 0 for infinity), default %(default)d")
parser.add_argument("delay", type=int, default=1, nargs="?",
                    help="Interval between printing, default %(default)d second")

args = parser.parse_args()
limit, delay = args.limit, args.delay

cpus = re.compile(r'\s+(CPU\d+\s+)+(CPU\d+\s+)$')
cpu = re.compile(r'CPU\d+')
start_us = int(time.time() * 1000 * 1000)

buf = []

def read_interrupts(fd):
    stamp_us = int(time.time() * 1000 * 1000)

    # first line - number of CPUs
    line = fd.readline()
    split = re.split(r'\s+', line)
    numcpu = 0
    for spl in split:
        if cpu.match(spl):
            numcpu = numcpu + 1

    # rest of lines - interrupts
    line = fd.readline()
    dct = dict()
    dct['timestamp_us'] = stamp_us - start_us

    for line in fd:
        split = list(filter(None, re.split(r'\s+', line)))

        name = split[0].replace(':', '')
        for i in range(numcpu + 1, len(split)):
            name = name + "_" + split[i]
        for i in range(0, min(numcpu, len(split) - 1)):
            dct[name + "_CPU" + str(i)] = split[1 + i]
    return dct

def finalizer(signum, frame):
    sys.exit()

def finalize():
    with open('./irqrecorder.csv', 'w', newline='') as ff:
        fieldnames = set(buf[0].keys())
        for fn in buf:
            fieldnames = set(fieldnames) | set(fn.keys())
        fieldnames = list(fieldnames)
        writer = csv.DictWriter(ff, fieldnames=fieldnames, delimiter=';', quotechar='"', quoting=csv.QUOTE_MINIMAL)
        writer.writeheader()
        for dicti in buf:
            writer.writerow(dicti)
    print('file written')

atexit.register(finalize)
signal.signal(signal.SIGTERM, finalizer)
try:
    with open("/proc/interrupts") as f:

        buf.append(read_interrupts(f))
        ddl = 0
        while limit != 1:
            if limit > 0:
                limit -= 1
            time.sleep(delay - ddl)
            appenddelay = time.time()
            f.seek(0)
            buf.append(read_interrupts(f))
            ddl = time.time() - appenddelay
except KeyboardInterrupt:
    pass
