import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress myRemoteLocation;
int gridw = 5, gridh = 6;
int numberOfNotes = 10;
int[] context_array;
int missedNotes = 0;
float MAX_PRINT_TIMEOUT = 5;
float printHitTimeOut = 0;
float printMissTimeOut = 0;
NoteEvent[] noteSequence;
// hotNotes is an array of five NoteEvents, one for each finger.
// A hotNote is a NoteEvent currently in the hitMe status,
// i.e. that has to be hit (the NoteEvent is in the last row of the grid).
NoteEvent[] hotNotes;
ArrayList<NoteEvent> active_notes = new ArrayList<NoteEvent>();

PFont f;

//thumb: red
color thumb_soft = #FF6666;
color thumb_medium = #FF0000;
color thumb_hard = #990000;
//index: green
color index_soft = #99FF99;
color index_medium = #33FF33;
color index_hard = #009900;
//middle: yellow
color middle_soft = #FFFF99;
color middle_medium = #FFFF33;
color middle_hard = #CCCC00;
//ring: blue
color ring_soft = #99CCFF;
color ring_medium = #3333FF;
color ring_hard = #000099;
//pinky: orange
color pinki_soft = #FFCC99;
color pinki_medium = #FF8000;
color pinki_hard = #CC6600;

color[][] Colors = {
  {thumb_soft, thumb_medium, thumb_hard},
  {index_soft, index_medium, index_hard},
  {middle_soft, middle_medium, middle_hard},
  {ring_soft, ring_medium, ring_hard},
  {pinki_soft, pinki_medium, pinki_hard}
};

int ih_old = -1;
int t = 0;

public class NoteEvent{
      public int finger;
      public int pressure;
      public float duration;
      public int counter;
      public float time;
      public int ticPassed;
      public boolean isActive;     // the NoteEvent is active (visible on the screen)
      public boolean hitMe;        // the NoteEvent is in the "hot zone" (you have to hit it!)
      public boolean alreadyHit;   // the NoteEvent is in the hot zone and has been hit already
      public boolean missed;       // the NoteEvent has passed the hot zone and has been missed
      
      public NoteEvent(int finger, 
                        int pressure,
                        float duration,
                        //int counter,
                        float time) {
        this.finger = finger;
        this.pressure = pressure;
        this.duration = duration;
        //this.counter = counter;
        this.time = time;
        this.isActive = true;
        this.ticPassed = 0;
        this.hitMe = false;
        this.alreadyHit = false;
        this.missed = false;
      }

      public NoteEvent() {
        this.finger = 1;
        this.pressure = 0;
        this.duration = 1;
      }
}

//send OSC message
void sendMsgInt(String addr, int v) {
  OscMessage myMessage = new OscMessage(addr);
  myMessage.add(v); 
  oscP5.send(myMessage, myRemoteLocation); 
}

void mousePressed() {
  int finger = int(mouseX/float(width) * gridw);
  int row = int(mouseY/float(height) * gridh);
  // if mouse pressed on the last row of rectangles
  if (row == 5) {
    // check if the square clicked has a hot note inside
    if(hasHotNote(finger)) {
      NoteEvent note = getHotNote(finger);
      // note has been hit
      note.alreadyHit = true;
      // you can't hit the same hot note twice
      note.hitMe = false;
      // remove the note from the array of hot notes
      delHotNote(finger);
      // print "HIT"
      printHitTimeOut = MAX_PRINT_TIMEOUT;
      //play note
      sendMsgInt("/play",finger);
    }
  }
}

boolean hasHotNote(int x) {
  return (hotNotes[x] != null);
}

NoteEvent getHotNote(int x) {
  return hotNotes[x];
}

void delHotNote(int x) {
  hotNotes[x] = null;
}

void setup() {
  println("Loading...");
  size(320,240);
  frameRate(60);
  oscP5 = new OscP5(this,12345);
  myRemoteLocation = new NetAddress("127.0.0.1",1234);
  String portName = Serial.list()[0]; //ttyACM0 on Linux
  myPort = new Serial(this, portName, 9600);
  fromArduino = new ReadFromArduino(myPort);
  context_array = new int[5];
  strokeWeight(3);
  String[] fingers = loadStrings("song/fingers.txt");
  String[] pressures = loadStrings("song/pressures.txt");
  String[] time = loadStrings("song/tempos.txt");
  String[] duration = loadStrings("song/durations.txt");
  NoteEvent note;
  for (int i = 0 ; i < fingers.length; i++) {
    note = new NoteEvent(Integer.parseInt(fingers[i]), Integer.parseInt(pressures[i]), float(duration[i]), float(time[i]));
    active_notes.add(note);
  }
  hotNotes = new NoteEvent[5];
  // in the beginning there are no hot notes
  for (int i = 0; i < 5; i++) {
    hotNotes[i] = null;
  }
  f = createFont("Arial", 20, true);
  println("Done.");
}

