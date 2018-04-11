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
boolean printMiss = false;
NoteEvent[] noteSequence;
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
      public boolean isActive;
      public boolean hitMe;
      public boolean alreadyHit;
      public boolean missed;
      
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
  size(320,240);
  frameRate(30);
  //oscP5 = new OscP5(this,12345);
  //myRemoteLocation = new NetAddress("127.0.0.1", 1234);
  context_array = new int[5];
  //buildSong(10);
  strokeWeight(3);
  hotNotes = new NoteEvent[5];
  for (int i = 0; i < 5; i++) {
    hotNotes[i] = null;
  }
  f = createFont("Arial", 20, true);
  println("Loaded");
}

/*
void buildSong(int numberOfNotes) {
  noteSequence = new NoteEvent[numberOfNotes];
  for(int note = 0; note < numberOfNotes; note++) {
    noteSequence[note] = new NoteEvent();
  }
}
*/

void sendMsgInt(String addr, int v) {
  OscMessage myMessage = new OscMessage(addr);
  myMessage.add(v); 
  oscP5.send(myMessage, myRemoteLocation); 
}

int ih_old = -1;
int t = 0;

void draw() {
  //int y = 0;
  int dw = int(width/float(gridw));
  int dh = int(height/float(gridh));
  int ih = (frameCount % height) / dh;
  int reference_line = height-dh;
  //float threshold = 0;
  float threshold = float(dh) / 2;
  boolean tic = ih_old != ih;
  NoteEvent note;
  
  if(tic) {

    fill(thumb_hard);
    for (int i=0; i < 5; i++) {
      context_array[i] = int(random(0,1.9));
      if(context_array[i] == 1) {
        //float start_delay = random(0,0.9);
        float start_delay = 0;
        note = new NoteEvent(i, 1, 1, 1, ih+start_delay);
        active_notes.add(note);
        break;
      }
    }
  }
  
  ih_old = ih;
  stroke(255);
  for(int i=0;i<gridw;i++) {
    for(int j=0;j<gridh;j++) {
      fill(0);
      rect(i*dw,j*dh,dw,dh); 
    }
  }
  stroke(color(0, 250, 59));
  line(0, reference_line, width, reference_line); //reference green line

  for (NoteEvent noteEv : active_notes) {
    
    int finger = noteEv.finger;
    float time = noteEv.time;
    float y_pos = frameCount - time * dh;
    
    if (noteEv.isActive) {

      if ((y_pos % height) + dh >= reference_line + threshold
          && noteEv.isActive
          && !noteEv.alreadyHit
          && !noteEv.missed)
      {
        noteEv.hitMe = true;
        hotNotes[finger] = noteEv;
      }
      
      if (noteEv.alreadyHit) {
        fill(0, 0, 0, 0);
      }
      else if (noteEv.hitMe) {
        fill(index_hard);
      }
      else {
        fill(thumb_hard);
      }
      
      rect(finger*dw, y_pos % height, dw, dh * noteEv.duration);
    }

    if (tic) {
      noteEv.ticPassed++;
    }
    
    if (y_pos % height > height - threshold) {
      
      if (noteEv.isActive &&
          noteEv.hitMe &&
          !noteEv.alreadyHit) 
      {
        noteEv.hitMe = false;
        noteEv.missed = true;
        printMissTimeOut = MAX_PRINT_TIMEOUT;
      }
      
      if (hotNotes[finger] == noteEv) {
        hotNotes[finger] = null;
      }
      
    }

    if (noteEv.ticPassed > gridh) {
      noteEv.isActive = false;
    }
    
  }
  
  if (printMissTimeOut > 0) {
    float factor = printMissTimeOut / MAX_PRINT_TIMEOUT;
    textFont(f, 60 * factor);
    fill(255, 0, 0, 255 * factor);
    textAlign(CENTER);
    text("MISS :(", width/2, height/2);
    printMissTimeOut -= .10;
  }
  
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
  int gi = int(mouseX/float(width) * gridw);
  int gj = int(mouseY/float(height) * gridh);
  // if mouse pressed on the last row of rectangles
  if (gj == 5) {
    if(hasHotNote(gi)) {
      NoteEvent note = getHotNote(gi);
      note.alreadyHit = true;
      note.hitMe = false;
      delHotNote(gi);
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