import promidi.*;
import java.io.*;

import king.kinect.*;
import hypermedia.video.*;
import java.util.LinkedList;

ChordThread chord_thread;
HandTracker tracker;

MidiIO midiIO;
MidiOut midiOut;

// -------------------------------parameters------------------------------------

static final int KEYNUM = 88;
static final int WHITEKEYNUM = 52;
static int SCREENW = 1227;//2005;//2150;
static int SCREENWTOTAL = SCREENW + 640;
static final int SCREENH = 500;
// key dimension, defined by ratio between white key width and heights
static final int KEYRATIO_W = 6;
static final float KEYRATIO_B = 3.9; //3.6

static final float KEYBORDER_B = .4;
static final float KEYWRATIO_B = .75;

static final int KEYCLOW = 20;

// spotlight parameters
static final int SPOTWID1 = 500;//200;
static final int SPOTWID2 = 400;//140;
static final int SPOTHI = 30;

// feedback bar parameters
static float FEEDY;
static final int FEEDH = 20;

// -------------------------------data structs----------------------------------
KeyGuide[] keys = new KeyGuide[KEYNUM];
KeyGuide[] feedBar = new KeyGuide[KEYNUM];

Set chordSet = new HashSet();

static int MIDIOUTCH;
static int MIDIINCH;

static int mouseXold;
	
// check if we got black key: mod 12: 1, 4, 6, 9, 11
// white: 0 2 3 5 7 8 10
// width    1 2 3 4 5 6
// piano 88 keys, 36 black, 52 white

void setup() {
	// colorMode(HSB,100);
	size(SCREENWTOTAL,SCREENH);
	background(0);
	smooth();
	float keywidth = float(SCREENW)/WHITEKEYNUM;
	float keywidth_b = (SCREENW-3*keywidth)/(KEYNUM-4);
	float keyoffset_b = 2*(keywidth-keywidth_b);
	float posy_w = SCREENH-keywidth*KEYRATIO_W-1;
	float posy_b = posy_w -10; //posy_w - keywidth*(KEYRATIO_W-KEYRATIO_B)/2;
	FEEDY = posy_w-25;
	int curWhite = 0;
	for (int i = 0; i < keys.length; i ++ ) {
		int scale = i % 12;
		if (scale==1 || scale==4 || scale==6 || scale==9 || scale==11) {
			// keys[i] = new KeyGuide(KEYCLOW,keyoffset_b+keywidth_b*(i-1) ,posy_b,keywidth_b*KEYWRATIO_B,keywidth*KEYRATIO_B, false);
			keys[i] = new KeyGuide(KEYCLOW,
				keyoffset_b+keywidth_b*(i-1)+keywidth_b*(1-KEYWRATIO_B)/2
			 	,posy_b,keywidth_b*KEYWRATIO_B,keywidth*KEYRATIO_B, false);
			
		} else {	//white keys
			keys[i] = new KeyGuide(KEYCLOW,keywidth*(curWhite) ,posy_w,keywidth,keywidth*KEYRATIO_W, true);
			curWhite ++;
			// curWhite %=7;
		}
		// feedBar[i] = new KeyGuide(KEYCLOW,keyoffset_b+keywidth_b*(i-.5) ,175,keywidth_b*KEYWRATIO_B,20, true);
		feedBar[i] = new KeyGuide(KEYCLOW,
			keyoffset_b+keywidth_b*(i-1)+keywidth_b*(1-KEYWRATIO_B)/2,
			FEEDY,keywidth_b*KEYWRATIO_B,FEEDH, true);
		
		// if (scale==3 || scale==7 || scale==10 || scale==1) {
		// 	keys[i].isActiveGuide = true;
		// }
		// keys[i].isActiveGuide = true;
	}

	//get an instance of MidiIO
	midiIO = MidiIO.getInstance(this);
	println("printPorts of midiIO");

	//print a list of all available devices
	midiIO.printDevices();

	for (int i=0; i<midiIO.numberOfInputDevices(); i++) {
		if(midiIO.getInputDeviceName(i).equals("In")){
			MIDIINCH = i;
			break;
		}
	}

	for (int i=0; i<midiIO.numberOfOutputDevices(); i++) {
		if(midiIO.getOutputDeviceName(i).equals("Bus 1")){
			MIDIOUTCH = i;
			break;
		}
	}
	
	//open the first midi channel of the first device
	midiIO.openInput(MIDIINCH,0);
	midiOut = midiIO.getMidiOut(MIDIOUTCH,0);
	
	// chord_thread = new ChordThread();
	// chord_thread.start();
	
	// ------------------------------initialize kinect:
	OpenCV ocv = new OpenCV( this );
	tracker	= new HandTracker(SCREENW,0, ocv);
}

