#!/usr/bin/env python3
"""Write nea_mechanism_letter.json, the data of the poster's Figure 3, from the output of letter_score.m
(nea_letter_fig2.json and nea_letter_numbers.json), in the format make_plt_mechanism.py reads."""
import json, os
import numpy as np
HERE = os.path.dirname(os.path.abspath(__file__))
J = json.load(open(os.path.join(HERE, 'nea_letter_fig2.json'))); P = json.load(open(os.path.join(HERE, 'nea_letter_numbers.json')))['par']; Lv = J['table_Lv']
M = {'f': 1000, 'oct': J['table_oct'], 'Lv': Lv, 'delta': J['table'], 'w': [J['winh'] * float(np.exp(-((L - J['Lq50']) / J['Lqw']) ** 2)) for L in Lv],
     'winh': J['winh'], 'Lq50': J['Lq50'], 'Lqw': J['Lqw'], 'qpeak': P['qpeak'], 'data': {'quarter': J['data']['quarter'], 'octave': J['data']['octave']}}
json.dump(M, open(os.path.join(HERE, 'nea_mechanism_letter.json'), 'w')); print('wrote nea_mechanism_letter.json')
