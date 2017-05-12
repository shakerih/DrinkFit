#include "vars.h"
/*---------------------------------------------------------------------- Global Variables  ----*/
extern boolean sendHeart;
String inputString = "";         // a string to hold incoming data
boolean stringComplete = false;  // whether the string is complete
boolean stingStarted = false;
char nBytesToReceive = 0;

/*
  SerialEvent occurs whenever a new data comes in the
 hardware serial RX.  This routine is run between each
 time loop() runs, so using delay inside loop can delay
 response.  Multiple bytes of data may be available.
 */
void serialEvent() {
  char inChar;
  stringComplete = false;
  while (Serial.available()) {
    // get the new byte:
    inChar = (char)Serial.read();
    if ( nBytesToReceive == 0 ) {
      if ( inChar == HEART_REQUEST_LO ||  inChar == HEART_STOP_LO)
        nBytesToReceive = 1;
      else if ( inChar == WR_USER_PARAM_LO )
        nBytesToReceive = 5;
      else if ( inChar == REQUEST_READ_LO )
        nBytesToReceive = 2;
      if ( nBytesToReceive > 0 ) {
        // add it to the inputString:
        inputString += inChar;
      }
    }
    else {
      // add it to the inputString:
      inputString += inChar;
      nBytesToReceive--;
      if ( nBytesToReceive == 0 ) {
        stringComplete = true;
      }
    }
  }
}




void sendDataToSerial(char symbol, int data ) {
  if(sendHeart){
  Serial.print(symbol);

  Serial.println(data);
  }
}




void serialOutput() {  // Decide How To Output Serial. HEART
  if(sendHeart){
    sendDataToSerial('S', Signal);     // goes to sendDataToSerial function
  }
}


//  Decides How To OutPut BPM and IBI Data HEART
void serialOutputWhenBeatHappens() {
  if(sendHeart) {
    sendDataToSerial('B', BPM);  // send heart rate with a 'B' prefix
    sendDataToSerial('Q', IBI);  // send time between beats with a 'Q' prefix
  }
}

void checkRequest() {
  char nChar = inputString[0];
  switch ( nChar ) {
    case HEART_REQUEST_LO:
      nChar = inputString[1];
      if ( nChar == HEART_REQUEST_HI )
        sendHeart = true;
      break;
    case HEART_STOP_LO:
      nChar = inputString[1];
      if ( nChar == HEART_STOP_HI )
        sendHeart = false;
      break;
    case WR_USER_PARAM_LO:
      nChar = inputString[1];
      if ( nChar == WR_USER_PARAM_HI ) {
        EEPROM.write(EE_HEIGHT_ADDRESS, inputString[2]);
        EEPROM.write(EE_WEIGHT_ADDRESS, inputString[3]);
        EEPROM.write(EE_AGE_ADDRESS, inputString[4]);
        EEPROM.write(EE_GENDER_ADDRESS, inputString[5]);
      }
      break;
    case REQUEST_READ_LO:
      nChar = inputString[1];
      if ( nChar == REQUEST_READ_HI )
        respondToRequest(inputString[2]);
      break;
  }
  // clear the string:
  inputString = "";
  stringComplete = false;
}


