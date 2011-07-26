// note class, draws notes on staff


class NoteGuide { 
	// color c;
	int lowB;	//brightness levels: lower bound
	int curB;	//current brightness
	float xpos;
	float ypos;
	float width;
	float height;
	// float xspeed;
	boolean isWhite;
	boolean isOn;
	boolean isActiveGuide;
	
	// The Constructor is defined with arguments.
	NoteGuide(int newLow, float X, float Y, float w, float h, boolean white) { 
		lowB = newLow;
		curB = lowB;
		xpos = X;
		ypos = Y;
		width = w;
		height = h;
		// xspeed = tempXspeed;
		isWhite = white;
		isOn = false;
		isActiveGuide = false;
	}

	// void updateBrightness() {
	// 	
	// }
	
	void display() {
	
		if (!(isOn || isActiveGuide)) {
			return;
		}		
		ellipseMode(CORNER);
		fill(100);
		smooth();
		ellipse(xpos,ypos,width,height);
		
	}
}
