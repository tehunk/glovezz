/*
 * ReadFromProcessing.cpp - Read 5 values for vibrations from Processing through Serial
 * Created by Tae Hun Kim 
 */

#include "Arduino.h"
#include "ReadFromProcessing.h"

ReadFromProcessing::ReadFromProcessing()
{
    ready = false;
}

bool ReadFromProcessing::isReady() {
    return ready;
}

void ReadFromProcessing::readFromSerial()
{
    if(Serial.available() > 6)
    {
        Serial.readBytes(vals, 6);
        ready = true;
    }
}

bool ReadFromProcessing::syncBoundary()
{
    int i=0;
    byte tempBuffer[] = {0};
    if(ready)
    {
        while (tempBuffer[0]!=255 || vals[5]!=255)
        {
            if (Serial.available() > 0)
                Serial.readBytes(tempBuffer, 1);
        }
        return true;
    }
    else
        return false;
}

int ReadFromProcessing::getMotorVal(int* buffer)
{
    bool synced = syncBoundary();
    if(ready && synced)
    {
        memcpy(buffer, vals, 5);
        ready = false;
        return 5;
    }
    else
        return 0;

}