// struct obj to store matched notes from note_on note_off events

class MidiNote { 
	
	public final int pitch;
	public final int velocity;
	public final float onTick;
	public float offTick;
	public final int channel;
	
	MidiNote(int pit, int vel, float onT, int chan) {
		pitch = pit;
		velocity = vel;
		onTick = onT;
		channel = chan;
	}
}
