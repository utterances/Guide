// simply reads a midi file, output a linkedlist with MidiNote structs

import promidi.*;
import java.io.*;
import javax.sound.midi.MidiSystem;
import javax.sound.midi.InvalidMidiDataException;
import javax.sound.midi.Sequence;
import javax.sound.midi.Track;
import javax.sound.midi.MidiEvent;
import javax.sound.midi.MidiMessage;
import javax.sound.midi.ShortMessage;
import javax.sound.midi.MetaMessage;
import javax.sound.midi.SysexMessage;
import javax.sound.midi.Receiver;

// help from http://www.jsresources.org/examples/DumpSequence.java.html
// http://download.oracle.com/javase/tutorial/sound/MIDI-messages.html
// http://stackoverflow.com/questions/3850688/reading-midi-files-in-java

// public static final String[] NOTE_NAMES = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"};

LinkedList<MidiNote> MIDIReader(String filepath) {
	Sequence seq = null;
	// String file = "/Users/Tim/Documents/Processing/MIDIReader/Clocks - carillon.mid";
	File midif = new File(filepath);
	try	{
		seq = MidiSystem.getSequence(midif);
	} catch (InvalidMidiDataException e) {
		e.printStackTrace();
		System.exit(1);
	} catch (IOException e) {
		e.printStackTrace();
		System.exit(1);
	}
	LinkedList<MidiNote> allNotes = new LinkedList<MidiNote>();

	if (seq == null){
		print("Cannot retrieve Sequence.\n");
	}
	else{
		print("Length: " + seq.getTickLength() + " ticks\n");
		print("Duration: " + seq.getMicrosecondLength() + " microseconds\n");
		float	fDivisionType = seq.getDivisionType();
		String	strDivisionType = null;
		if (fDivisionType == Sequence.PPQ)
		{
			strDivisionType = "PPQ";
		}
		else if (fDivisionType == Sequence.SMPTE_24)
		{
			strDivisionType = "SMPTE, 24 frames per second";
		}
		else if (fDivisionType == Sequence.SMPTE_25)
		{
			strDivisionType = "SMPTE, 25 frames per second";
		}
		else if (fDivisionType == Sequence.SMPTE_30DROP)
		{
			strDivisionType = "SMPTE, 29.97 frames per second";
		}
		else if (fDivisionType == Sequence.SMPTE_30)
		{
			strDivisionType = "SMPTE, 30 frames per second";
		}

		print("DivisionType: " + strDivisionType);

		String	strResolutionType = null;
		if (seq.getDivisionType() == Sequence.PPQ)
		{
			strResolutionType = " ticks per beat";
		}
		else
		{
			strResolutionType = " ticks per frame";
		}
		print("Resolution: " + seq.getResolution() + strResolutionType+"\n");
		
		Track[]	tracks = seq.getTracks();
		LinkedList<MidiNote> tmpNotes = new LinkedList<MidiNote>();
		for (int nTrack = 0; nTrack < tracks.length; nTrack++) {
			print("Track " + nTrack + ":\n");
			print("-----------------------");
			Track track = tracks[nTrack];
			for (int nEvent = 0; nEvent < track.size(); nEvent++)
			{
				MidiEvent event = track.get(nEvent);
				// print(event);
				MidiMessage message = event.getMessage();
				// print("@" + event.getTick() + " ");
				if (message instanceof ShortMessage) {
                    ShortMessage sm = (ShortMessage) message;
                    // print("Channel: " + sm.getChannel() + " ");
                    if (sm.getCommand() == ShortMessage.NOTE_ON) {
                        int key = sm.getData1();
                        int octave = (key / 12)-1;
                        int note = key % 12;
                        // String noteName = NOTE_NAMES[note];
                        int velocity = sm.getData2();
                        // print("Note on, " + noteName + octave + " key=" + key + " velocity: " + velocity+"\n");

						//save tmp notes
						MidiNote m=new MidiNote(key,
									velocity,
									(float)event.getTick()/seq.getResolution(),
									sm.getChannel());
						tmpNotes.add(m);
                    } else if (sm.getCommand() == ShortMessage.NOTE_OFF) {
                        int key = sm.getData1();
                        int octave = (key / 12)-1;
                        int note = key % 12;
                        // String noteName = NOTE_NAMES[note];
                        int velocity = sm.getData2();
                        // print("Note off, " + noteName + octave + " key=" + key + " velocity: " + velocity+"\n");

						//complete notes, if possible, otherwise discard
						//check existing NOTE_ON events:
						MidiNote rem = null;
						for (MidiNote m : tmpNotes) {
							if (m.pitch == key && m.channel == sm.getChannel()){
								rem = m;
								m.offTick = (float)event.getTick()
												/seq.getResolution();
								allNotes.add(m);
								break;
							}
						}
						tmpNotes.remove(rem);
                    } else {
                        // print("Command:" + sm.getCommand());
					}
				} else {
					// print("Other message: " + message.getClass());
				}
			}
		}
	}
	for (MidiNote m : allNotes) {
		print(m.onTick+" "+m.offTick+" "+m.pitch+" "+m.velocity+"\n");
	}
	return allNotes;
}

