
/* Classes */

public class TrackerThread extends Thread {
  	private boolean running;	     // Is the thread running?  Yes or no?
	HandTracker trkr;	// actual hand tracker object
   	boolean fresh;		 // Is there fresh data to be polled?
  
  // Constructor, create the thread
  	public TrackerThread(int xoff, int yoff, OpenCV newOCV) {
		tracker	= new HandTracker(xoff, yoff, newOCV);
		running = false;
  	}
  
  	public void start() {
	    // Set running equal to true
	    running = true;
	    fresh = false;
		print("starting tracker thread");
	    // Do whatever start does in Thread, don't forget this!
	    super.start();
  	}
  
	
	public void run() {
		while (true) {
			// tracker.update();
		}
	}
}
