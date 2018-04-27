//import processing.serial.*;
//Serial myPort;  // Create object from Serial class
//byte[] motorVals = new byte[5]; 
//byte strength = 0;
//SendToArduino toArduino;

import processing.serial.*;
Serial myPort;  // Create object from Serial class
boolean[] motorVals = {false, false, false, false, false};
boolean[] pressed = {false, false, false, false, false};
int index = -1;
static char BOUNDARY = 'e'; //byte(unbinary("11111111"));

void setup()
{
  printArray(Serial.list());
  String portName = Serial.list()[0]; //ttyACM0 on Linux
  myPort = new Serial(this, portName, 9600);
  //toArduino = new SendToArduino(myPort);
}

void draw()
{
    for (int i=0; i<5; i++){
        motorVals[i] = byte(random(10, 120));
    }
    sendToArduino(myPort, motorVals);
    delay(10);
}

//void sendToArduino(Serial myPort, byte[] motorVals) {
//    byte[] sendBuffer = new byte[6];
//    arrayCopy(motorVals, sendBuffer, 5);
//    sendBuffer[5] = -1; //'11111111'
//    printArray(sendBuffer);
//    myPort.write(sendBuffer);
//}

void sendToArduino(Serial myPort, boolean[] motorVals) {
  char[] sendBuffer = new char[5];
  for (int i=0; i<5; i++) {
    sendBuffer[i] = motorVals[i] ? '1' : '0'; 
    myPort.write(sendBuffer[i]);
  }
  myPort.write(BOUNDARY);
  printArray(sendBuffer);
}