/* compress/save kinect frame data to disk, append tracking data to file */

public class DataProcThread extends Thread {
  	private boolean running;	     // Is the thread running?  Yes or no?
	PImage img, depth;
	String outString;
	boolean fresh;		 // Is there fresh data to be polled?
  // int[] labjack_fields = new int[16];
  
  // Constructor, create the thread
  // It is not running by default
  public ChordThread() {
	running = false;
  }
  
  public void start() {
    // Set running equal to true
    running = true;
    fresh = true;
	outString = "";
    // Print messages
	print("starting chord thread");
    // Do whatever start does in Thread, don't forget this!
    super.start();
  }
  
	// public void updateChord(Set chordSet) {
	// 	noteSet = "";
	// 	Iterator chorditer = chordSet.iterator();
	// 	while(chorditer.hasNext()) {
	// 		Object n = chorditer.next();
	// 		int nint =((Number)n).intValue();
	// 		nint = (nint - 3)%12+1;
	// 		noteSet +=" "+str(nint);
	// 	}
	// 	// print(noteSet);
	// }
	
	public void run() {
		String line;
		OutputStream stdin = null;


		depth.save(BASEPATH + "/rec/d"+now+".tif");
		img.save(BASEPATH + "/vid/v"+now+".tif");


	}
}
