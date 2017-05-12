import processing.serial.*;

import controlP5.*;
ControlP5 cp5;

PFont font;
PFont writingFont;

float bW;

//program states
int state;
final int START = 0;
final int VIEW = 1;
final int UPDATE = 2;

//buffer sizes
int minutesBefore = 30;
int waterBefore = 30;

Textfield name; 
Numberbox pheight, weight, age;
Button create, edit, save, getDehydration, getWater, getHeart;
Toggle gender;

boolean add;

int genderValue = 1;
String genderString = "Male";
String userName;
float userHeight = 180;
float userWeight = 90;
float userAge = 50;

//these are the values for each cm of the bottle, stopping at the max height of 10 cm. its 414ml/cm
int arrVolume[] = {
  414, 373, 331, 290, 248, 207, 166, 124, 83, 41, 0
};

//instantaneous volume
int bottleVolume;
//total consumed water
int totalWater;

boolean collectWaterData, collectDehydrationData, collectHeartData;
Serial myPort;

boolean writeBeat;
ArrayList<Integer> hydrationInfoGraph = new ArrayList<Integer>();
ArrayList<Integer> bottleInfoGraph = new ArrayList<Integer>();
ArrayList<Integer> heartGraph = new ArrayList<Integer>();

//************************************************************************HEART
//heart rate receiving is inspired by the communication in the code provided by pulsesensor.com

int Sensor;      // HOLDS PULSE SENSOR DATA FROM ARDUINO
int IBI;         // HOLDS TIME BETWEN HEARTBEATS FROM ARDUINO
int BPM;         // HOLDS HEART RATE VALUE FROM ARDUINO
int[] RawY;      // HOLDS HEARTBEAT WAVEFORM DATA BEFORE SCALING
int[] ScaledY;   // USED TO POSITION SCALED HEARTBEAT WAVEFORM
int[] rate;      // USED TO POSITION BPM DATA WAVEFORM

//  THESE VARIABLES DETERMINE THE SIZE OF THE DATA WINDOWS
int PulseWindowWidth = 490;
int PulseWindowHeight = 512; 
int BPMWindowWidth = 180;
int BPMWindowHeight = 340;
boolean beat = false;    // set when a heart beat is detected, then cleared when the BPM graph is advanced


void setup() {
  myPort = new Serial(this, Serial.list()[0], 115200);  
  size(800, 800);
  totalWater = 0;
  
  RawY = new int[PulseWindowWidth];          // initialize raw pulse waveform array
  ScaledY = new int[PulseWindowWidth];       // initialize scaled pulse waveform array
  rate = new int [BPMWindowWidth];           // initialize BPM waveform array



  myPort.clear();            // flush buffer

  cp5 = new ControlP5(this);

  state = VIEW;

  edit = cp5.addButton("EDIT")
    .setPosition(650, 20)
      .setSize(50, 20)
        .setColorBackground(color(255, 0, 0))
          .setVisible(true)
            ;

  getDehydration = cp5.addButton("GET DEHYDRATION")
    .setPosition(300, 700)
      .setSize(100, 20)
        .setColorBackground(color(255, 0, 0))
          .setVisible(true)
            ;

  getWater = cp5.addButton("GET WATER")
    .setPosition(100, 700)
      .setSize(100, 20)
        .setColorBackground(color(255, 0, 0))
          .setVisible(true)
            ;

  getHeart = cp5.addButton("GET HEART RATE")
    .setPosition(500, 700)
      .setSize(100, 20)
        .setColorBackground(color(255, 0, 0))
          .setVisible(true)
            ;


  font = loadFont("ARCARTER-48.vlw");
  writingFont = loadFont("ARHERMANN-15.vlw");

  name = cp5.addTextfield("name")
    .setPosition(300, 280)//<-----position
      .setSize(150, 20)
        .setFont(writingFont)
          .setFocus(true)
            .setVisible(false)
              ;

  pheight =  cp5.addNumberbox("height")
    .setPosition(300, 330)//<-----position
      .setSize(150, 20)
       
        .setVisible(false)
          ;

  weight =  cp5.addNumberbox("weight")
    .setPosition(300, 380)//<-----position
      .setSize(150, 20)
        .setVisible(false)
          ;

  age =  cp5.addNumberbox("age")
    .setPosition(300, 430)//<-----position
      .setSize(150, 20)
        .setVisible(false)
          ;

  create = cp5.addButton("CREATE")
    //  .setValue(0)
    .setPosition(250, 550)
      .setSize(250, 20)
        .setColorBackground(color(255, 0, 0))
          .hide();
  ;

  save = cp5.addButton("SAVE")
    .setPosition(250, 550)
      .setSize(250, 20)
        .setColorBackground(color(255, 0, 0))
          .hide()
            ;

  gender = cp5.addToggle("gender", false, 300, 480, 60, 20)
    .hide();
  ;
}


