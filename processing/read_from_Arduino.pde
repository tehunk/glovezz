import processing.serial.*;
Serial myPort;  // Create object from Serial class
byte B_BUFFER2[] = {0, 0};

void setup()
{
  printArray(Serial.list());
  String portName = Serial.list()[0]; //ttyACM0 on Linux
  myPort = new Serial(this, portName, 9600);
}

void draw()
{
  byte bufferSize14[] = new byte[14];
  if (myPort.available() > 14)
  {
    myPort.readBytes(bufferSize14);
    printArray(bufferSize14);
    for (int i=0; i<14; i++)
    {
      if(isBoundaryFound(bufferSize14[i]))
      {
        B_BUFFER2[0] = B_BUFFER2[1] = 0;
        int b_size = (i+1)%14;
        if (myPort.available() > b_size)
        {
          byte temp[] = new byte[b_size];
          myPort.readBytes(temp);
        }
      }
    }
  }

  delay(50);

}

boolean isBoundaryFound(byte b)
{
  final byte BOUNDARY = -1; //11111111
  B_BUFFER2[1] = B_BUFFER2[0];
  B_BUFFER2[0] = b;
  if ((B_BUFFER2[0] == BOUNDARY) && (B_BUFFER2[1] == BOUNDARY))
    return true;
  else
    return false;
}

class ReadFromArduino {
  int port;
  //Constructor
  ReadFromArduino (int p) {
    port = p;
  }
}