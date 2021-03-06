// A simple Particle class
// http://processing.org/learning/topics/simpleparticlesystem.html

class Particle {
	PVector loc;
	PVector vel;
	PVector acc;
	float r;
	float timer;
	color c;

	// Another constructor (the one we are using here)
	Particle(PVector l, color newC) {
		PVector v = new PVector(random(-1,1),random(-2,0),0);
		acc = new PVector(0,0.2,0);
		vel = new PVector(random(-1,1),random(-2,0),0);
		loc = l.get();
		r = 20.0;
		timer = 100.0;
		c = newC;
	}

	// Another constructor (the one we are using here)
	Particle(PVector l) {
		PVector v = new PVector(random(-1,1),random(-2,0),0);
		acc = new PVector(0,0.1,0);
		vel = new PVector(random(-1,1),random(-2,0),0);
		loc = l.get();
		r = 20.0;
		timer = 100.0;
	}
	
	Particle(PVector l, PVector initv) {
		acc = new PVector(0,0.1,0);
		// vel = new PVector(random(-1,1),random(-2,0),0);
		vel = initv.get();
		loc = l.get();
		r = 20.0;
		timer = 100.0;
	}

	void run() {
		update();
		render();
	}

	// Method to update location
	void update() {
		vel.add(acc);
		loc.add(vel);
		timer -= 1.0;
	}

	// Method to display
	void render() {
		ellipseMode(CENTER);
		stroke(255,timer);
		fill(c,timer);
		ellipse(loc.x,loc.y,r,r);
		// displayVector(vel,loc.x,loc.y,10);
	}

	// Is the particle still useful?
	boolean dead() {
		if (timer <= 0.0) {
			return true;
		} else {
			return false;
		}
	}

	void displayVector(PVector v, float x, float y, float scayl) {
		pushMatrix();
		float arrowsize = 4;
		// Translate to location to render vector
		translate(x,y);
		stroke(255);
		// Call vector heading function to get direction (note that pointing up is a heading of 0) and rotate
		rotate(v.heading2D());
		// Calculate length of vector & scale it to be bigger or smaller if necessary
		float len = v.mag()*scayl;
		// Draw three lines to make an arrow (draw pointing up since we've rotate to the proper direction)
		line(0,0,len,0);
		line(len,0,len-arrowsize,+arrowsize/2);
		line(len,0,len-arrowsize,-arrowsize/2);
		popMatrix();
	} 

}