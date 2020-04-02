#!/usr/bin/env python

import sys

d = sys.stdin.read()

mids = {}
themid = ''
lines = d.split('\n')
for line in lines:
	fields = line.split(' ', -1)
	if len(fields) < 5:
		continue
	mid = fields[0]
	pmid = fields[1]
	mp = fields[4]
	mids[mid] = [mid, pmid, line, True, []]

mids['0'] = ['0', '0', '0', True, []]

for mid in mids.keys():
	if mid == '0':
		continue
	pmid = mids[mid][1]
	m = mids[mid] # me
	p = mids[pmid] # parent
	m[3] = False # root
	p[4].append(m)

def print_tree(mid, dep):
	m = mids[mid]
	print(' '*dep + m[2])
	for i, c in enumerate(m[4]):
		print_tree(c[0], dep+1)

for mid in mids.keys():
	m = mids[mid]
	r = m[3]
	if r:
		print_tree(mid, 0)
