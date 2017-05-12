#include "vars.h"


void findIndex() {
  //************************************************************************EEPROM WRITING SUM
  for (eeBufferIndex = EE_BUFFER_START; eeBufferIndex <= EE_BUFFER_END; eeBufferIndex++) {

    if (EEPROM.read(eeBufferIndex) == 255) {
      break;
    }
  }
  if (eeBufferIndex == EE_BUFFER_END) {
    eeBufferIndex = EE_BUFFER_START;
  }
}

void respondToRequest(int buffSize) {
  int tempIndex;
  for (int i = 1; i <= buffSize; i++) {
    tempIndex = eeBufferIndex - i;
    if (tempIndex < EE_BUFFER_START) {
      tempIndex += EE_BUFFER_SIZE;
    }
    Serial.write(EEPROM.read(tempIndex));
    Serial.flush();  // Waits for the transmission of outgoing serial data to complete
  }
}

void writeEEPROM(byte value) {
  EEPROM.write(eeBufferIndex, value);
  eeBufferIndex++;
  //WRITE 255 TO FIND AVAILABLE SPOT TO WRITE IN NEXT TIME
  EEPROM.write(eeBufferIndex, (byte)255);
  if (eeBufferIndex > EE_BUFFER_END) {
    eeBufferIndex = EE_BUFFER_START;
  }
}


