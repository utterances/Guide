/* compress/save kinect frame data to disk, append tracking data to file */
// import king.kinect.*;
// import hypermedia.video.*;


/*
import java.applet.*;
import java.awt.*;

public class CounterThread extends Applet implements Runnable
{	
	Thread t;	
	int Count;

	public void init()	
	{	
		Count=0;
		t=new Thread(this);
		t.start();
	}

	public boolean mouseDown(Event e,int x, int y)
	{	
		t.stop();
		return true;
	}

	public void run()
	{
		while(true)
		{
			Count++;
			repaint();
			try {
				t.sleep(10);
			} catch (InterruptedException e) {}
		}
	}

	public void paint(Graphics g)
	{
		g.drawString(Integer.toString(Count),10,10);
		System.out.println("Count= "+Count);
	}

	public void stop()
	{
		t.stop();
	}
}
*/


public class DataProcThread extends Thread {
	private final String BASEPATH = "/Users/Tim/Documents/Processing/Data/";
  	private boolean running;	     // Is the thread running?
	PImage img, depth;
	// String outString;
	long time;
	boolean fresh;
  
  // Constructor, create the thread
  // It is not running by default
	public DataProcThread() {
		running = false;
	}
  
  	public void start() {
    	// Set running equal to true
	    running = true;
		fresh = false;
	    // Print messages
		print("starting data proc thread");
	    // Do whatever start does in Thread, don't forget this!
    	super.start();
  	}
  
	public void setData(PImage vid, PImage dep, long newTime) {
		img = vid;
		depth = dep;
		time = newTime;
		fresh = true;
	}
	
	public void run() {
		String line;
		OutputStream stdin = null;

		while (running) {
			if (fresh) {
				print("@");
				// depth.save(BASEPATH + "/rec/d"+time+".tif");
				// img.save(BASEPATH + "/vid/v"+time+".tif");
			}
		}
	}
	
	// Our method that quits the thread
	  	public void quit() {
	    	System.out.println("Quitting."); 
	    	running = false;  // Setting running to false ends the loop in run()
	    // IUn case the thread is waiting. . .
	    interrupt();
	}
}
