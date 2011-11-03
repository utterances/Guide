
/* Classes */

public class TrackerThread extends Thread {
  	private boolean running;	     // Is the thread running?  Yes or no?
	HandTracker tracker;
   	boolean fresh;		 // Is there fresh data to be polled?
  
  // Constructor, create the thread
  // It is not running by default
  	public TrackerThread() {
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
		}
	}
}
