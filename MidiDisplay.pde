// private static final String[] NOTE_NAMES = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"};

// -------------------------------parameters------------------------------------

private static final float RANGE = 5;	//how many bars to show
private static final float GUIDERANGE = 3; //show guidance for these notes
private static final float PERSRATIO = 0.8;	//display tilt perspective, 1 = isometric
private static final float OVERTIME = 0.5;	//show this much after finish line

class MidiDisplay {
	LinkedList<MidiNote> song;
	float x,y,h;
	float currentTick;
	final float keywidth, spacing;
	final int alpha;
	List guideNotes;
	
	MidiDisplay(LinkedList<MidiNote> newSong, float xpos, float ypos, float height, float noteW, float notespacing) {
		song = newSong;
		x = xpos;
		y = ypos;
		h = height;
		keywidth = noteW;
		spacing = notespacing;
		currentTick = -4;
		alpha = 90;
		guideNotes = new ArrayList(); 
	}
		
	void display() {
		
		// draw grids for each beat
		fill(color(0,0,100,10));
		float offBeat = currentTick - (float)Math.floor(currentTick);
		for (int i=0;i < 88;i++) {
			int scale = i % 12;
			if (!(scale==1 || scale==4 || scale==6 || scale==9 || scale==11)) {
				noStroke();
				rect(x+i*keywidth, y, keywidth, h);
			}
			// float liney = y + (offBeat + i)/RANGE*h;
			stroke(color(20,0,100,alpha-70));			
			line(x+i*keywidth, y, x+i*keywidth, y+h);
		}
		for (int i=0;i < RANGE;i++) {
			float liney = y + (offBeat + i)/RANGE*h;
			line(x-keywidth, liney, x+88*keywidth, liney);
		}
		
		
		// draw notes
		noStroke();
		guideNotes.clear();
		for (MidiNote n : song) {
			if ((n.onTick > currentTick && n.onTick < currentTick+RANGE) ||
			 	(n.offTick > currentTick && n.offTick < currentTick+RANGE)){
				// show the note:
				// computing y position first
				float y1 = (currentTick+RANGE-n.onTick)/RANGE*h;
				float y2 = (currentTick+RANGE-n.offTick)/RANGE*h;
				if (y1>h) { y1=h; }
				if (y2<0) { y2=0; }
				if ((n.onTick<=currentTick + OVERTIME) &&
					(n.offTick > currentTick + OVERTIME)){
					fill(color(20,80,100));
				} else {
					fill(color(20,50,50));
				}
				
				rect(x+keywidth*(n.pitch-24)+spacing,
					y+y2,
					keywidth-spacing*2,
					y1-y2);
				if (n.onTick<=currentTick + GUIDERANGE) {
					guideNotes.add(n.pitch-24);
					fill(color(0,0,80,80 - (h-y1)/((GUIDERANGE/RANGE)*h)*80));
					rect(x+keywidth*(n.pitch-24)+spacing,
						y+y1,
						keywidth-spacing*2,
						h-y1);
				}
			}
			if (n.onTick > currentTick + RANGE) {
				break;
			}
		}
		// blackout after finish:
		fill(color(0,0,0,80));
		noStroke();
		float overH = OVERTIME/RANGE*h;
		rect(x,y+h-overH,88*keywidth,overH);
		// draw finishline:
		stroke(color(20,80,256,alpha));
		strokeWeight(2);
		line(x-keywidth,y+h-overH,x+88*keywidth,y+h-overH);
		// line(x-keywidth,y,x+88*keywidth,y);
		// line(x-keywidth,y+h,x+88*keywidth,y+h);
		
		// fill(color(0,0,0,0));
		// rect(x,y,88*keywidth,h);
	}
	
	float getLength() {
		return song.getLast().offTick;
	}
	
	void rewind() {
		currentTick = 0;
	}
	
	void forward(float t) {
		currentTick += t;
		// if (currentTick > song.getLast().offTick) {
		// 	currentTick = song.getLast().offTick;
		// }
	}
}