void keyPressed() {
	if (key == CODED) {
		if (keyCode == UP) {
			tracker.CVThreshold += 1;
		} else if (keyCode == DOWN) {
			tracker.CVThreshold -= 1;
		} 
	} else {
		if (key == 116) {
			tracker.thre = !tracker.thre;
			print(tracker.thre);
		} else if (key == 'b') {
			// do background
			if (tracker.backCollect == 0) {
				tracker.backCollect = tracker.BACKFRAMES;				
			}
		} else if (key =='m') {
			if (tracker.markMode == 0){
				tracker.markMode = 2;				
			}
		} else if (key =='s') {
			tracker.hand1x.clear();
			tracker.hand1y.clear();
			tracker.hand2x.clear();
			tracker.hand2y.clear();
		}
	}
}

void mouseMoved() {
	for (int i = 0; i < keys.length; i ++ ) { // Run each Car using a for loop.
		// if (abs(keys[i].xpos - mouseX) < keys[i].width/2 && 
		// 	abs(keys[i].ypos - mouseY) < keys[i].height/2) {
		// 	keys[i].temp = 60;
		// // } else {
		// 	// keys[i].temp = 20;
		// }
		if (!keys[i].isActiveGuide) {
			continue;
		}
		int dist = int(abs(keys[i].xpos - mouseX));
		if (dist < SPOTWID1) {
			if (dist < SPOTWID2) {
				keys[i].curB = int(keys[i].lowB +SPOTHI);
			} else {
				keys[i].curB = int(keys[i].lowB +
				 	SPOTHI*(SPOTWID1-dist)/(SPOTWID1-SPOTWID2));
			}
		} else {
			keys[i].curB = keys[i].lowB;
		}
	}
}

void mouseDragged() {		
	// fire active notes while we glide
	for (int i = 0; i < keys.length; i ++ ) { // Run each Car using a for loop.
		// if (abs(keys[i].xpos - mouseX) < keys[i].width/2 && 
		// 	abs(keys[i].ypos - mouseY) < keys[i].height/2) {
		// 	keys[i].temp = 60;
		// // } else {
		// 	// keys[i].temp = 20;
		// }
		if (!keys[i].isActiveGuide) {
			continue;
		}
		int dist = int(abs(keys[i].xpos - mouseX));
		if (dist < SPOTWID1) {
			if (dist < SPOTWID2) {
				keys[i].curB = int(keys[i].lowB +SPOTHI);
			} else {
				keys[i].curB = int(keys[i].lowB +
				 	SPOTHI*(SPOTWID1-dist)/(SPOTWID1-SPOTWID2));
			}
		} else {
			keys[i].curB = keys[i].lowB;
		}
	}
	
	
	Note note;
	for (int i = 0; i < keys.length; i ++ ) { // Run each Car using a for loop.
		if (!keys[i].isActiveGuide) {
			continue;
		}
		if (abs(keys[i].xpos+keys[i].width/2  - mouseX) < keys[i].width/2 && abs(keys[i].xpos+keys[i].width/2 - mouseXold) >= keys[i].width/2) {
			// keys[i].curB = 60;
			// print("hit");
		// } else {
			// keys[i].temp = 20;

			int vel = int(mouseY/10f)+20;
			note = new Note(i+21,vel,300);
			
			feedBar[i].height = FEEDH + vel*2;
			feedBar[i].ypos = FEEDY - vel*2;
			// feedBar[pit-21].isOn = true;
			
		    midiOut.sendNote(note);
		}
	}
	mouseXold = mouseX;
}

void mousePressed() {
	// Note note;
	// for (int i = 0; i < keys.length; i ++ ) {
	// 	if (abs(keys[i].xpos+keys[i].width/2  - mouseX) < keys[i].width/2 && 
	// 		abs(keys[i].ypos+keys[i].height/2 - mouseY) < keys[i].height/2) {
	// 		keys[i].curB = 60;			
	// 		note = new Note(i+21,int(mouseY/10f)+30,300);
	// 	    midiOut.sendNote(note);
	// 	}
	// }
	
	if (tracker.markMode == 2) {
		tracker.guide1x = mouseX-SCREENW;
		tracker.guide1y = mouseY;
		tracker.markMode--;
		print(str(tracker.guide1x)+ str(tracker.guide1y));
	} else if (tracker.markMode == 1) {
		tracker.guide2x = mouseX-SCREENW;
		tracker.guide2y = mouseY;
		tracker.markMode--;
		tracker.guidelen = (float) Math.sqrt(Math.pow(tracker.guide2x-tracker.guide1x,2) + Math.pow(tracker.guide2x-tracker.guide1x,2));
		print(str(tracker.guide2x)+ str(tracker.guide2y));
		
	}
}

