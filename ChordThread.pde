// 
// DataThread ping_thread;
// float time = 0;
// int min = 160;
// int max = 170;
// int index = 0;
// float[] numbers;
// 
// void setup() {
//   size(640,480);
//   frameRate(33);
//   numbers = new float[100];
//   ping_thread = new DataThread();
//   ping_thread.start();
//   background(255);
//   fill(0,40);
//   stroke(0,40);
//   smooth();
// }
// 
// void draw() {
//   background(255);
//   time += 0.1/20;
//   stroke(0,30);
//   line(0,height/2-height/8,width,height/2-height/8);
//   line(0,height/2+height/8,width,height/2+height/8);
//   line(0,height/2+height-height/6,width,height/2+height-height/6);
//   numbers[index % numbers.length] = ping_thread.getLatest(0);
//   //println(ping_thread.getLatest(0));
//   beginShape();
//   for (int i = 0; i < numbers.length + 1; i++) {
//     float value = numbers[(index+i+1)%numbers.length];
//     float spacing = (float) width /  (float) numbers.length;
//     value = map(value,5000,pow(2,16),height/2+height/8,height/2-height/8);
//     noFill();
//     curveVertex(spacing * i, value);
//     //ellipse(spacing * i, value, 20, 20);
//     stroke(0,180);
//   }
//   endShape();
//   index = (index + 1) % numbers.length;
// }

/* Classes */

public class ChordThread extends Thread {
  	private boolean running;	     // Is the thread running?  Yes or no?
	String noteSet;
	String outString;
   boolean fresh;		 // Is there fresh data to be polled?
  // int[] labjack_fields = new int[16];
  
  // Constructor, create the thread
  // It is not running by default
  public ChordThread() {
	running = false;
  }
  
  public void start()
  {
    // Set running equal to true
    running = true;
    fresh = false;
	outString = "";
    // Print messages
    // System.out.println("Starting data thread...");
	print("starting chord thread");
    // Do whatever start does in Thread, don't forget this!
    super.start();
  }
  

	public void updateChord(Set chordSet) {
		noteSet = "";
		Iterator chorditer = chordSet.iterator();
		while(chorditer.hasNext()) {
			Object n = chorditer.next();
			int nint =((Number)n).intValue();
			nint = (nint - 3)%12+1;
			noteSet +=" "+str(nint);
		}
		// print(noteSet);
	}
	
	public void run() {
		String line;
		OutputStream stdin = null;

		while (true) {
			stdin = null;
			try {
				print(noteSet+": ");

				Process p = Runtime.getRuntime().exec("python /Users/Tim/Documents/Processing/Guide/test.py"+noteSet);
				BufferedReader input = new BufferedReader(new InputStreamReader(p.getInputStream()));
				while ((line = input.readLine()) != null) {
					if(line.length()>0){
						outString = line;
						print(outString+"\n");
						fresh=true;						
					}
				}
				Thread.currentThread().sleep(10000); // Mysteriously Important Sleep 
			} catch (Exception err) {
				err.printStackTrace();
			}
		}
	}
  	// public int getLatest() {
  	//     	return outString;
  	//     }
}
