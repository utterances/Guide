#!/usr/bin/env python
# encoding: utf-8
"""
untitled.py

Created by Tim on 2011-07-05.
Copyright (c) 2011 __MyCompanyName__. All rights reserved.
"""

import sys
import getopt
from histoClassifier import *
 

help_message = '''
The help message goes here.
'''


class Usage(Exception):
	def __init__(self, msg):
		self.msg = msg


def main(argv=None):
	if argv is None:
		argv = sys.argv
	try:
		try:
			opts, args = getopt.getopt(argv[1:], "ho:v", ["help", "output="])
		except getopt.error, msg:
			raise Usage(msg)
	
		# option processing
		for option, value in opts:
			if option == "-v":
				verbose = True
			if option in ("-h", "--help"):
				raise Usage(help_message)
			if option in ("-o", "--output"):
				output = value
	
	except Usage, err:
		print >> sys.stderr, sys.argv[0].split("/")[-1] + ": " + str(err.msg)
		print >> sys.stderr, "\t for help use --help"
		return 2
		
	if len(args)>1:
		chordDetector = histoClassifier('/Users/Tim/Documents/Music Research/chords_all')
		result = chordDetector.classify([int(n) for n in args])
		k = result.keys()
		k.sort()
		print result[k[-1]]
	# else:
	# 	print "more notes please"


if __name__ == "__main__":
	sys.exit(main())




	# convert from letter to numbers

	nlist = []
	for c in notelist:
		nlist += [noteLetters[c.lower()]]


	result = keyDetector.classify(nlist)

	# print highest probability results

	k = result.keys()
	k.sort()
	print result[k[-1]]