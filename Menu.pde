private static final String[] MENU_OPTION = {"Air Harp", "Play Piano Roll", "Play Along", "Help", "Shutdown"};
// private static final String MENU_TITLE = "Welcome!";


// -------------------------------parameters------------------------------------
// private static final float PERSRATIO = 0.8;	//display tilt perspective, 1 = isometric

class Menu {
	float x,y,h;
	boolean inTransition;
	int curMenu;
	float currentTick;
	final float keywidth, spacing;
	final int alpha;
	
	Menu(float xpos, float ypos, float height, float noteW, float notespacing) {
		x = xpos;
		y = ypos;
		h = height;
		keywidth = noteW;
		spacing = notespacing;
		alpha = 90;
	}
		
	void display() {
		
		// draw grids
		fill(color(20,80,200,alpha-20));
		
		
		// draw notes
		fill(color(20,80,200,alpha));
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
		
		// draw finishline:
		fill(color(20,80,200,alpha));
		line(x,y+h-30,x+88*keywidth,y+h-30);
		// blackout after finish:
		fill(color(0,0,0));
		rect(x,y+h-30,88*keywidth,30);
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
