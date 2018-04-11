import processing.serial.*;
Serial myPort;  // Create object from Serial class
byte[] sendBuffer = new byte[6]; 
byte strength = 0;
//SendToArduino toArduino;

void setup()
{
  printArray(Serial.list());
  String portName = Serial.list()[0]; //ttyACM0 on Linux
  myPort = new Serial(this, portName, 9600);
  sendBuffer[5] = -1;
  //toArduino = new SendToArduino(myPort);
}

void draw()
{
    for (int i=1; i<5; i++){
        sendBuffer[i] = byte(random(10, 120));
    }
    strength = byte((strength+1)%120);
    sendBuffer[0] = strength;
    println(sendBuffer[0]*2);
    myPort.write(sendBuffer);
    delay(10);
}