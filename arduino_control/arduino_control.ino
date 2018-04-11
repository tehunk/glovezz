/*
 * Arduino Sensor/Motor Communication
 * 
 * Author: Tae Hun Kim
 * Last Updated: 12 APR 2018
 * 
 * Analog pins are mapped to 5 pressure and 1 flex sensors.
 * Digital PWM pins are connected to vibration motors
 */

#include "ReadFromProcessing.h"

// Digital Pins
const byte PWM_PINS[] = {3, 5, 6, 9, 10};
ReadFromProcessing processing;
int motorVal[5];
int i;

void setup() {
  Serial.begin(9600);
  for (int i=0; i<5; i++){
    pinMode(PWM_PINS[i], OUTPUT);
  }
}

void loop() {
/*
 * 1. Receive values from pressure sensors and write byte codes to serial
 * 2. Receive motor values from serial
 * 3. Control motors with received values
 */
  sendSensorVals();
  if(Serial)
    processing.readFromSerial();
  if (processing.isReady())
  {
    processing.getMotorVal(motorVal);
    //Serial.print(motorVal[0]);
    //i = motorVal[0]*2;
    controlMotors();
  }  
}

void controlMotors()
/*
 * Write to the motors connected to pwm pins
 * For now, it will write values directly from processing
 * Later, there is chance to represent different type of miss
 */
{
  for(int i=0; i<5; i++) {
    analogWrite(PWM_PINS[i], motorVal[i]);
  }
}

void sendSensorVals() {
/*
 * Serial communication sends an array of 12 bytes
 * Each sensor takes up 2 bytes
 * 0-4th pin: thumb-pinky pressure
 *   5th pin: flex
 */
  byte boundary[] = {255, 255};
  byte vals[12];
  for (byte i=0; i<6; i++) {
    word raw = analogRead(i);
    if (i==5) // For now, only the 5th sensor (flex) is not supported
      raw = 0;
    vals[i*2] = highByte(raw);
    vals[i*2+1] = lowByte(raw);
//    Serial.print(i);
//    Serial.print(": ");
//    Serial.print(raw);
//    Serial.print("\t")
  }
//  Serial.print("\n");

// Boundary is necessary to deliminate sensor values
// Since no sensor value can reach "11111111" in binary,
// this number is used to show the boundary
  Serial.write(boundary, 2);
  Serial.write(vals, sizeof(vals));

  delay(50);
}
