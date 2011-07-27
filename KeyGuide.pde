// draw individual keys, uses a single rect

class KeyGuide { 

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
	float oldHeight;
	
	// The Constructor is defined with arguments.
	KeyGuide(int newLow, float X, float Y, float w, float h, boolean white) { 
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
	
	void display() {
		stroke(0);
		int sat = 0;
		if (isOn) {
			sat = 80;
		}
		if (isWhite) {
			strokeWeight(1);
			fill(color(0, sat, curB+8));
		} else {
			strokeWeight(KEYBORDER_B*width);
			fill(color(0, sat, curB));
		}
		// rectMode(CORNERS); //rectMode(CENTER);
		rect(xpos,ypos,width,height);
	}
	
	void blackOut() {	//blank out with black
		stroke(0);
		fill(color(0, 0, 0));
		// rectMode(CORNERS); //rectMode(CENTER);
		rect(xpos,ypos-400,width,height+400);	
	}
}
