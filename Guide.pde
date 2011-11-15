import promidi.*;
import java.io.*;

import king.kinect.*;
import hypermedia.video.*;
import java.util.LinkedList;

ChordThread chord_thread;
HandTracker tracker;

MidiIO midiIO;
MidiOut midiOut;

ParticleSystem ps;

// -------------------------------parameters------------------------------------

static final int KEYNUM = 88;
static final int WHITEKEYNUM = 52;
static int SCREENW = 1227;//2005;//2150;
static int SCREENWTOTAL = SCREENW + 640;
static final int SCREENH = 600;
// key dimension, defined by ratio between white key width and heights
static final int KEYRATIO_W = 6; //6
static final float KEYRATIO_B = 4.2; //3.9

static final float KEYBORDER_B = .4;
static final float KEYWRATIO_B = .75;

static final int KEYCLOW = 20;

// spotlight parameters
static final int SPOTWID1 = 200;//200;
static final int SPOTWID2 = 120;//140;
static final int SPOTHI = 60;

// feedback bar parameters
static float FEEDY;					// location of feed bars, calculated
static final int FEEDH = 10;		//minimal height
static final float FEEDRATIO = 0.4; // how high the velocity is shown

static final float XSCALE = 1.9;
static final float YSCALE = 2;
static final int XOFF = 240;
static final int YOFF = -640;

static float TEMPO = 0.03;

// skip frames for sending MIDI messages
static int SKIPFR = 5; //send expression every this many frames

// Particle system:
static int PARTICLETHE = 70; // hand width threshold for activate particles

// -------------------------------data structs----------------------------------
KeyGuide[] keys = new KeyGuide[KEYNUM];
KeyGuide[] feedBar = new KeyGuide[KEYNUM];

Set chordSet = new HashSet();

static int MIDIOUTCH;
static int MIDIINCH;

static int mouseXold;
static float h1xold,h2xold;
static boolean useFeedbackBar;
// check if we got black key: mod 12: 1, 4, 6, 9, 11
// white: 0 2 3 5 7 8 10
// width    1 2 3 4 5 6
// piano 88 keys, 36 black, 52 white

int skipframes;

LinkedList<MidiNote> song;
MidiDisplay songGuide;
boolean songPlaying, playingHarp, useChordGuide,useMIDIGuide, showKeys,particle;
boolean MIDIon;
int MIDIchanY, MIDIchanZ, MIDIchanW;

void setup() {
	// colorMode(HSB,100);
	skipframes = 0;
	useFeedbackBar = true;
	size(SCREENWTOTAL,SCREENH);
	background(0);
	smooth();
	float keywidth = float(SCREENW)/WHITEKEYNUM;
	float keywidth_b = (SCREENW-3*keywidth)/(KEYNUM-4);
	float keyoffset_b = 2*(keywidth-keywidth_b);
	float posy_w = SCREENH-keywidth*KEYRATIO_W-1;
	float posy_b = posy_w -10; //posy_w - keywidth*(KEYRATIO_W-KEYRATIO_B)/2;
	FEEDY = posy_w-10;
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
		
		if (scale==3 || scale==7 || scale==10 || scale==1) {
			keys[i].isActiveGuide = true;
		}
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
	OpenCV ocv = new OpenCV(this);
	tracker	= new HandTracker(SCREENW,0, ocv);
	
	// ------------------------------initialize MIDI guide
	String file = "/Users/Tim/Documents/Processing/MIDIReader/Clocks - carillon.mid";
	
	// "/Users/Tim/Documents/Scores/Carillon - Sjef van Balkom.mid";
	 //"/Users/Tim/Documents/Processing/MIDIReader/Faure_pavane.mid";
	
	
	// song = MIDIReader(file);
	// songGuide = new MidiDisplay(song, 
	// 							keyoffset_b, 
	// 							10.0, FEEDY, 
	// 							keywidth_b, keywidth_b*(1-KEYWRATIO_B)/2);
	
	// --------------------------------initialize particle generator:
	  // Create an alpha masked image to be applied as the particle's texture
	ps = new ParticleSystem(1, new PVector(width/2,height/2,0));
	
	songPlaying = false;
	playingHarp = false;
	useChordGuide = true;
	useMIDIGuide = false;
	showKeys = true;
	particle =false;
	MIDIon = false;
	MIDIchanY = MIDIchanZ = MIDIchanW = -1;
}

