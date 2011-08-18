// private static final String[] NOTE_NAMES = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"};

// -------------------------------parameters------------------------------------

private static final float RANGE = 5;	//how many bars to show
private static final float PERSRATIO = 0.8;	//display tilt perspective, 1 = isometric
private static final float OVERTIME = 0.5;	//show this much after finish line

class MidiDisplay {
	LinkedList<MidiNote> song;
	float x,y,h;
	float currentTick;
	final float keywidth, spacing;
	final int alpha;
	
	MidiDisplay(LinkedList<MidiNote> newSong, float xpos, float ypos, float height, float noteW, float notespacing) {
		song = newSong;
		x = xpos;
		y = ypos;
		h = height;
		keywidth = noteW;
		spacing = notespacing;
		currentTick = -4;
		alpha = 90;
		// print(h+"\n");
	}
		
	void display() {
		
		// draw grids for each beat
		stroke(color(20,0,100,alpha-60));
		float offBeat = currentTick - (float)Math.floor(currentTick);
		for (int i=0;i < RANGE;i++) {
			float liney = y + (offBeat + i)/RANGE*h;
			line(x-keywidth, liney, x+88*keywidth, liney);
		}
		
		// draw notes
		noStroke();
		for (MidiNote n : song) {
			if ((n.onTick > currentTick && n.onTick < currentTick+RANGE) ||
			 	(n.offTick > currentTick && n.offTick < currentTick+RANGE)){
				// show the note:
				// computing y position first
				float y1 = (currentTick+RANGE-n.onTick)/RANGE*h;
				float y2 = (currentTick+RANGE-n.offTick)/RANGE*h;
				if (y1>h) { y1=h; }
				if (y2<0) { y2=0; }
				if ( (n.onTick<=currentTick + OVERTIME) &&
					(n.offTick > currentTick + OVERTIME)){
					fill(color(20,80,100));
					print("ON\n");
				} else {
					fill(color(20,50,50));
				}
				
				rect(x+keywidth*(n.pitch-24)+spacing,
					y+y2,
					keywidth-spacing*2,
					y1-y2);
				// print(str(y1)+" "+str(y2)+" "+str(n.pitch)+"\n");
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
