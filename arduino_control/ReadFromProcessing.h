/*
 * ReadFromProcessing.h - Read 5 values for vibrations from Processing through Serial
 * Created by Tae Hun Kim 
 */

#ifndef ReadFromProcessing_h
#define ReadFromProcessing_h

#include "Arduino.h"

class ReadFromProcessing
{
  private:
    const byte boundary = 127;
    byte vals[6];
    bool syncBoundary();
    bool ready;
    
  public:
    ReadFromProcessing();
    void readFromSerial();
    int getMotorVal(int*);
    bool isReady();
};

#endif