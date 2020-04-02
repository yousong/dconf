#!/usr/bin/env python

import sys

fin = None
if len(sys.argv) > 1:
	fin = open(sys.argv[1], 'r')
else:
	fin = sys.stdin

mids = {}
themid = ''
for line in fin:
	fields = line.split(' ', -1)
	if len(fields) < 5:
		continue
	mid = fields[0]
	pmid = fields[1]
	mp = fields[4]
	mids[mid] = [mid, pmid, line, True, []]

fin.close()

for mid in mids.keys():
	pmid = mids[mid][1]
	if pmid not in mids:
		continue
	m = mids[mid] # me
	p = mids[pmid] # parent
	m[3] = False # root
	p[4].append(m)

def print_tree(mid, dep):
	q = [[mid, 0]]
	while len(q) > 0:
		mid, i = q[-1]
		m = mids[mid]
		if i == 0 and mid != '0':
			sys.stdout.write(' '*(len(q)-1) + m[2])
		if i < len(m[4]):
			q[-1][1] = i + 1
			q.append([m[4][i][0], 0])
		else:
			q.pop()

for mid in mids.keys():
	m = mids[mid]
	r = m[3]
	if r:
		print_tree(mid, 0)
