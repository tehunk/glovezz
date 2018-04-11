/*
 * Arduino Sensor/Motor Communication
 * 
 * Author: Tae Hun Kim
 * Last Updated: 21 Feb 2018
 * 
 * Analog pins are mapped to 5 pressure and 1 flex sensors.
 * Digital PWM pins are connected to vibration motors
 */

#include "ReadFromProcessing.h"

// Digital Pins
const byte PWM_PINS[] = {3, 5, 6, 9, 10, 11};
ReadFromProcessing processing;
int motorVal[5];
int i;

void setup() {
  Serial.begin(9600);
  pinMode(PWM_PINS[0], OUTPUT);
  i=0;
}

void loop() {
/*
 * 1. Receive values from pressure sensors and write byte codes to serial
 * 2. Receive motor values from serial
 * 3. Control motors with received values
 */
  //sendSensorVals();
  if(Serial)
    processing.readFromSerial();
  if (processing.isReady())
  {
    processing.getMotorVal(motorVal);
    Serial.print(motorVal[0]);
    i = motorVal[0]*2;
  }
  //controlMotors();  NOT IMPLEMENTED YET
  analogWrite(PWM_PINS[0], i);
}

void sendSensorVals() {
/*
 * Serial communication sends an array of 12 bytes
 * Each sensor takes up 2 bytes
 * 0-5th pin: thumb-pinky pressure
 *   6th pin: flex
 */
  byte boundary[] = {255, 255};
  byte vals[12];
  for (byte i=0; i<6; i++) {
    word raw = analogRead(i);
    if (i!=0) // For now, only the 0th sensor is working
      raw = 0;
    vals[i*2] = highByte(raw);
    vals[i*2+1] = lowByte(raw);
  }

// Boundary is necessary to deliminate sensor values
// Since no sensor value can reach "11111111" in binary,
// this number is used to show the boundary
  Serial.write(boundary, 2);
  Serial.write(vals, sizeof(vals));
  //Serial.println("\n");
  //Serial.println(sizeof(vals));
}
