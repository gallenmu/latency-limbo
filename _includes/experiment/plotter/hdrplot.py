#!/usr/bin/python3

from pathlib import Path

import argparse
import csv
import sys

parser = argparse.ArgumentParser()
parser.add_argument("histogram", help='input histogram folder', default='./results')
args = parser.parse_args()

histogram = Path(args.histogram)
plot_folder = Path('results')

histograms = list(histogram.glob('**/*.pcap.hist-filtered.csv'))
for hist in histograms:

    filname = hist.stem.replace('.hist-filtered', '.hist-filtered.cdf')
    #print(filname)

    with open(hist, newline='') as csvfile:
        spamreader = csv.reader(csvfile, delimiter=',', quotechar='|')
        next(spamreader)
        total = 0
        for row in spamreader:
            total += int(row[1])

    with open(hist, newline='') as csvfile:
        spamreader = csv.reader(csvfile, delimiter=',', quotechar='|')
        next(spamreader)
        with open(plot_folder.joinpath(filname + '.csv'), 'w', newline='') as csvfile:
            
            spamwriter = csv.writer(csvfile, delimiter=';', quotechar='|', quoting=csv.QUOTE_MINIMAL)
            integrator = 0
            for row in spamreader:
                integrator += int(row[1])
                if (1 - (float(integrator)/total)) > 0.0:
                    magic = 1 / (1 - float(integrator)/total)
                    spamwriter.writerow([str(row[0]), str(magic), str(integrator), str('{:.20f}'.format(float(integrator)/total))])
                else:
                    # maximum measured value not plottable on log scale
		    # => shift it to the non-printed area of the graph
                    magic = 1 / (1 - (float(integrator) - 0.000001)/total)
                    spamwriter.writerow([str(row[0]), str(magic), str(integrator), str('{:.20f}'.format(float(integrator)/total))])

