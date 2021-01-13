#!/usr/bin/env python3

import sys
import json
import re

cmtpref = ' // zh:'
regK = re.compile(r'''i18n\.t\((['"])(?P<key>[^'"]+)\1[,\)]''')

def processFile(locales, fname):
    newlines = []
    with open(fname, 'r') as fin:
        for line in fin:
            m = regK.search(line)
            if m:
                key = m.group('key')
                val = localesGet(locales, key)
                print(key, val)
                if val:
                    line = line.rstrip('\n')
                    i = line.find(cmtpref)
                    if i > 0:
                        line = line[:i]
                    line += cmtpref + f'{val!r}\n'
            newlines.append(line)

    with open(fname, 'w') as fout:
        for line in newlines:
            fout.write(line)

def localesGet(locales, keystr):
    ctx = locales
    while True:
        if keystr in ctx:
            r = ctx[keystr]
            if isinstance(r, str):
                return r
            else:
                return None
        i = keystr.find('.')
        if i <= 0:
            return None
        k, keystr = keystr[:i], keystr[i+1:]
        if k not in ctx:
            return None
        ctx = ctx[k]

    return None

with open('locales/zh-CN.json', 'r') as fin:
    locales = json.load(fin)

for f in sys.argv:
    processFile(locales, f)