void keyPressed() {
	if (key == CODED) {
		if (keyCode == UP) {
			tracker.CVThreshold += 1;
			// TEMPO += 0.001;
			print(tracker.CVThreshold);
		} else if (keyCode == DOWN) {
			tracker.CVThreshold -= 1;
			// TEMPO -= 0.001;
			print(tracker.CVThreshold);
		} 
	} else {
		switch (key) {
			case 'b': tracker.resetBackground();	break;
		 	case 'm':
				if (tracker.markMode == 0){
					tracker.markMode = 2;				
				}									break;
			case 's': tracker.resetTracking();		break;
			case 'h': playingHarp=!playingHarp;		break;
			case 'g': useChordGuide = !useChordGuide;
				useMIDIGuide = !useMIDIGuide;		break;
			case 'r': tracker.startStopRecording();	break;
			case 'v': showKeys = !showKeys;			break;
			case 'p': particle = !particle;			break;
			case '1': 
				if (MIDIchanY < 0) {
					MIDIchanY = 16;
				} else if (MIDIchanY == 18) {
					MIDIchanY = -1;
				} else {
					MIDIchanY += 1;
				}									break;
			case '2': 
				if (MIDIchanZ < 0) {
					MIDIchanZ = 16;
				} else if (MIDIchanZ == 18) {
					MIDIchanZ = -1;
				} else {
					MIDIchanZ += 1;
				}									break;
			case '3': 
				if (MIDIchanW < 0) {
					MIDIchanW = 16;
				} else if (MIDIchanW == 18) {
					MIDIchanW = -1;
				} else {
					MIDIchanW += 1;
				}									break;
			case 'd': MIDIon = !MIDIon;				break;
			default: break;
		}		
	}
}

// void mouseMoved() {
// 	for (int i = 0; i < keys.length; i ++ ) { // Run each Car using a for loop.
// 		// if (abs(keys[i].xpos - mouseX) < keys[i].width/2 && 
// 		// 	abs(keys[i].ypos - mouseY) < keys[i].height/2) {
// 		// 	keys[i].temp = 60;
// 		// // } else {
// 		// 	// keys[i].temp = 20;
// 		// }
// 		if (!keys[i].isActiveGuide) {
// 			continue;
// 		}
// 		int dist = int(abs(keys[i].xpos - mouseX));
// 		if (dist < SPOTWID1) {
// 			if (dist < SPOTWID2) {
// 				keys[i].curB = int(keys[i].lowB +SPOTHI);
// 			} else {
// 				keys[i].curB = int(keys[i].lowB +
// 				 	SPOTHI*(SPOTWID1-dist)/(SPOTWID1-SPOTWID2));
// 			}
// 		} else {
// 			keys[i].curB = keys[i].lowB;
// 		}
// 	}
// }

