from pathlib import Path, PurePath
import re
from jinja2 import Environment, FileSystemLoader
import argparse
import csv
import logging
import yaml
import sys

# TODO support the plotting of several graphs result files per run, e.g. run0 with two different trim parameters

# parse arguments
parser = argparse.ArgumentParser()
parser.add_argument("figures_folder", help="location of the figures folder")
parser.add_argument("measurement_folder", help="location of the folder containing the processed csv files")
parser.add_argument("result_folder", help="location of the original results (containing *.loop files)")
parser.add_argument("-v", "--verbose",  help="print debug output", action="store_true")
args = parser.parse_args()

# configure logging
if args.verbose:
    logging.basicConfig(level=logging.DEBUG)
else:
    logging.basicConfig(level=logging.WARNING)

# read folder paths
figuresFolder = Path(args.figures_folder)
measurementFolder = Path(args.measurement_folder)
resultFolder = Path(args.result_folder)
templateFolder = Path('./template')

env = Environment(loader=FileSystemLoader(templateFolder))

def checkFiguresFolder():
    logging.debug('checking figures folder')
    logging.debug(figuresFolder)

checkFiguresFolder()

loops = {}
def checkResultFolder():
    logging.debug('checking result folder')
    loopFiles = sorted(list(resultFolder.glob('*.loop')))
    if len(loopFiles) == 0:
        logging.error("no loop files found. wrong result folder?")
        sys.exit(0)
    for loop in loopFiles:
       with open(loop, "r") as stream:
           run = re.findall(r'run\d+', loop.stem)[-1].replace('run', '')
           try:
               loops[run] = yaml.safe_load(stream)
           except yaml.YAMLError as exc:
               logging.error(exc)
               sys.exit(0)

checkResultFolder()

templates = {}
def checkTemplateFolder():
    logging.debug('checking template folder')
    for templ in templateFolder.glob('*.tex'):
        templates[templ.stem] = env.get_template(templ.name)

checkTemplateFolder()

def createHistograms():
    histoFiles = sorted(list(measurementFolder.glob('*.hist.csv')))
    if len(histoFiles) == 0:
        logging.warning("no histogram files found, skipping histogram creation")
        return
    for hist in histoFiles:
        run = re.findall(r'run\d+', hist.stem)[0].replace('run', '')
        cscheme = templates['color-scheme-fill'].render()
        plot = templates['histogramplot'].render(content=str(hist), run=run, loop=loops[run])
        axis = templates['histogramaxis'].render(content=plot)
        doc = templates['standalone'].render(content=axis, colorscheme=cscheme)
        logging.debug(figuresFolder)
        with open(figuresFolder / ('histogram-run' + run + '.tex'), 'w') as stream:
            logging.debug(figuresFolder / ('histogram-run' + run + '.tex'))
            stream.write(doc)

createHistograms()

def createJitterHistograms():
    histoFiles = sorted(list(measurementFolder.glob('*.jitterpre.csv')))
    histoFiles += sorted(list(measurementFolder.glob('*.jitterpost.csv')))
    if len(histoFiles) == 0:
        logging.warning("no jitter files found, skipping jitter histogram creation")
        return
    for hist in histoFiles:
        run = re.findall(r'run\d+', hist.stem)[0].replace('run', '')
        cscheme = templates['color-scheme-fill'].render()
        plot = templates['histogramplot'].render(content=str(hist), run=run, loop=loops[run])
        axis = templates['histogramaxis'].render(content=plot)
        doc = templates['standalone'].render(content=axis, colorscheme=cscheme)
        logging.debug(figuresFolder)
        flname = ''
        if hist.stem.endswith('jitterpre'):
            flname = 'jitterpre'
        elif hist.stem.endswith('jitterpost'):
            flname = 'jitterpost'
        else:
            continue
        with open(figuresFolder / ('histogram-' + flname + '-run' + run + '.tex'), 'w') as stream:
            logging.debug(figuresFolder / ('histogram-run' + run + '.tex'))
            stream.write(doc)

createJitterHistograms()

def createHDRHistograms():
    histoFiles = sorted(list(measurementFolder.glob('*.percentiles.csv')))
    if len(histoFiles) == 0:
        logging.warning("no percentiles files found, skipping hdr-histogram creation")
        return
    for hist in histoFiles:
        run = re.findall(r'run\d+', hist.stem)[0].replace('run', '')
        cscheme = templates['color-scheme-nofill'].render()
        plot = templates['hdr-histogramplot'].render(content=str(hist), run=run, loop=loops[run])
        axis = templates['hdr-histogramaxis'].render(content=plot)
        doc = templates['standalone'].render(content=axis, colorscheme=cscheme)
        with open(figuresFolder / ('hdr-histogram-run' + run + '.tex'), 'w') as stream:
            logging.debug(figuresFolder / ('hdr-histogram-run' + run + '.tex'))
            stream.write(doc)

