// class encapsulating kinect module, uses openCV

import king.kinect.*;
import hypermedia.video.*;
import java.util.LinkedList;
import java.util.Date;

class HandTracker { 

	//----------------------------Recorder paths -------------------------------
	final String BASEPATH = "/Users/Tim/Documents/Processing/Data/";

	//----------------------------Kinect Parameters-----------------------------

	final int minCVDetectArea = 1300;
	final int maxCVDetectArea = 38400;
	final int maxNumBlobs = 3;
	final int BACKFRAMES = 20;	//how many frames to use to build background
	final int NORMDIST = 106;  	//hand size
	final int BACKTHRES = 10;	//threshold for background subtraction
	final int SMOOTHDIST = 70;	//max dist for hand motion smoothing, squared
	final int SMOOTHFR = 7; 	//uses this many frames for smoothing
	// final int KEYCOUNT = 61;	//number of keys, roughly, for keyguide
	
	int CVThreshold = 93; //80
	int markMode = 0;
	int backCollect = 20;
	boolean thre = true;
	int lastPitch = -1;

	// ---------------------------kinect data-----------------------------------
	OpenCV opencv;
	PImage img, depth, back;
	float guide1x,guide1y,guide2x,guide2y,guidelen;
	LinkedList<Float> hand1x, hand1y, hand2x, hand2y;
	int vel1,vel2,wid1,wid2; //velocity/pixel value and hand size
	float proj1,proj1p,proj2,proj2p;
	int viewx,viewy;
	boolean on1,on2;
	
	// -------------------------- other data and structs
	DataProcThread dataThread; // use to save data to disk on 2nd thread
	String streamfile;
	int fps, disfps;
	long lastS;
	
	// -----external setting-----
	boolean recording;
	
	HandTracker(int xpos, int ypos, OpenCV newopencv) { 
		NativeKinect.init();
		NativeKinect.start();

		dataThread = new DataProcThread();
		dataThread.start();
		
		img = createImage(640,480,RGB);
		depth = createImage(640,480,RGB);
		back = createImage(640,480,RGB);

		opencv = newopencv;
		opencv.allocate(640,480);
		hand1x = new LinkedList<Float>();
		hand1y = new LinkedList<Float>();
		hand2x = new LinkedList<Float>();
		hand2y = new LinkedList<Float>();
		guide2x = -1;
		proj1p = -1;
		proj1 = -1;
		proj2p = -1;
		proj2 = -1;
		viewx = xpos;
		viewy = ypos;
		on1= false;
		on2= false;
		recording = false;
		streamfile = "";
		fps = disfps =0;
		lastS = -1;
	}
	
	void startStopRecording() {
		// flip recording state
		recording = !recording;		
		if (!recording) {
			streamfile = "";
		}
	}
	
	void resetTracking() {
		hand1x.clear();
		hand1y.clear();
		hand2x.clear();
		hand2y.clear();
	}
	
	void resetBackground() {
		// do background
		if (backCollect == 0) {
			backCollect = BACKFRAMES;				
		}
	}
	