void mouseDragged() {
	// fire active notes while we glide
	// for (int i = 0; i < keys.length; i ++ ) { // Run each Car using a for loop.
	// 	// if (abs(keys[i].xpos - mouseX) < keys[i].width/2 && 
	// 	// 	abs(keys[i].ypos - mouseY) < keys[i].height/2) {
	// 	// 	keys[i].temp = 60;
	// 	// // } else {
	// 	// 	// keys[i].temp = 20;
	// 	// }
	// 	if (!keys[i].isActiveGuide) {
	// 		continue;
	// 	}
	// 	int dist = int(abs(keys[i].xpos - mouseX));
	// 	if (dist < SPOTWID1) {
	// 		if (dist < SPOTWID2) {
	// 			keys[i].curB = int(keys[i].lowB +SPOTHI);
	// 		} else {
	// 			keys[i].curB = int(keys[i].lowB +
	// 			 	SPOTHI*(SPOTWID1-dist)/(SPOTWID1-SPOTWID2));
	// 		}
	// 	} else {
	// 		keys[i].curB = keys[i].lowB;
	// 	}
	// }
	
	
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
			
			if (useFeedbackBar) {
				feedBar[i].height = FEEDH + vel*FEEDRATIO;
				feedBar[i].ypos = FEEDY - vel*FEEDRATIO;				
			} else {
				feedBar[i].curB = feedBar[i].lowB+vel/128 * 100;
			}
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
	fill(0);
	noStroke();
	rect(0,0,SCREENW,SCREENH);
	// if (useMIDIGuide) {
	// 	songGuide.display();		
	// 	if (songPlaying) {
	// 		songGuide.forward(TEMPO);
	// 	}
	// }
	// print(songGuide.guideNotes);
	
	for (int i = 0; i < keys.length; i ++ ) {
		if (keys[i].isWhite && (showKeys || keys[i].isOn 
										|| keys[i].curB > keys[i].lowB)) {
			keys[i].display();
		}
		// feedBar[i].blackOut();
		if (feedBar[i].height > FEEDH && !feedBar[i].isOn) {
			feedBar[i].height-=4;
			feedBar[i].ypos +=4; //FEEDY
		} else if (!useFeedbackBar && feedBar[i].curB > feedBar[i].lowB) {
			feedBar[i].curB -=2;
		}
		if (showKeys || feedBar[i].height > FEEDH){
			feedBar[i].display();			
		}
		// if (useMIDIGuide){
		// 	keys[i].isActiveGuide = songGuide.guideNotes.contains(i-1);
		// 	// if (songGuide.guideNotes.contains(i)) {
		// 	// 	print("activating "+i+"\n");				
		// 	// }
		// }
	}
	
	for (int i = 0; i < keys.length; i ++ ) {
		if (!keys[i].isWhite && (showKeys || keys[i].isOn
										|| keys[i].curB > keys[i].lowB)) {
			keys[i].display();
		}
		
		if (!keys[i].isActiveGuide) {
			if (keys[i].curB > keys[i].lowB) {
				keys[i].curB -=2;
			}
			continue;
		}
		// int dist = int(abs(keys[i].xpos - mouseX));
		// if (dist < SPOTWID1) {
		// 	if (dist < SPOTWID2) {
		// 		keys[i].curB = int(keys[i].lowB +SPOTHI);
		// 	} else {
		// 		keys[i].curB = int(keys[i].lowB +
		// 		 	SPOTHI*(SPOTWID1-dist)/(SPOTWID1-SPOTWID2));
		// 	}
		// } else {
		// 	keys[i].curB = keys[i].lowB;
		// }
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
		// fill(color(0, 0, 0));
		// chord_thread.fresh=false;
			// rectMode(CORNERS); //rectMode(CENTER);
		// rect(SCREENW/2,0,400,40);
		// fill(color(0,0,100));
		// text(chord_thread.outString,SCREENW/2,30);
			// chord_thread.updateChord(chordSet);
	// }
	colorMode(RGB,255);
	tracker.display();
	ps.run();

	// if (particle) { ps.addParticle(mouseX,mouseY);}
	
	// draw hand bubble, if calibration exists
	if (tracker.guide2x >0 && (!tracker.hand1y.isEmpty() && !tracker.hand2y.isEmpty())) {
		// fill(200,200,200,50);
		stroke(0);
		float h1x = tracker.proj1;
		float h1y = tracker.hand1y.getLast();
		float h2x = tracker.proj2;
		float h2y = tracker.hand2y.getLast();
		
		h1x = h1x * XSCALE + XOFF;
		h2x = h2x * XSCALE + XOFF;
		h1y = (SCREENH -h1y) * YSCALE + YOFF-150;
		h2y = (SCREENH -h2y) * YSCALE + YOFF-150;
		
		if (tracker.on1) {
			fill(150,(tracker.vel1-90)*3.2,150,200);
			ellipse(h1x,h1y,tracker.wid1*2-10,tracker.wid1*2-10);
			text(str(tracker.vel1)+" "+str(tracker.wid1),h1x,h1y);
			if (particle && tracker.wid1 > PARTICLETHE) {
				 ps.addParticle(h1x,h1y,color(200,(tracker.vel1-90)*3.2,200));
			}
		}
		if (tracker.on2) {
			fill(150,(tracker.vel2-90)*3.2,150,200);
			ellipse(h2x,h2y,tracker.wid2*2-10,tracker.wid2*2-10);
			text(str(tracker.vel2)+" "+str(tracker.wid2),h2x,h2y);
			if (particle && tracker.wid2 > PARTICLETHE) {		
				ps.addParticle(h2x,h2y,color(200,(tracker.vel2-90)*3.2,200));
			}
		}
		int vel1 = Math.min((tracker.vel1-80)*2+47,127);
		int vel2 = Math.min((tracker.vel2-80)*2+47,127);
		vel1 = Math.max(vel1,20);
		vel2 = Math.max(vel2,20);
		
		if (skipframes == 0 && MIDIon) {
		
			// Y-axis send out MIDI expression messages: mod or damper?
			float newMod;
			if (MIDIchanY >0) {
				newMod = 
					Math.max(tracker.hand1y.getLast(),tracker.hand2y.getLast());
				newMod = Math.max((newMod-30)/2,1);
				newMod = Math.min(newMod,127);
				midiOut.sendController(new 
					Controller(MIDIchanY, Math.round(newMod)));
				// print("sent Y"+newMod+"\n");
			}
			
			// X-axis message?

			// send width/ open/close hand message?
			if (MIDIchanW>0 && (tracker.on1 || tracker.on2)) {
				if (tracker.hand1y.getLast()>tracker.hand2y.getLast() 
					&& tracker.on1) {
					newMod = tracker.wid1*1.2-30;
				} else {
					newMod = tracker.wid2*1.2-30;
				}
				// newMod = Math.round(Math.max(tracker.wid1,tracker.wid2)*1.2-30);
				newMod = Math.min(Math.max(newMod,0),127);
				midiOut.sendController(new 
					Controller(MIDIchanW, Math.round(newMod)));				
			}
			
			if (!playingHarp && MIDIchanZ>0) {
				float h = Math.min(127,
					Math.max((Math.max(tracker.vel1,tracker.vel2)-100)*2.4,0));
				midiOut.sendController(new 
					Controller(MIDIchanZ, Math.round(h)));
				// print(h);
				// print("\n");
			}
		}
		
		// print(newMod + "\n");
		
		//firing notes if they overlap:
		
		Note note;
		for (int i = 0; i < keys.length; i ++ ) {
			if (!keys[i].isActiveGuide) {
					continue;
			}
			
			if (skipframes == 0 &&
				abs(keys[i].xpos+keys[i].width/2  - h1x) < keys[i].width/2 &&
			 	abs(keys[i].xpos+keys[i].width/2 - h1xold) >= keys[i].width/2 
				&& h1y < SCREENH-80 && playingHarp) {

				// int vel = int(mouseY/10f)+20;
				note = new Note(i+21,vel1,400);

				feedBar[i].height = FEEDH + vel1*2;
				feedBar[i].ypos = FEEDY - vel1*2;
				// feedBar[i].isOn = true;
				// print(str(i+21)+" "+str(vel1)+"\n");
			    midiOut.sendNote(note);
			}
		
			if (skipframes == 0 &&
				abs(keys[i].xpos+keys[i].width/2-h2x) < keys[i].width/2 &&
			 	abs(keys[i].xpos+keys[i].width/2 - h2xold) >= keys[i].width/2
				&& h2y < SCREENH-80 && playingHarp) {

				// int vel = int(mouseY/10f)+20;
				note = new Note(i+21,vel2,400);

				feedBar[i].height = FEEDH + vel2*2;
				feedBar[i].ypos = FEEDY - vel2*2;
				// feedBar[i].isOn = true;
			
			    midiOut.sendNote(note);
			}
			
			float dist = Math.min(abs(keys[i].xpos - h1x),
								abs(keys[i].xpos - h2x));
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
		
		skipframes = (skipframes++) % SKIPFR;
		h1xold=h1x;
		h2xold=h2x;
	}
	printLabels();
}

void printLabels() {
	if (tracker.recording) {
		stroke(color(200,200,200));
		text("Recording",SCREENW/2,30);
	}
	noStroke();
	fill(0);
	rect(SCREENW,480,SCREENW+640,SCREENH);
	fill(color(200,200,200));
	text("MIDI expressions: " + MIDIon + "\n", SCREENW, 494);
	text("Y channel = " + MIDIchanY + "\n", SCREENW,506);
	text("Z channel = " + MIDIchanZ + "\n", SCREENW,518);
	text("W channel = " + MIDIchanW + "\n", SCREENW,530);
}


void noteOn(Note note, int device, int channel){
  int vel = note.getVelocity();
  int pit = note.getPitch();
	keys[pit-21].isOn = true;
	chordSet.add(pit-21);
	// print(chordSet);
	
	feedBar[pit-21].oldHeight = feedBar[pit-21].height;
	feedBar[pit-21].height = FEEDH + vel*FEEDRATIO;
	feedBar[pit-21].ypos = FEEDY - vel*FEEDRATIO;
	feedBar[pit-21].isOn = true;
	
	// activate octaves:
	if (useChordGuide) {
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
	
	if (useChordGuide) {
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
}