createHDRHistograms()

def createWorstOf():
    worstOf = sorted(list(measurementFolder.glob('*.worst.csv')))
    if len(worstOf) == 0:
        logging.warning("no worst files found, skipping worst-of-timeseries creation")
        return
    for worst in worstOf:
        run = re.findall(r'run\d+', worst.stem)[0].replace('run', '')
        cscheme = templates['color-scheme-mark'].render()
        plot = templates['scatterplot'].render(content=str(worst), run=run, loop=loops[run])
        axis = templates['scatteraxis'].render(content=plot)
        doc = templates['standalone'].render(content=axis, colorscheme=cscheme)
        with open(figuresFolder / ('worstof-timeseries-run' + run + '.tex'), 'w') as stream:
            logging.debug(figuresFolder / ('worstof-timeseries-run' + run + '.tex'))
            stream.write(doc)

createWorstOf()

def createPacketRate():
    packetRatesPre = sorted(list(measurementFolder.glob('*.packetratepre.csv')))
    if len(packetRatesPre) == 0:
        logging.warning("no packetrate files found, skipping packetrate plot creation")
        return
    for ratePre in packetRatesPre:
        run = re.findall(r'run\d+', ratePre.stem)[0].replace('run', '')
        ratePost = str(ratePre).replace('packetratepre', 'packetratepost')
        cscheme = templates['color-scheme-mark'].render()
        plot = [templates['rateplot'].render(content=str(ratePre), run=run, x=str(0), xdivisor=str(1000000000), y=str(1), ydivisor=str(1000), loop=loops[run], legendentry='Pre')]
        plot.append(templates['rateplot'].render(content=str(ratePost), run=run, x=str(0),  xdivisor=str(1000000000), y=str(1), ydivisor=str(1000), loop=loops[run], legendentry='Post'))
        xlbl = "Measurement time [\\si{\\second}]"
        ylbl = "Packet rate [\\si{\\kilo pkt\\per\\second}]"
        axis = templates['rateaxis'].render(xlabel=xlbl, ylabel=ylbl, plots=plot)
        doc = templates['standalone'].render(content=axis, colorscheme=cscheme)
        with open(figuresFolder / ('packetrate-run' + run + '.tex'), 'w') as stream:
            logging.debug(figuresFolder / ('packetrate-run' + run + '.tex'))
            stream.write(doc)

createPacketRate()

def filter_cpunum(liste):
    cpu = set()
    for haeufle in liste:
        el = haeufle.split('_')
        c = el[len(el) - 1]
        if re.match('CPU\d+', c):
            cpu.add(c)
    return sorted(list(cpu))

def dissectIRQFile(svfile, run):
    with open(str(svfile), newline='') as csvfile:
        reader = csv.reader(csvfile, delimiter=',', quotechar='"')
        header = list(next(reader, None))
        if not header:
            return
        cpu_list = filter_cpunum(header)
        timestamp_index = header.index('timestamp_us')
        dic = {}
        for cnum in cpu_list:
            dic[cnum] = []
            for i in header:
                if i == 'timestamp_us' or cnum not in i:
                    continue
                else:
                    dic[cnum].append(templates['rateplot'].render(content=str(svfile), run=run, x=str(timestamp_index),  xdivisor=str(1000000), y=str(header.index(i)), ydivisor=str(1), loop=loops[run], legendentry=i.replace('_' + cnum, '').replace('_', '\\_')))
        return dic

def createIRQPlot():
    irqs = sorted(list(measurementFolder.glob('*.irq.csv')))
    if len(irqs) == 0:
        logging.warning("no irq csv files found, skipping packetrate plot creation")
        return
    for irq in irqs:
        run = re.findall(r'run\d+', irq.stem)[0].replace('run', '')
        cscheme = templates['color-scheme-nofill'].render()
        dic = dissectIRQFile(irq, run)
        for cpu in dic:
            xlbl = "Measurement time [\\si{\\second}]"
            ylbl = "IRQ [relative]"
            axis = templates['rateaxis'].render(xlabel=xlbl, ylabel=ylbl, plots=dic[cpu])
            doc = templates['standalone'].render(content=axis, colorscheme=cscheme)
            with open(figuresFolder / ('irq-' + cpu.replace('CPU', 'cpu') + '-run' + run + '.tex'), 'w') as stream:
                stream.write(doc)

createIRQPlot()
