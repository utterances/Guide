import promidi.*;

// import java.util.LinkedList;

// private static final String[] NOTE_NAMES = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"};

// -------------------------------parameters------------------------------------

private static final float RANGE = 8;	//how many bars to show


class MidiDisplay {
	LinkedList<MidiNote> song;
	float x,y,h;
	float currentTick;
	final float keywidth, spacing;
	
	MidiDisplay(LinkedList<MidiNote> newSong, float xpos, float ypos, float height, float noteW, float notespacing) {
		song = newSong;
		x = xpos;
		y = ypos;
		h = height;
		keywidth = noteW;
		spacing = notespacing;
		currentTick = 0;
	}
		
	void display() {
		fill(color(20,80,200));
		noStroke();
		for (MidiNote n : song) {
			if ((n.onTick > currentTick && n.onTick < currentTick+RANGE) ||
			 	(n.offTick > currentTick && n.offTick < currentTick+RANGE)){
				// show the note:
				// computing x position first
				int y1 = (int)Math.round(Math.max((currentTick+RANGE-n.onTick)/RANGE * h,0));
				int y2 = (int)Math.round(Math.min((currentTick+RANGE-n.offTick)/RANGE * h,h));
				
				rect(x+keywidth*(n.pitch-1)+spacing,
					y2,
					keywidth-spacing*2,
					y1-y2);
				// print(str(y1)+str(y2)+str(n.pitch)+"\n");	
			}
			if (n.onTick > currentTick + RANGE) {
				break;
			}
		}
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
