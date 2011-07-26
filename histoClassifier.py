"""
generic histogram classifier
"""

class histoClassifier:
	# dictionary to store list of class histograms
	histoClasses = {}
	
	def __init__(self, signatureFile):
		# read file into siglist
		f = open(signatureFile,'r')
		
		for line in f.readlines():
			# print line
			l = line.split()
			hist = [float(x) for x in l[:-1]]			
			self.histoClasses[l[-1]] = hist
			
		f.close()
		
		# print self.histoClasses

	
	def classify(self, list):
		# generate histogram for list
		hist = [0]*len(self.histoClasses.values()[0])
		
		for i in list:
			hist[i-1] += 1
		
		return self.classifyHist(hist)

	def classifyHist(self, hist):
		result = {}
		for k in self.histoClasses.keys():
			h = [x*y for x,y in zip(hist,self.histoClasses[k])]
			score = sum(h)
			result[score] = result.get(score,[]) + [k]
		
		return result