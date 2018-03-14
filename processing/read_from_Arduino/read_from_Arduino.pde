import processing.serial.*;
Serial myPort;  // Create object from Serial class
byte B_BUFFER2[] = {0, 0};
ReadFromArduino fromArduino;

void setup()
{
  //printArray(Serial.list());
  String portName = Serial.list()[0]; //ttyACM0 on Linux
  myPort = new Serial(this, portName, 9600);
  fromArduino = new ReadFromArduino(myPort);
}

void draw()
{
  fromArduino.read();
  fromArduino.getEncodedBuffer();
  //printArray(fromArduino.getEncodedBuffer());
  delay(50);

}

class ReadFromArduino {
  Serial port;
  byte bufferSize14[];
  int encodedBuffer[];
  
  // Constructor
  ReadFromArduino (Serial p) {
    port = p;
    bufferSize14 = new byte[14];
    encodedBuffer = new int[6];
  }
  
  // Return encoded buffer;
  int[] getEncodedBuffer() {
    encodeBuffer(bufferSize14);
    return encodedBuffer;
  } 
  // Encode Buffer
  void encodeBuffer(byte[] buffer){
    if (buffer.length != 14){
      println("Error in encodeBuffer(): the size of buffer is not 14");
      return;
    } else {
      int[] dest = new int[12];
      int bigEndMask = unbinary("00000000000000001111111100000000");
      int littleEndMask = unbinary("00000000000000000000000011111111");
      arrayCopy(buffer, dest, 12);
      for (int i=0; i<6; i++) {
        println("i is: ", str(i));
        int offset = i*0;
        encodedBuffer[i] = 0;
        print(encodedBuffer[i]+ " ");
        encodedBuffer[i] += (dest[offset] & bigEndMask);
        print(encodedBuffer[i]+ " ");
        encodedBuffer[i] += (dest[offset+1] & littleEndMask);
        println(encodedBuffer[i]+ " ");
        //println("Big End Mask: ", str(bigEndMask));
        //println("Little End Mask: ", str(littleEndMask));
        //println(str(i) + " in encoded Buffer is: ", str(encodedBuffer[i]));
      }
    }
  }
  
  // return the raw byte buffer
  byte[] getBuffer() {
    return bufferSize14;
  }
  // start reading buffer
  void read() {
    if (myPort.available() > 14)
    {
      myPort.readBytes(bufferSize14);
      printArray(bufferSize14);
      isBoundaryFound(bufferSize14[12]);
      if(!isBoundaryFound(bufferSize14[13])) {  
        syncToBoundary();
      }
    }
  }
  // Syncronize to the boundary. It's called by read() function.
  void syncToBoundary() {
    for (int i=0; i<14; i++) {
      if(isBoundaryFound(bufferSize14[i])) {
        int b_size = (i+1)%14;
        if (myPort.available() > b_size) {
          byte temp[] = new byte[b_size];
          myPort.readBytes(temp);
        }
      }
    }
  }
  // Check if the last element in the buffer is a boundary
  // Must be called twice with consecutive bytes.
  boolean isBoundaryFound(byte b)
  {
    final byte BOUNDARY = -1; //11111111
    B_BUFFER2[1] = B_BUFFER2[0];
    B_BUFFER2[0] = b;
    if ((B_BUFFER2[0] == BOUNDARY) && (B_BUFFER2[1] == BOUNDARY)) {
      B_BUFFER2[0] = B_BUFFER2[1] = 0;
      return true;
    } else
      return false;
  }
}