//tell processing to send dehydration info
void sendRequestDehydration() {

  myPort.write((byte)40); 
  myPort.write((byte)63); 
  myPort.write((byte)minutesBefore);
}

//tell processsing to send bottle water info
void sendRequestWater() {

  myPort.write((byte)250); 
  myPort.write((byte)163); 
  myPort.write((byte)waterBefore);
}

//tell processing to send heart rate info
void sendRequestHeart() {
  myPort.write((byte) 122);
  myPort.write((byte) 63);
}

//tell processing to STOP sending heart info
void stopRequestHeart() {
  myPort.write((byte) 111);
  myPort.write((byte) 63);
}

void draw() {
  
  //convert distance readings into bottle volume and 
  if (collectWaterData) {
    if (myPort.available() > 0) {
      int bottleReading = myPort.read();
      if (bottleReading > 10) bottleReading = 10;
      if (bottleReading  < 0) bottleReading = 0;
      bottleVolume = arrVolume[bottleReading];
      println(bottleVolume);
      println(bottleInfoGraph.size() + "SIZE");

      bottleInfoGraph.add(bottleVolume);
      
      //adding up the consumed water
        if( add && bottleInfoGraph.size() > 1 && bottleInfoGraph.get(0) < bottleInfoGraph.get(1)){
          totalWater += (bottleInfoGraph.get(1) - bottleInfoGraph.get(0));
          add = false;
        }
     

    }
  }

  if (collectDehydrationData) {
    if (myPort.available() > 0) {
      int reading =  myPort.read();
       bW = 0.372*(userHeight*userHeight/(reading*10) + 3.05*(genderValue) + 0.142*userWeight - 0.069*(userAge));
      if(bW <= 0 ) bW = 0;
      if(bW >= 100) bW = 100;
      hydrationInfoGraph.add((int)bW);
      println(reading);
    }
  }

  if (collectHeartData) {
    if (writeBeat) {
      heartGraph.add(0);
      writeBeat  = false;
    } else if (frameCount%30 == 0) {
      heartGraph.add(700);
    }

    if (heartGraph.size() > 30) {
      heartGraph.remove(0);
    }
  }


  background(255);


  if (state == START) {
    stroke(0);
    fill(0);
    textFont(font);
    text("DRINKFIT", 320, 100);
    textFont(font, 20);
    text("Create profile", 340, 200);
    text("Enter name:", 180, 300);
    text("Enter height (cm):", 180, 350);
    text("Enter weight (kg):", 180, 400);
    text("Enter age (years):", 180, 450);
    text("Sex (M/F):", 180, 500);
    text(genderString, 400, 500);
  }

  if (state == VIEW) {
    noFill();
    stroke(4);
    rect(0, 100, 800, 150);    
    rect(0, 280, 800, 150);
    rect(0, 460, 800, 150);
    fill(0);
    text("Hello " + userName, 380, 50);
    text("Age: " + userAge, 20, 50);
    text("Height: " + userHeight, 100, 50);
    text("Weight: " + userWeight, 180, 50);
    text("Total Water:" + totalWater + "mL", 600, 275);
    text("Heart rate:" + BPM + "BPM", 600, 625);
    if(hydrationInfoGraph.size() > 1)
    text("Hydration:" + hydrationInfoGraph.get(0) + "%", 600, 450);


    textSize(8);
    stroke(200);
    
    //graph lines and numbers for water
    for (int i = 0; i < arrVolume.length; i++) {
      text(Integer.toString(arrVolume[i]), 10, 250-15*i);
      line(0, 250 - 15*i, 800, 250 - 15*i);
    }
    
    //graph lines and numbers for dehydration
    for(int i = 0; i <= 100; i+=10){
      text(i, 10, 290+1.3*i);
      line(0, 290+1.3*i, 800, 290+1.3*i);
    }
    textSize(11);

    text("WATER", 400, 260);
    text("DEHYDRATION", 400, 440);
    text("HEART RATE", 400, 620);
    stroke(255, 0, 0);
    strokeWeight(3);
    
    //draw graphs
    for (int i = 0; i < bottleInfoGraph.size () - 1; i++) {
      line(30*i, (bottleInfoGraph.get(i)/2.2) + 100, 30*(i + 1), (bottleInfoGraph.get(i+ 1)/2.2) + 100);
    }

    for (int i = 0; i < hydrationInfoGraph.size () - 1; i++) {
      line(30*i, (hydrationInfoGraph.get(i)) + 310, 30*(i + 1), (hydrationInfoGraph.get(i+ 1)) + 310);
    }

    for (int i = 0; i < heartGraph.size () - 1; i++) {
      line(30*i, (heartGraph.get(i)/5) + 460, 30*(i + 1), (heartGraph.get(i+ 1)/5) + 460);
    }
    strokeWeight(1);
  }

  if (state == UPDATE) {
    fill(0);
    stroke(0);
    text("Update profile", 340, 200);

    text("Update height:", 200, 350);
    text("Update weight:", 200, 400);
    text("Update age:", 200, 450);
    text(genderString, 200, 500);
  }

  heartDraw();
}