	void display() {
		depth.pixels = NativeKinect.getDepthMap();
		depth.updatePixels();
		img.pixels = NativeKinect.getVideo();
		img.updatePixels();
		// image(depth,viewx,viewy,640,480);
		if (backCollect>0) {
			back.loadPixels();
			if (backCollect == BACKFRAMES){
				arrayCopy(depth.pixels, back.pixels);
			} else {
				float r,g,b;
				int fCount = BACKFRAMES - backCollect+1;
				for (int i=0; i<depth.pixels.length; i++){
					r = (red(depth.pixels[i]) + red(back.pixels[i])*fCount);
					g = (green(depth.pixels[i]) + green(back.pixels[i])*fCount);
					b = (blue(depth.pixels[i]) + blue(back.pixels[i])*fCount);
					back.pixels[i] = color(r/(fCount+1),g/(fCount+1),b/(fCount+1));
				}	
			}

			backCollect--;
			if (backCollect == 0) {
				print("done background\n");
			}
			back.updatePixels();			
			print(".");
		}
		
		// // ======================== save kinect data ===========================
		// long now = System.currentTimeMillis();
		// if (recording) {
		// 	// Date now = new Date();
		// 	// long now = System.currentTimeMillis();
		// 	depth.save("./rec/d"+now+".tga");
		// 	img.save("./vid/v"+now+".tif");
		// }
		depth.loadPixels();
		for (int i=0; i<depth.pixels.length; i++){
			float r,g,b;
			r = red(depth.pixels[i]) - red(back.pixels[i]);
			g = green(depth.pixels[i]) - green(back.pixels[i]);
			b = blue(depth.pixels[i]) - blue(back.pixels[i]);
			if (abs(r+g+b) < BACKTHRES) {
				depth.pixels[i] = color(10);
			}
		}
		depth.updatePixels();
		image(depth,viewx,viewy,640,480);
		
		// ======================== save kinect data ===========================
		long now = System.currentTimeMillis();
		if (recording) {
			dataThread.setData(img,depth,now);
		}
		// ========================= end save kinect data ======================

		opencv.copy(depth);
		if (thre) {
			opencv.threshold(CVThreshold);		
		}
		// image(opencv.image(),640,0,640,480);
		
		strokeWeight(1);
		on1=false;
		on2=false;
		Blob[] blobs = opencv.blobs(minCVDetectArea, maxCVDetectArea, maxNumBlobs, false, OpenCV.MAX_VERTICES*4);
		for( int i=0; i<blobs.length; i++ ) {

			// filter/normalize blob first:
			float centX = 0, centY = 0;
			int maxX = -1, minX = -1, maxY = -1, minY = -1;
			for( int j=0; j<blobs[i].points.length; j++ ) {
				if (blobs[i].points[j].y > maxY) {
					maxY = blobs[i].points[j].y;
				}
			}
			
			// draw hand blobs
			fill(204, 102, 0, 45);
			noStroke();
			beginShape();
			int cx=0, cy=0;
			for( int j=0; j<blobs[i].points.length; j++ ) {
				if (maxY - blobs[i].points[j].y < NORMDIST) {
					
					float hx = SCREENW - blobs[i].points[j].x * SCALE + XOFF;
					float hy = (SCREENH -blobs[i].points[j].y) * SCALE + YOFF;
					vertex(hx,hy);
					
					// vertex( blobs[i].points[j].x+viewx, blobs[i].points[j].y+viewy );
					if (maxY - blobs[i].points[j].y < NORMDIST/2) {
						// centX+=blobs[i].points[j].x;
						// cx++;
						if (blobs[i].points[j].x > maxX){
							maxX = blobs[i].points[j].x;
						}	
						if (blobs[i].points[j].x < minX || minX <0){
							minX = blobs[i].points[j].x;				
						}
					}
					// centY+=blobs[i].points[j].y;
					// cy++;
					if (blobs[i].points[j].y < minY || minY <0){
						minY = blobs[i].points[j].y;				
					}
				}
			}
			endShape(CLOSE);
			// centX/=cx;
			centX=(maxX+minX)/2;
			// centY/=cy;
			centY=(maxY+minY)/2;
			String lab = "N"; 
			float d1 = 0, d2 = 0;
			if (!hand1x.isEmpty() && !hand2x.isEmpty()) {
				// do smoothing:
				d1 = (float)(Math.pow(hand1x.getLast()-centX,2)
							+Math.pow(hand1y.getLast()-centY,2));
				d2 = (float)(Math.pow(hand2x.getLast()-centX,2)
							+Math.pow(hand2y.getLast()-centY,2));
				if (d1<d2) {
					wid1 = maxX - minX;
					lab = "A ";
					hand1x.add(centX);
					hand1y.add(centY);

					if (hand1x.size()>SMOOTHFR) {
						hand1x.removeFirst();
						hand1y.removeFirst();
					}
					int dx = 0, dy = 0;
					for ( int j=0; j<hand1x.size(); j++ ) {
						centX+=hand1x.get(j).floatValue();
						centY+=hand1y.get(j).floatValue();
						if (j>0) {
							dx+=hand1x.get(j)-hand1x.get(j-1);
							dy+=hand1y.get(j)-hand1y.get(j-1);
						}
					}
					dx/=hand1x.size()-1;
					dy/=hand1x.size()-1;
					centX= (centX+hand1x.getLast()+dx)/(hand1x.size()+2);
					centY= (centY+hand1y.getLast()+dy)/(hand1x.size()+2);
					on1 = true;
				} else {
					wid2 = maxX - minX;
					lab="B ";
					hand2x.add(centX);
					hand2y.add(centY);

					if (hand2x.size()>SMOOTHFR) {
						hand2x.removeFirst();
						hand2y.removeFirst();
					}
					int dx = 0, dy = 0;
					for ( int j=0; j<hand2x.size(); j++ ) {
						centX+=hand2x.get(j).floatValue();
						centY+=hand2y.get(j).floatValue();
						if (j>0) {
							dx+=hand2x.get(j)-hand2x.get(j-1);
							dy+=hand2y.get(j)-hand2y.get(j-1);
						}
					}
					dx/=hand2x.size()-1;
					dy/=hand2x.size()-1;
					centX= (centX+hand2x.getLast()+dx)/(hand2x.size()+2);
					centY= (centY+hand2y.getLast()+dy)/(hand2x.size()+2);
					on2 = true;
				}
			} else if (hand1x.size()==0){
				hand1x.add(centX);
				hand1y.add(centY);
			} else {
				hand2x.add(centX);
				hand2y.add(centY);
			}
			// project point onto the keyboard guide, to get actual notes/X axis
			// A dot B / |B|
			float proj = (centX-guide1x)*(guide2x-guide1x)+
						(centY-guide1y)*(guide2y-guide1y);
			proj /= guidelen;
			
			// int vel = Math.round(brightness(depth.get(int(centX),int(centY))));
			int vel = 0;
			for (int j=minX ; j<maxX; j++ ) {
				int bright = Math.round(brightness(
						depth.get(int(j),int(centY))));
				if (bright >vel) {
					vel = bright;
				}
			}
			// vertex( blobs[i].points[j].x+viewx, blobs[i].points[j].y+viewy );
			stroke(color(255,0,0));
			line(minX+viewx,centY+viewy,maxX+viewx,centY+viewy);
						
			if (d1>0||d2>0) {
				if (d1<d2) {
					proj1p = proj1;
					proj1 = proj;
					vel1=vel;
				} else {
					proj2p = proj2;
					proj2 = proj;
					vel2=vel;
				}
			}
			// int pitch = Math.round(proj/guidelen*KEYCOUNT);
			// if (oldpit>0 && proj>0 && Math.round(oldpit/guidelen*KEYCOUNT)!=pitch&&lastPitch!=pitch){
			// 	int velocity = Math.round((vel-60)*2);
			// 	if (velocity>0) {
			// 		if (velocity>127) { velocity = 127;}
			// 		if (pitch<0) { pitch = 0; }
			// 		Note note = new Note(pitch+21+24,velocity,400);		
			//     	midiOut.sendNote(note);
			// 		print(str(pitch)+" "+str(velocity)+"\n");
			// 		lastPitch = pitch;				
			// 	}
			// }

			fill(200,200,200,vel);
			ellipse(centX+viewx,centY+viewy,
				Math.max(vel*2-120,5),Math.max(vel*2-120,5));
			// print(str(vel)+" ");
			// ellipse((maxX+minX)/2+viewx,(maxY+minY)/2+viewy,10,10);
			fill(230,200,200);
			text(lab+str(vel)+" "+str(centY),centX+viewx,centY+viewy);

			// beginShape();
			// for( int j=0; j<blobs[i].points.length; j++ ) {
			// 	vertex( blobs[i].points[j].x+640, blobs[i].points[j].y );
			// }
			// endShape(CLOSE);
		}
		// image(opencv.image(),1280,0,640,480);
		
		// ======================== save tracker data ==========================
		if (recording && !hand1y.isEmpty() && !hand2y.isEmpty()) {
			// print("@");
			try {
				if (streamfile.equals("")) {
					streamfile = BASEPATH + "/track" + now;
					File file = new File(streamfile);
					print("saving trackng data to " + streamfile + "\n");
					if (!file.createNewFile()) {
						print("File already exists.");
					}
				}
				
				FileWriter fstream = new FileWriter(streamfile,true);
				BufferedWriter out = new BufferedWriter(fstream);
				out.write(now + ":" + hand1x.getLast() + " " + hand1y.getLast()
				 	+ " "+ vel1 + " " + wid1 + " "	+ hand2x.getLast() + " " +
				 	hand2y.getLast() + " " + vel2 + " " + wid2 + "\n");
				out.close();
			} catch (Exception e){			//Catch exception if any
				System.err.println("Error: " + e.getMessage());
			}
		}
		// ======================= count frames per sec ========================
		if (lastS != now/1000) {
			disfps = fps;
			fps = 0;
			lastS = now/1000;
		}
		fps += 1;
		// print(now/1000 + " " + lastS + "\n");
		// =========================================draw text and other overlay:
		fill(0,0,0,80);
		rect(0,0,200,200);
		fill(230,200,200);
		text("fps:"+str(disfps),viewx,viewy+30);
		text(str(CVThreshold),viewx,viewy+50);
		// text(str(proj),0,45);
		if (markMode == 2) {
			text("mark first point", 0, 60);
		} else if (markMode == 1) {
			text("mark second point", 0, 60);
			stroke(color(255,0,0));
			line(guide1x+viewx,guide1y+viewy,mouseX,mouseY);
		} else {
			stroke(color(255,0,0));
			line(guide1x+viewx,guide1y+viewy,guide2x+viewx,guide2y+viewy);		
		}
	}
}