/*
void setup() {
  println("Loading...");
  size(320, 240);
  frameRate(30);
  oscP5 = new OscP5(this,12345);
  myRemoteLocation = new NetAddress("127.0.0.1", 1234);
  context_array = new int[5];
  strokeWeight(3);
  hotNotes = new NoteEvent[5];
  // in the beginning there are no hot notes
  for (int i = 0; i < 5; i++) {
    hotNotes[i] = null;
  }
  f = createFont("Arial", 20, true);
  println("Loaded");
}
*/

void draw() {
  int dw = int(width/float(gridw));
  int dh = int(height/float(gridh));
  int ih = (frameCount % height) / dh;
  int reference_line = height-dh;
  int[] encodedBuffer = new int[5];
  //float threshold = 0;
  float threshold = float(dh) / 2;
  boolean tic = ih_old != ih;
  //NoteEvent note;
  
  fromArduino.read();
  encodedBuffer = fromArduino.getEncodedBuffer();

  for (int finger = 0; finger < 5; finger++) {
    if (encodedBuffer[finger] > 10) {
      if(hasHotNote(finger)) {
        NoteEvent note = getHotNote(finger);
        // note has been hit
        note.alreadyHit = true;
        // you can't hit the same hot note twice
        note.hitMe = false;
        // remove the note from the array of hot notes
        delHotNote(finger);
        // print "HIT"
        printHitTimeOut = MAX_PRINT_TIMEOUT;
        //play note
        sendMsgInt("/play",finger);
      }
    }
  }

  //code only to create notes
  //if(tic) {
    
    // For each finger randomly create or not a NoteEvent
    /*
    THIS WILL BE REPLACED BY FRANCESC'S CODE
    
    for (int i=0; i < 5; i++) {
      
      context_array[i] = int(random(0,1.9));
      if(context_array[i] == 1) {
        //float start_delay = random(0,0.9);
        float start_delay = 0;
        note = new NoteEvent(i, 1, 1, 1, ih+start_delay);
        active_notes.add(note);
        break;   // Only create one note for each tic
                 // (comment previous line to create more than one note)
      }
    }
    */
  //}
  
  /*
  
  **************************************************  
  * PSEUDO-CODE FOR CALCULATING ERRORS/PERFORMANCE 
  **************************************************
  * This pseudo-code takes care of receiving the array from the
  * Arduino and checking if a note was hit, eventually sending a feedback
  * to the motor sensors.
  **************************************************
  
  //This reads the encoded array that we receive from Arduino at each cycle
  encoded_array = receiveArrayFromSensors()
  //I think we need to trigger the event when the array from sensors is not all 0 (at least a finger is pressed)
  //this is to simulate the mousepressed event
  
  boolean checkEvent(int[] encoded){
    zeros = [0, 0, 0, 0, 0]
    if (encoded != zeros){
      return true
    }
    else{
      return false
    }
  }
  
  if(checkEvent(encoded_array)){ 
    //do something as mousepressed
    for each finger in encoded_array:
      if(hotNotes[finger] != null){
        note = hotNotes[finger]
        note.hitMe = false;
        note.alreadyHit = true;
        hotNotes[finger] = null;
        print HIT
        
        //i would pass the whole note and make two different controls  
        error = calculateError(note, finger.pressure)
        //hopefully we will receive values from 1 to 3 for the pressure (1 = soft, 2 = medium, 3 = hard)
        void calculateError(NoteEvent note, int fingerPressure){
        if ()
        }    
        // calculateError confronts the note pressure with the finger pressure,
        // and the note position (which can be y_pos for example) with the position
        // of the green line and returns some error measure. For example:
        //    error.errorPressure = correct note but with wrong pressure
        //    error.errorTime = correct note but too early or too late
        //                      (before or after the green line)
      
      else
      //pressed the wrong finger
      
      //sendSensorFeedback should send two types of error, one for the position/missed error and one for the wrong pressure
      sendSensorFeedback(finger, error)
    end if
  end for
  
  */
  
  ih_old = ih;
  stroke(255);
  // draw grid
  for (int i = 0; i < gridw; i++) {
    for (int j = 0; j < gridh; j++) {
      fill(0);
      rect(i*dw, j*dh, dw, dh); 
    }
  }
  
  // draw reference green line
  stroke(color(0, 250, 59));
  line(0, reference_line, width, reference_line);

  // For each active note
  for (NoteEvent noteEv : active_notes) {
    
    int finger = noteEv.finger;
    int pressure = noteEv.pressure;
    float time = noteEv.time;
    float y_pos = frameCount - time * dh;
    
    // if the note is on the screen
    if (noteEv.isActive) {

      if ((y_pos % height) + dh >= reference_line + threshold    // if the note has passed the "hit note" start line
          && !noteEv.hitMe                                       // and it can't be hit yet
          && !noteEv.alreadyHit                                  // and hasn't been hit yet
          && !noteEv.missed)                                     // and hasn't been missed
      {
        noteEv.hitMe = true;                                     // you can hit it
        hotNotes[finger] = noteEv;                               // add the note to the hotNote array
      }
      
      // the following "if... else if... else"
      // selects the color for the note based on its status
      if (noteEv.alreadyHit) {
        fill(0, 0, 0, 0);
      }
      else if (noteEv.hitMe) {
        fill(index_hard);
      }
      else {
        fill(Colors[finger][pressure]);
      }
      
      // draw the note
      rect(finger*dw, y_pos-noteEv.duration % height, dw, dh * noteEv.duration);
    }

    // increase tics of the note
    if (tic) {
      noteEv.ticPassed++;
    }
    
    if (y_pos % height > height - threshold) {                  // if the note has passed the "hit note" finish line

      if (noteEv.isActive &&      // if the note is active
          !noteEv.alreadyHit &&   // and it hasn't been hit already
          noteEv.hitMe)           // and you could still hit it
      {
        noteEv.hitMe = false;     // you can't hit it anymore
        noteEv.missed = true;     // you missed it
        printMissTimeOut = MAX_PRINT_TIMEOUT;    // print "MISS"
        missedNotes++;
        println((active_notes.size() - float(missedNotes)) / active_notes.size());
        /*
        
        **************************************************  
        * PSEUDO-CODE FOR CALCULATING ERRORS/PERFORMANCE *
        **************************************************
        * This pseudo code takes care of sending a feedback to the motors
        * if a note was missed.
        * 
        * N.B.: here we are already inside the condition when the note was missed!
        **************************************************
        
        error = calculateError()    // if you want, I don't know what error you want to calculate
                                    // when you miss a note
        
                                    //we can count how many missed notes in all the session and count how many notes we create and make a ratio
                                    
        sendSensorFeedback(finger, "missed")
        //with send_to_Arduino script we will be able to do it
        // The variable finger is already defined!
        
        */
      }
      
      // if the hot note in the hotNotes array for that finger
      // is the same as the note we're evaluating
      if (hotNotes[finger] == noteEv) {
        hotNotes[finger] = null;      // remove it from the hotNotes array
      }
      
    }

    // if the note tics are more than the number of rows in the grid
    // (the note is out of the screen)
    if (noteEv.ticPassed > gridh + noteEv.time) {
      noteEv.isActive = false;    // the note is not active anymore
    }
    
  }
  
  // print MISS with fadeout effect and decreasing font size
  if (printMissTimeOut > 0) {
    float factor = printMissTimeOut / MAX_PRINT_TIMEOUT;
    textFont(f, 60 * factor);
    fill(255, 0, 0, 255 * factor);
    textAlign(CENTER);
    text("MISS :(", width/2, height/2);
    printMissTimeOut -= .10;
  }
  
  // print HIT with fadeout effect and decreasing font size
  if (printHitTimeOut > 0) {
    float factor = printHitTimeOut / MAX_PRINT_TIMEOUT;
    textFont(f, 60 * factor);
    fill(0, 255, 0, 255 * factor);
    textAlign(CENTER);
    text("HIT :)", width/2, height/2);
    printHitTimeOut -= .10;
  }
  
  delay(20);

}