void heartDraw() {
  noStroke();
  
  // prepare pulse data points    
  RawY[RawY.length-1] = (1023 - Sensor) - 212;   // place the new raw datapoint at the end of the array
  for (int i = 0; i < RawY.length-1; i++) {      // move the pulse waveform by
    RawY[i] = RawY[i+1];                         // shifting all raw datapoints one pixel left
  }
  
  // first, shift the BPM waveform over to fit then next data point only when a beat is found
  if (beat == true) {    
    writeBeat = true;
    for (int i=0; i<rate.length-1; i++) {
      rate[i] = rate[i+1];          // shift the bpm Y coordinates over one pixel to the left
    }
    beat = false;      // clear beat flag (beat flag waset in serialEvent tab)
    BPM = min(BPM, 200);                     // limit the highest BPM value to 200
  } 
 
}


public void controlEvent(ControlEvent e) {
  // println(e.getController().getName());
  if (e.getController().getName() == "gender") {
    if (genderValue == 0) {
      genderValue = 1;
      genderString = "Male";
    } else if (genderValue == 1) {
      genderValue = 0;
      genderString = "Female";
    }
  
  }

  if (e.getController().getName() == "CREATE") {
    userName = name.getText();
    userHeight = pheight.getValue();
    userWeight = weight.getValue();
    userAge = age.getValue();
    name.setVisible(false);
    pheight.setVisible(false);
    weight.setVisible(false);
    age.setVisible(false);
    gender.setVisible(false);
    create.hide();

    state = VIEW;
    edit.setVisible(true);
    getDehydration.setVisible(true);

    myPort.write((byte)81);
    myPort.write((byte)86);
    myPort.write((byte)userHeight);
    myPort.write((byte)userWeight);
    myPort.write((byte) userAge);
    myPort.write((byte)genderValue);
    println("reached");
  }

  if (e.getController().getName() == "GET DEHYDRATION") {
    if (collectHeartData) stopRequestHeart();
    delay(1000);
    sendRequestDehydration();
    collectWaterData = false;
    collectDehydrationData = true;
    collectHeartData = false;
    hydrationInfoGraph.clear();
  }

  if (e.getController().getName() == "GET WATER") {
    myPort.clear();
    if (collectHeartData) stopRequestHeart();
    sendRequestWater();
    collectWaterData = true;
    collectDehydrationData = false;    
    collectHeartData = false;
    bottleInfoGraph.clear();
    add = true;
   // totalWater = 0;
  }

  if (e.getController().getName() == "GET HEART RATE") {
    sendRequestHeart();
    collectHeartData = true;
    collectWaterData = false;
    collectDehydrationData = false;
  }


  if (e.getController().getName() == "EDIT") {
    state = UPDATE;
    edit.hide();
    pheight.setVisible(true);
    weight.setVisible(true);
    age.setVisible(true);
    save.setVisible(true);
    gender.setVisible(true);
    getWater.hide();
    getDehydration.hide();
    getHeart.hide();
  }

  if (e.getController().getName() == "SAVE") {

    userName = name.getText();
    userHeight = pheight.getValue();
    userWeight = weight.getValue();
    userAge = age.getValue();
    name.setVisible(false);
    pheight.setVisible(false);
    weight.setVisible(false);
    age.setVisible(false);
    gender.setVisible(false);
    getWater.setVisible(true);
    getDehydration.setVisible(true);
    getHeart.setVisible(true);
    save.hide();
    state = VIEW;
    edit.setVisible(true);
    myPort.write("1");
    myPort.write((byte)userHeight);
    myPort.write((byte)userWeight);
    myPort.write((byte) userAge);
    myPort.write((byte)genderValue);
    println("reached");
  }
}



void serialEvent(Serial port) { 
  String inData = port.readStringUntil('\n');

  if (inData == null) {                 // bail if we didn't get anything
    return;
  }   
  if (inData.isEmpty()) {                // bail if we got an empty line
    return;
  }
  inData = trim(inData);                 // cut off white space (carriage return)   
  if (inData.length() <= 0) {             // bail if there's nothing there
    return;
  }

  if (inData.charAt(0) == 'S') {          // leading 'S' for sensor data
    inData = inData.substring(1);        // cut off the leading 'S'
    Sensor = int(inData);                // convert the string to usable int
  }
  if (inData.charAt(0) == 'B') {          // leading 'B' for BPM data
    inData = inData.substring(1);        // cut off the leading 'B'
    BPM = int(inData);                   // convert the string to usable int
    beat = true;                         // set beat flag to advance heart rate graph
  }
  if (inData.charAt(0) == 'Q') {            // leading 'Q' means IBI data 
    inData = inData.substring(1);        // cut off the leading 'Q'
    IBI = int(inData);                   // convert the string to usable int
  }
}

