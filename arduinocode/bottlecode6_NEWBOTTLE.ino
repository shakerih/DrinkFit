
#include <Wire.h>
#include <L3G.h>
#include <EEPROM.h>

L3G gyro;

boolean flat;


long duration;
const int trigPin = 2;
const int echoPin = 4;

byte cm;

#define EE_BUFFER_START 505
#define EE_BUFFER_END 905
#define EE_BUFFER_SIZE 400;

#define REQUEST_READ_LO 250
#define REQUEST_READ_HI 163

byte countSeconds = 0;

int eeBufferIndex;

void findIndex() {
  //find the first available index to write in EEPROM
  for (eeBufferIndex = EE_BUFFER_START; eeBufferIndex <= EE_BUFFER_END; eeBufferIndex++) {

    if (EEPROM.read(eeBufferIndex) == 255) {
      break;
    }
  }
  if (eeBufferIndex == EE_BUFFER_END) {
    eeBufferIndex = EE_BUFFER_START;
  }
}

void setup() {
  // initialize serial communication:
  Serial.begin(115200);
  Wire.begin();

  findIndex();

  if (!gyro.init())
  {
    //    Serial.println("Failed to autodetect gyro type!");
    while (1);
  }

  gyro.enableDefault();

  cm = 0;

}


long microsecondsToCentimeters(long microseconds)
{
  //turn ping duration into cm
  return microseconds / 29 / 2;

}

void writeEEPROM(byte value) {
  //write value to index in EEPROM
  EEPROM.write(eeBufferIndex, value);
  eeBufferIndex++;
  //WRITE 255 TO FIND AVAILABLE SPOT TO WRITE IN NEXT TIME
  EEPROM.write(eeBufferIndex, (byte)255);
  if (eeBufferIndex > EE_BUFFER_END) {
    eeBufferIndex = EE_BUFFER_START;
  }

}

void respondToRequest(int buffSize) {
  //read from EEPROM and send to serial according to requested buffersize
  int tempIndex;
  byte n;
  for (int i = 1; i <= buffSize; i++) {
    tempIndex = eeBufferIndex - i;
    if (tempIndex < EE_BUFFER_START) {
      tempIndex += EE_BUFFER_SIZE;
    }
    n = EEPROM.read(tempIndex);
    Serial.write(n);
    Serial.flush();
  }
}

void checkRequest() {
  //check if the processing is sending a request
  int readBuffSize = 0;
  byte first = Serial.read();
  if (first == REQUEST_READ_LO) {
    if (Serial.read() == REQUEST_READ_HI) {
      readBuffSize = Serial.read();
      if (readBuffSize > 0 && readBuffSize <= 400) {
        respondToRequest(readBuffSize);
      }
    }
  }
}

void mainCycle() {
  //write cm to EEPROM and wait for a request
  
  countSeconds++;
  if (countSeconds > 10) {
    countSeconds = 0;
    writeEEPROM((byte)cm);
  }

  if (Serial.available() >= 3) {
    checkRequest();
  }
  delay(454);

}


void loop() {
  gyro.read();
  flat = false;
  if ((int) gyro.g.x > -300 && (int) gyro.g.x < 300 && (int) gyro.g.y > 100 && (int) gyro.g.y < 400) {
    flat = true;
  }

//if gyro is flat, measure the distance to the water.

  if (true) {

    pinMode(trigPin, OUTPUT);
    digitalWrite(trigPin, LOW);
    delayMicroseconds(2);
    digitalWrite(trigPin, HIGH);
    delayMicroseconds(10);
    digitalWrite(trigPin, LOW);


    pinMode(echoPin, INPUT);
    duration = pulseIn(echoPin, HIGH);

    // convert the time into a distance
    cm = microsecondsToCentimeters(duration);


    mainCycle();
  }
}




