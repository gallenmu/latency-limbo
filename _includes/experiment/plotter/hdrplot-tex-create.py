#!/usr/bin/python3

from pathlib import Path
import re

import argparse

parser = argparse.ArgumentParser()
parser.add_argument("measurement_folder", help='input folder', default='./results')
args = parser.parse_args()

measurement_folder = Path(args.measurement_folder)
plot_folder = Path('figures')
plot_folder.mkdir(parents=True, exist_ok=True)

texheader=r"""\RequirePackage{luatex85}
\documentclass{standalone}
\usepackage{siunitx}
\usepackage{xcolor}
\usepackage{pgfplots}
\pgfplotsset{compat=newest}
\usepackage{pgfplotstable} 

\begin{document}%
  \definecolor{TUMBlue}           {cmyk}{1.00,0.43,0.00,0.00}% Pantone 300 C
  \definecolor{TUMWhite}          {cmyk}{0.00,0.00,0.00,0.00}% White
  \definecolor{TUMBlack}          {cmyk}{0.00,0.00,0.00,1.00}% Black
  \definecolor{TUMDarkerBlue}     {cmyk}{1.00,0.54,0.04,0.19}% Pantone 301 C
  \definecolor{TUMDarkBlue}       {cmyk}{1.00,0.57,0.12,0.70}% Pantone 540 C
  \definecolor{TUMDarkGray}       {cmyk}{0.00,0.00,0.00,0.80}% 80% Black
  \definecolor{TUMMediumGray}     {cmyk}{0.00,0.00,0.00,0.50}% 50% Black
  \definecolor{TUMLightGray}      {cmyk}{0.00,0.00,0.00,0.20}% 20% Black
  \definecolor{TUMIvony}          {cmyk}{0.03,0.04,0.14,0.08}% Pantone 7527 C
  \definecolor{TUMOrange}         {cmyk}{0.00,0.65,0.95,0.00}% Pantone 158 C
  \definecolor{TUMGreen}          {cmyk}{0.35,0.00,1.00,0.20}% Pantone 383 C
  \definecolor{TUMLightBlue}      {cmyk}{0.42,0.09,0.00,0.00}% Pantone 283 C
  \definecolor{TUMLighterBlue}    {cmyk}{0.65,0.19,0.01,0.04}% Pantone 542 C
  \definecolor{TUMPurple}         {cmyk}{0.50,1.00,0.00,0.40}%
  \definecolor{TUMDarkPurple}     {cmyk}{1.00,1.00,0.00,0.40}%
  \definecolor{TUMTurquois}       {cmyk}{1.00,0.03,0.30,0.30}%
  \definecolor{TUMDarkGreen}      {cmyk}{1.00,0.00,1.00,0.20}%
  \definecolor{TUMDarkerGreen}    {cmyk}{0.60,0.00,1.00,0.20}%
  \definecolor{TUMYellow}         {cmyk}{0.00,0.10,1.00,0.00}%
  \definecolor{TUMDarkYellow}     {cmyk}{0.00,0.30,1.00,0.00}%
  \definecolor{TUMLightRed}       {cmyk}{0.00,0.80,1.00,0.10}%
  \definecolor{TUMRed}            {cmyk}{0.10,1.00,1.00,0.10}%
  \definecolor{TUMDarkRed}        {cmyk}{0.00,1.00,1.00,0.40}%
    \begin{tikzpicture}[>=latex]%
      \pgfplotscreateplotcyclelist{mystil}{%
        {TUMBlue, mark=none},
        {TUMOrange, mark=none},
        {TUMGreen, mark=none},
        {TUMBlue!30, mark=none},
        {TUMOrange!30, mark=none},
        {TUMGreen!30, mark=none}
      }%
"""

texaxis=r"""
                \begin{axis}[                                                                                           
                        height = 5cm,                                                                                   
                        width = 10cm,                                                                                   
                        xmode=log,                                                                                      
                        ymode=log,                                                                                      
                        grid=major,                                                                                     
                        log basis x={10},                                                                               
                        log basis y={10},                                                                               
                        ymin=10^0,                                                                                      
                        ymax=10^5,                                                                                      
                        max space between ticks=20,                                                                     
                        yminorticks=true,                                                                               
                        xtick={1, 2, 10, 100, 1000, 10000, 100000, 1000000},                                            
                        xticklabels={0, 50, 90, 99, 99.9, 99.99, 99.999, 99.9999},                                      
                        xmin=10^0,                                                                                      
                        xmax=10^7,                                                                                      
                        xlabel={Percentiles [\%]},                                                                      
                        ylabel={Latency [\si{\micro\second}]},                                                          
                        restrict x to domain=0:2000000,                                                                 
                        cycle list name=mystil,                                                                         
                        legend pos = outer north east,                                                                  
                ] 
"""

texfooter=r"""
		\end{axis}
		\end{tikzpicture}
\end{document}

"""

addplot=r"""
                \addplot table[                                                                                         
                        col sep=semicolon,                                                                              
                        x expr= \thisrowno{1},                                                                          
                        y expr= \thisrowno{0}/1000,                                                                     
                 ]"""

# latency histogram
hist = sorted(list(measurement_folder.glob('**/*.pcap.hist-filtered.cdf.csv')))
for f in hist:
    filname = f.stem.replace('.hist-filtered', '')
    fhandle = open(plot_folder.joinpath(filname + '.hdrhist-filtered.tex'), 'w')
    fhandle.write(texheader)
    fhandle.write(texaxis)
    add = "{%s};" % (str(f))
    fhandle.write(addplot + add)
    fhandle.write(texfooter)


