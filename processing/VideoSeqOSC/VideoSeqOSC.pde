import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress myRemoteLocation;
int gridw = 5, gridh = 6;
int numberOfNotes = 10;
int[] context_array;
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
      
      public NoteEvent(int finger, int pressure, float duration, int counter, float time) {
        this.finger = finger;
        this.pressure = pressure;
        this.duration = duration;
        this.counter = counter;
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

void sendMsgInt(String addr, int v) {
  OscMessage myMessage = new OscMessage(addr);
  myMessage.add(v); 
  oscP5.send(myMessage, myRemoteLocation); 
}

int ih_old = -1;
int t = 0;

void draw() {
  int dw = int(width/float(gridw));
  int dh = int(height/float(gridh));
  int ih = (frameCount % height) / dh;
  int reference_line = height-dh;
  //float threshold = 0;
  float threshold = float(dh) / 2;
  boolean tic = ih_old != ih;
  NoteEvent note;
  
  if(tic) {
    
    // For each finger randomly create or not a NoteEvent
    /*
    THIS WILL BE REPLACED BY FRANCESC'S CODE
    */
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
  }
  
  /*
  
  **************************************************  
  * PSEUDO-CODE FOR CALCULATING ERRORS/PERFORMANCE 
  **************************************************
  * This pseudo-code takes care of receiving the array from the
  * Arduino and checking if a note was hit, eventually sending a feedback
  * to the motor sensors.
  **************************************************
  
  encoded_array = receiveArrayFromSensors()
  
  for each finger in encoded_array:
    if hotNotes[finger] != null:
      note = hotNotes[finger]
      note.hitMe = false
      note.alreadyHit = true
      remove note from hotNotes
      print HIT
      
      error = calculateError(note.pressure, note.position, finger.pressure)
      
      // calculateError confronts the note pressure with the finger pressure,
      // and the note position (which can be y_pos for example) with the position
      // of the green line and returns some error measure. For example:
      //    error.errorPressure = correct note but with wrong pressure
      //    error.errorTime = correct note but too early or too late
      //                      (before or after the green line)
      
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
        fill(thumb_hard);
      }
      
      // draw the note
      rect(finger*dw, y_pos % height, dw, dh * noteEv.duration);
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
                                    
        sendSensorFeedback(finger, "missed")
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
    if (noteEv.ticPassed > gridh) {
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