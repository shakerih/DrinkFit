#include <PWM.h>
#include <EEPROM.h>
#include "vars.h"

/*---------------------------------------------------------------------- Global Variables  ----*/
extern String inputString;
extern boolean stringComplete;
extern volatile boolean QS;

byte bytelist[1024];

int32_t frequency = 25000; // desired frequency in Hertz
volatile int i = 0;
byte userInfo[5];
boolean getting = true;
float sum = 0;


byte countSeconds;
boolean sendHeart;

int eeBufferIndex;
int pulsePin = 4;                 // Pulse Sensor purple wire connected to analog pin 4

// Regards Serial OutPut  -- Set This Up to your needs
//static final boolean serialVisual = false;   // Set to 'false' by Default.  Re-set to 'true' to see Arduino Serial Monitor ASCII Visual Pulse

/*---------------------------------------------------------------------- Functions  ----*/





void setup()
{
  sendHeart = false;
  // defines for setting and clearing register bits
#ifndef cbi
#define cbi(sfr, bit) (_SFR_BYTE(sfr) &= ~_BV(bit))
#endif
#ifndef sbi
#define sbi(sfr, bit) (_SFR_BYTE(sfr) |= _BV(bit))
#endif


  // set prescale to 16
  cbi(ADCSRA, ADPS2) ;
  sbi(ADCSRA, ADPS1) ;
  cbi(ADCSRA, ADPS0) ;

  //initialize all timers except for 0, to save time keeping functions
  InitTimersSafe();
  interruptSetup();       // sets up to read Pulse Sensor signal every 2mS 
  countSeconds = 0;

  pinMode(5, OUTPUT);
  pinMode(7, INPUT);
  SetPinFrequency(5, frequency);

  // initialize serial:
  Serial.begin(115200);
  // reserve 10 bytes for the inputString:
  inputString.reserve(10);

  findIndex();

}




void mainCycle() {
  countSeconds++;
  if (countSeconds > 10) {
    countSeconds = 0;
    analogWrite(5, 127); //PWM TURN ON FOR ONLY 1 SECOND AND THEN TURN OFF

    for (int i = 0; i < 1024; i++) {
      delayMicroseconds(5);
      bytelist[i] = analogRead(A0) / 4;
    }
    analogWrite(5, 0); //PWM TURN OFF
    for (int i = 0; i < 1024; i++) {
      sum += bytelist[i];
    }

    //CALCULATING HYDRATION*************************************
    sum /= 1024;
    sum = sum;
    // ( sum == 0.0 ) sum = 0.1;
    //sum = 0.372 * (EEPROM.read(EE_HEIGHT_ADDRESS) * EEPROM.read(EE_HEIGHT_ADDRESS) / sum) + 3.05 * EEPROM.read(EE_GENDER_ADDRESS) + 0.142 * EEPROM.read(EE_WEIGHT_ADDRESS) - 0.069 * EEPROM.read(EE_AGE_ADDRESS);
    writeEEPROM((byte)sum);
    if (digitalRead(7) == 0) {
      //      for (int i = 0; i < 1024; i++) {
      //        Serial.write((byte)bytelist[i]);
      //      }
      //      Serial.write((byte)sum);
    }
  }

  if (Serial.available() >= 3) {
    checkRequest();
  }
  delay(4000);


}

void loop()
{

  // print the string when a newline arrives:
  if (stringComplete) {
    checkRequest();
  }

  if (sendHeart ) {
    serialOutput() ;

    if (QS == true) {    // A Heartbeat Was Found
      // BPM and IBI have been Determined
      // Quantified Self "QS" true when arduino finds a heartbeat

      // Set 'fadeRate' Variable to 255 to fade LED with pulse
      serialOutputWhenBeatHappens();   // A Beat Happened, Output that to serial.
      QS = false;                      // reset the Quantified Self flag for next time
    }
  }

  mainCycle();

}


