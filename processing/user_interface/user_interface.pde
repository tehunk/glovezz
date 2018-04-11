import oscP5.*;
import netP5.*;
  
OscP5 oscP5;
NetAddress myRemoteLocation;
boolean play1 = false;
boolean play2 = false;
int rectX, rectY;      // Position of square button
int circleX, circleY;  // Position of circle button
int rectSize = 90;     // Diameter of rect
int circleSize = 93;   // Diameter of circle
int init = 0;
color rectColor, circleColor, baseColor;
color rectHighlight, circleHighlight;
color currentColor;
boolean rectOver = false;
boolean circleOver = false;
int [][] events;
int gridw = 5, gridh = 6;
int numberOfNotes = 10;
int[] context_array;
NoteEvent[] noteSequence;
ArrayList<NoteEvent> active_notes1 = new ArrayList<NoteEvent>();
ArrayList<NoteEvent> active_notes2 = new ArrayList<NoteEvent>();
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

color[][] Colors = {  {thumb_soft, thumb_medium, thumb_hard},
                      {index_soft, index_medium, index_hard},
                      {middle_soft, middle_medium, middle_hard},
                      {ring_soft, ring_medium, ring_hard},
                      {pinki_soft, pinki_medium, pinki_hard}};
                      


public class NoteEvent{
      public int finger;
      public int pressure;
      public float duration;
      public float time;
      public int ticPassed;
      public boolean isActive;
      
      public NoteEvent(int finger, int pressure, float duration, float time) {
        this.finger = finger;
        this.pressure = pressure;
        this.duration = duration;
        this.time = time;
        this.isActive = false;
        this.ticPassed = 0;
      }

      public NoteEvent() {
        this.finger = 1;
        this.pressure = 0;
        this.duration = 1;
        //this.time = time;
      }
}



void setup() {
  rectColor = color(0);
  rectHighlight = color(51);
  circleColor = color(255);
  circleHighlight = color(204);
  baseColor = color(102);
  currentColor = baseColor;
  circleX = width/2+circleSize/2+10;
  circleY = height/2;
  rectX = width/2-rectSize-10;
  rectY = height/2-rectSize/2;
  ellipseMode(CENTER);
  size(320,240);
  frameRate(60);
  oscP5 = new OscP5(this,12345);
  myRemoteLocation = new NetAddress("127.0.0.1",1234);
  events = new int[gridw][gridh];
  context_array = new int[5];
  buildSong(10);
  strokeWeight(3);
  String[] fingers1 = loadStrings("song/fingers1.txt");
  String[] pressures1 = loadStrings("song/pressures1.txt");
  String[] time1 = loadStrings("song/tempos1.txt");
  String[] duration1 = loadStrings("song/durations1.txt");
  NoteEvent note1;  
  for (int i = 0 ; i < fingers1.length; i++) {
    note1 = new NoteEvent(Integer.parseInt(fingers1[i]), Integer.parseInt(pressures1[i]), float(duration1[i]), float(time1[i]));
    active_notes1.add(note1);}
  String[] fingers2 = loadStrings("song/fingers2.txt");
  String[] pressures2 = loadStrings("song/pressures2.txt");
  String[] time2 = loadStrings("song/tempos2.txt");
  String[] duration2 = loadStrings("song/durations2.txt");
  NoteEvent note2;  
  for (int j = 0 ; j < fingers2.length; j++) {
    note2 = new NoteEvent(Integer.parseInt(fingers2[j]), Integer.parseInt(pressures2[j]), float(duration2[j]), float(time2[j]));
    active_notes2.add(note2);
}
}

void buildSong(int numberOfNotes) {
  noteSequence = new NoteEvent[numberOfNotes];
  for(int note = 0; note < numberOfNotes; note++) {
    noteSequence[note] = new NoteEvent();
  }
}

void sendMsgInt(String addr, int v) {
  OscMessage myMessage = new OscMessage(addr);
  myMessage.add(v); 
  oscP5.send(myMessage, myRemoteLocation); 
}

int ih_old = -1;
int t = 0;