void draw() {
	colorMode(HSB,100);
	
	// mouse test: find which key the mouse is on top of
	for (int i = 0; i < keys.length; i ++ ) {
		if (keys[i].isWhite) {
			keys[i].display();
		}
		feedBar[i].blackOut();
		if (feedBar[i].height > FEEDH && !feedBar[i].isOn) {
			feedBar[i].height-=4;
			feedBar[i].ypos +=4; //FEEDY
		}
		feedBar[i].display();			
	}
	
	for (int i = 0; i < keys.length; i ++ ) {
		if (!keys[i].isWhite) {
			keys[i].display();			
		}
		
		if (!keys[i].isActiveGuide) {
			if (keys[i].curB > keys[i].lowB) {
				keys[i].curB -=2;
			}
			continue;
		}
		int dist = int(abs(keys[i].xpos - mouseX));
		if (dist < SPOTWID1) {
			if (dist < SPOTWID2) {
				keys[i].curB = int(keys[i].lowB +SPOTHI);
			} else {
				keys[i].curB = int(keys[i].lowB +
				 	SPOTHI*(SPOTWID1-dist)/(SPOTWID1-SPOTWID2));
			}
		} else {
			keys[i].curB = keys[i].lowB;
		}
	}
	
	// draw staff lines:
	// float spacing = 12;
	// for (int i = 0; i < 5; i++) {
	// 	stroke(100);
	// 	strokeWeight(1);
	// 	line(100,10+i*spacing,200,10+i*spacing);
	// 	line(100,10+(i+7)*spacing,200,10+(i+7)*spacing);
	// }
	
	// //draw notes:
	// ellipseMode(CORNER);
	// fill(100);
	// smooth();
	// ellipse(150,10+2,spacing+2,spacing*0.66);
	// // ellipse(150,27,12,7);
	// 
	// for (int i = 0; i < keys.length; i ++ ) { 
	// 
	// }


	// if (chord_thread.fresh) {
		fill(color(0, 0, 0));
		// chord_thread.fresh=false;
			// rectMode(CORNERS); //rectMode(CENTER);
		rect(SCREENW/2,0,400,40);
		// fill(color(0,0,100));
		// text(chord_thread.outString,SCREENW/2,30);
			// chord_thread.updateChord(chordSet);
	// }
	colorMode(RGB,255);
	tracker.display();
}

void noteOn(Note note, int device, int channel){
  int vel = note.getVelocity();
  int pit = note.getPitch();
	keys[pit-21].isOn = true;
	chordSet.add(pit-21);
	// print(chordSet);
	
	feedBar[pit-21].oldHeight = feedBar[pit-21].height;
	feedBar[pit-21].height = FEEDH + vel*2;
	feedBar[pit-21].ypos = FEEDY - vel*2;
	feedBar[pit-21].isOn = true;
	
	// activate octaves:
	for (int i = 0; i < keys.length; i ++ ) { // Run each Car using a for loop.
		//    keys[i].drive();
		keys[i].isActiveGuide = false;
		Iterator chorditer = chordSet.iterator();
		while(chorditer.hasNext()) {
			Object n = chorditer.next();
			int nint =((Number)n).intValue();
			if (i == nint) { keys[i].isActiveGuide = false; break; }
			if ((i - nint)%12 == 0) {
				keys[i].isActiveGuide = true;
				break;
			}
		}
	}

	// call for chord recognizer:
	// chord_thread.updateChord(chordSet);
}

void noteOff(Note note, int device, int channel){
  	int pit = note.getPitch();
	int vel = note.getVelocity();
	keys[pit-21].isOn = false;
	chordSet.remove(pit-21);	
	feedBar[pit-21].isOn = false;
	if ((feedBar[pit-21].height - FEEDH)/2 == vel) {
		// feedBar[pit-21].blackOut();
		feedBar[pit-21].height = feedBar[pit-21].oldHeight;
		feedBar[pit-21].ypos = FEEDY-feedBar[pit-21].height+FEEDH;
	}
	
	
	for (int i = 0; i < keys.length; i ++ ) { // Run each Car using a for loop.
		//    keys[i].drive();
		keys[i].isActiveGuide = false;
		Iterator chorditer = chordSet.iterator();
		while(chorditer.hasNext()) {
			Object n = chorditer.next();
			int nint =((Number)n).intValue();
			if (i == nint) { keys[i].isActiveGuide = false; break; }
			if ((i - nint)%12 == 0) {
				keys[i].isActiveGuide = true;
				break;
			}
		}
	}
}
