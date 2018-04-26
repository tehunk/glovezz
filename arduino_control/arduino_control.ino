/*
 * Arduino Sensor/Motor Communication
 * 
 * Author: Tae Hun Kim
 * Last Updated: 12 APR 2018
 * 
 * Analog pins are mapped to 5 pressure and 1 flex sensors.
 * Digital PWM pins are connected to vibration motors
 */

#include <Timer.h>
#include <Event.h>
Timer t;

// Digital Pins
const byte PWM_PINS[] = {3, 5, 6, 9, 10};
char raw[] = {0, 0, 0, 0, 0, 0};
int motorVals[] = {0, 0, 0, 0, 0};
int motorVal[5];
void* CONTEXT = 0;

void setup() {
  Serial.begin(9600);
  for (int i=0; i<5; i++)
    pinMode(PWM_PINS[i], OUTPUT);
  t.every(50, sendSensorVals, CONTEXT);
}

/*
 * 1. Receive values from pressure sensors and write byte codes to serial
 * 2. Receive motor values from serial
 * 3. Control motors with received values
 */
void loop() {
  if(Serial.available() >= 6) {
    digitalWrite(13, HIGH);
    Serial.readBytesUntil('e', raw, 6);
    for(int i=0; i<5; i++)
      motorVals[i] = (raw[i]=='0') ? LOW : HIGH;
    t.after(100, resetMotor, CONTEXT);
  }
  for(int i=0; i<5; i++)
    digitalWrite(PWM_PINS[i], motorVals[i]);
  t.update();
  // }  
}

/*
 * Serial communication sends an array of 12 bytes
 * Each sensor takes up 2 bytes
 * 0-4th pin: thumb-pinky pressure
 *   5th pin: flex
 */
void sendSensorVals() {
  byte boundary[] = {255, 255};
  byte vals[12];
  for (byte i=0; i<6; i++) {
    word raw = analogRead(i);
    Serial.print(i);
    Serial.print(": ");
    Serial.println(raw);
    if (i>=3) // For now, only the 5th sensor (flex) is not supported
      raw = 0;
    vals[i*2] = highByte(raw);
    vals[i*2+1] = lowByte(raw);
  }

// Boundary is necessary to deliminate sensor values
// Since no sensor value can reach "11111111" in binary,
// this number is used to show the boundary
  
  //Serial.write(vals, sizeof(vals));
  //Serial.write(boundary, 2);
}

void resetMotor()
{
  for(int i=0; i<5; i++)
    motorVals[i] = 0;
  digitalWrite(13, LOW);
}