void draw() {  
  update(mouseX, mouseY);
  background(currentColor);
  
  if (rectOver) {
    fill(rectHighlight);
  } else {
    fill(rectColor);
  }
  stroke(255);
  rect(rectX, rectY, rectSize, rectSize);
  
  if (circleOver) {
    fill(circleHighlight);
  } else {
    fill(circleColor);
  }
  stroke(0);
  ellipse(circleX, circleY, circleSize, circleSize);
  
  if(play1){
    print(frameCount);
    print('\n');
    int counter = frameCount - init;
    print(counter);
    print('\n');   
    int dw = int(width/float(gridw));
    int dh = int(height/float(gridh));
    int ih = (counter%height) / dh;
    int reference_line = height-dh;
    boolean tic = ih_old != ih;
    ih_old = ih;
    stroke(255);
    for(int i=0;i<gridw;i++) {
      for(int j=0;j<gridh;j++) {
        fill(0);
        rect(i*dw,j*dh,dw,dh); 
      }
    }
    stroke(color(0, 250, 59));
    line(0,reference_line, width, reference_line); //reference line
    for (int i = 0; i < active_notes1.size(); i++) { 
      NoteEvent noteEv = active_notes1.get(i);
      int finger = noteEv.finger;
      int pressure = noteEv.pressure;
      float time = noteEv.time;
      float y_pos = counter - time * dh;
      //noteEv.isActive = true;
  
      if (noteEv.isActive) {
        fill(Colors[finger][pressure]);
        rect(finger*dw, y_pos-noteEv.duration % height, dw, dh*noteEv.duration);
      }
      if (tic) {
        noteEv.ticPassed++;
      }
      
      if (noteEv.ticPassed > gridh + noteEv.time) {
        noteEv.isActive = false;
        //active_notes.remove(i);
      }
      else {
        if(y_pos+noteEv.duration*dh>0){
                noteEv.isActive = true;        
        }
      }
      
      if (counter > dh*(active_notes1.size() + gridh + 4)){
        play1 = false;
      }
    }
    delay(30);}
    
    if(play2){
    print(frameCount);
    print('\n');
    int counter = frameCount - init;
    print(counter);
    print('\n');   
    int dw = int(width/float(gridw));
    int dh = int(height/float(gridh));
    int ih = (counter%height) / dh;
    int reference_line = height-dh;
    boolean tic = ih_old != ih;
    ih_old = ih;
    stroke(255);
    for(int i=0;i<gridw;i++) {
      for(int j=0;j<gridh;j++) {
        fill(0);
        rect(i*dw,j*dh,dw,dh); 
      }
    }
    stroke(color(0, 250, 59));
    line(0,reference_line, width, reference_line); //reference line
    for (int i = 0; i < active_notes2.size(); i++) { 
      NoteEvent noteEv = active_notes2.get(i);
      int finger = noteEv.finger;
      int pressure = noteEv.pressure;
      float time = noteEv.time;
      float y_pos = counter - time * dh;
      //noteEv.isActive = true;
  
      if (noteEv.isActive) {
        fill(Colors[finger][pressure]);
        rect(finger*dw, y_pos-noteEv.duration % height, dw, dh*noteEv.duration);
      }
      if (tic) {
        noteEv.ticPassed++;
      }
      
      if (noteEv.ticPassed > gridh + noteEv.time) {
        noteEv.isActive = false;
        //active_notes.remove(i);
      }
      else {
        if(y_pos+noteEv.duration*dh>0){
                noteEv.isActive = true;        
        }
      }
      
      if (counter > dh*(active_notes2.size() + gridh + 4)){
        play2 = false;
      }
    }
    delay(30);}
}

void update(int x, int y) {
  if (overCircle(circleX, circleY, circleSize) ) {
    circleOver = true;
    rectOver = false;
  } else if (overRect(rectX, rectY, rectSize, rectSize) ) {
    rectOver = true;
    circleOver = false;
  } else {
    circleOver = rectOver = false;
  }
}

void mousePressed() {
  if (circleOver) {
    currentColor = circleColor;
    init = frameCount;
    play1=true;
  }
  if (rectOver) {
    currentColor = rectColor;
    init = frameCount;
    play2=true;
  }
}

boolean overRect(int x, int y, int width, int height)  {
  if (mouseX >= x && mouseX <= x+width && 
      mouseY >= y && mouseY <= y+height) {
    return true;
  } else {
    return false;
  }
}

boolean overCircle(int x, int y, int diameter) {
  float disX = x - mouseX;
  float disY = y - mouseY;
  if (sqrt(sq(disX) + sq(disY)) < diameter/2 ) {
    return true;
  } else {
    return false;
  }
}