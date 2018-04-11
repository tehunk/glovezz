import processing.serial.*;
Serial myPort;  // Create object from Serial class
byte[] motorVals = new byte[5]; 
byte strength = 0;
//SendToArduino toArduino;

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

void sendToArduino(Serial myPort, byte[] motorVals) {
    byte[] sendBuffer = new byte[6];
    arrayCopy(motorVals, sendBuffer, 5);
    sendBuffer[5] = -1; //'11111111'
    printArray(sendBuffer);
    myPort.write(sendBuffer);
}