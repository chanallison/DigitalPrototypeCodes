import processing.serial.*;
PFont font;

Serial port;
int numSensors = 2; // Change this if you want to use more sensors

int[] Sensor;      // HOLDS PULSE SENSOR DATA FROM ARDUINO
int[] IBI;         // HOLDS TIME BETWEN HEARTBEATS FROM ARDUINO
int[] BPM;         // HOLDS HEART RATE VALUE FROM ARDUINO
int[][] RawPPG;      // HOLDS HEARTBEAT WAVEFORM DATA BEFORE SCALING
int[][] ScaledPPG;   // USED TO POSITION SCALED HEARTBEAT WAVEFORM
int[][] ScaledBPM;      // USED TO POSITION BPM DATA WAVEFORM
int[][] cloudPPG;      // USED TO POSITION BPM DATA WAVEFORM

float offset;    // USED WHEN SCALING PULSE WAVEFORM TO PULSE WINDOW
color eggshell = color(255, 253, 248);
int heart[];   // USED TO TIME THE HEART 'PULSE'

//  THESE VARIABLES DETERMINE THE SIZE OF THE DATA WINDOWS
int PulseWindowWidth; // = 490;
int PulseWindowHeight; // = 512;
int PulseWindowX;
int PulseWindowY[];
int BPMWindowWidth; // = 180;
int BPMWindowHeight; // = 340;
int BPMWindowX;
int BPMWindowY[];
int spacer = 10;
boolean beat[];    // set when a heart beat is detected, then cleared when the BPM graph is advanced

boolean BPMOver = false;
boolean BPMOverArrayOne = false;
boolean BPMOverArrayTwo = false;


// SERIAL PORT STUFF TO HELP YOU FIND THE CORRECT SERIAL PORT
String serialPort;
String[] serialPorts = new String[Serial.list().length];
boolean serialPortFound = true;
Radio[] button = new Radio[Serial.list().length*2];
int numPorts = serialPorts.length;
boolean refreshPorts = false;
String serialNum = Serial.list()[1];
int cloudParNum = 5;

//::::::::::::::::::::::::::::::SENSOR STUFF ENDS::::::::::::::::::::::::::::::::::::::::::::

int n = 10000;

float[] m = new float[n];
float[] x = new float[n];
float[] y = new float[n];
float[] vx = new float[n];
float[] vy = new float[n];

//::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

void setup() {
  fullScreen();
  //size(900, 725);   
  //size(700, 725);
  fill(0, 32);
  reset();

  //::::::::::::::::::::::::::::::SENSOR STUFF BEGINS::::::::::::::::::::::::::::::::::::::::::::


  frameRate(60);
  font = loadFont("Arial-BoldMT-24.vlw");
  textFont(font);
  textAlign(CENTER);
  rectMode(CORNER);
  ellipseMode(CENTER);
  // Display Window Setup
  PulseWindowWidth = width;
  PulseWindowHeight = 1;
  PulseWindowX = 10;
  PulseWindowY = new int [numSensors];
  for (int i=0; i<numSensors; i++) {
    PulseWindowY[i] = 43 + (PulseWindowHeight * i);
    if (i > 0) PulseWindowY[i]+=spacer*i;
  }
  BPMWindowWidth = 180; //what?
  BPMWindowHeight = PulseWindowHeight;
  BPMWindowX = PulseWindowX + PulseWindowWidth + 10;
  BPMWindowY = new int [numSensors];
  for (int i=0; i<numSensors; i++) {
    BPMWindowY[i] = 43 + (BPMWindowHeight * i);
    if (i > 0) BPMWindowY[i]+=spacer*i;
  }
  heart = new int[numSensors];
  beat = new boolean[numSensors];
  // Data Variables Setup
  Sensor = new int[numSensors];      // HOLDS PULSE SENSOR DATA FROM ARDUINO
  IBI = new int[numSensors];         // HOLDS TIME BETWEN HEARTBEATS FROM ARDUINO
  BPM = new int[numSensors];         // HOLDS HEART RATE VALUE FROM ARDUINO
  RawPPG = new int[numSensors][PulseWindowWidth];          // initialize raw pulse waveform array
  ScaledPPG = new int[numSensors][PulseWindowWidth];       // initialize scaled pulse waveform array
  cloudPPG = new int[numSensors][PulseWindowWidth * cloudParNum];       // initialize cloud pulse waveform array
  ScaledBPM = new int [numSensors][BPMWindowWidth];           // initialize BPM waveform array

  // set the visualizer lines to 0
  resetDataTraces();

  background(0);
  noStroke();
  // DRAW OUT THE PULSE WINDOW AND BPM WINDOW RECTANGLES
  //drawDataWindows();
  //drawHeart();

  // GO FIND THE ARDUINO
  fill(255);
  //text("Select Your Serial Port", 245, 30);
  listAvailablePorts();
  createSerialPort();
}
//:::::::::::::::::::::SENSOR STUFF ENDS:::::::::::::::::::::::::::::::::::::::::::::::::::::

//::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

void draw() {
  if (serialPortFound) {
    background(0);
    //drawPulseWaveform();
    noStroke();
    rect(0, 0, width, height);
    fill(0, 32);

    //::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

    //:::::::::::::::::::::SENSOR STUFF BEGINS:::::::::::::::::::::::::::::::::::::::::::::::::::::

    for (int i=0; i<numSensors; i++) {
      RawPPG[i][PulseWindowWidth-1] = (1300 - Sensor[i]);   // place the new raw datapoint at the end of the array
      //println("sensor data is: " +Sensor[i]);
      for (int j = 0; j < PulseWindowWidth-1; j++) {      // move the pulse waveform by
        RawPPG[i][j] = RawPPG[i][j+1];                         // shifting all raw datapoints one pixel left
        float dummy = RawPPG[i][j] * 0.625/numSensors;       // adjust the raw data to the selected scale
        offset = float(PulseWindowY[i]);                // calculate the offset needed at this window
        ScaledPPG[i][j] = int(dummy) + int(offset);   // transfer the raw data array to the scaled array
        //for (int k = 0; k < cloudParNum; k++) {
        //  cloudPPG[i][j] = int(dummy) + int(offset)+ int(random(-10, 10));   // transfer the raw data array to the scaled array
        //}
      }


      //:::::::::::::::::::::SENSOR STUFF ENDS:::::::::::::::::::::::::::::::::::::::::::::::::::::
      //::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

      if ((i == 0) || (i == 1)) {
        for (int k = 0; k < n; k++) {
          float dx = RawPPG[i][PulseWindowWidth-1] - x[k];
          float dy = RawPPG[i][PulseWindowWidth-1] - y[k];

          float d = sqrt(dx*dx + dy*dy);
          if (d < 1) d = 100;

          //below changes density of circles
          float f = sin(d * 0.005) * m[k] / d;

          vx[k] = vx[k] * 0.5 + f * dx;
          vy[k] = vy[k] * 0.5 + f * dy;
        }

        for (int k = 0; k < n; k++) {
          x[k] += vx[k];
          y[k] += vy[k];

          if (x[k] < 0) x[k] = width;
          else if (x[k] > width) x[k] = 0;

          if (y[k] < 0) y[k] = height;
          else if (y[k] > height) y[k] = 0;


          if (i == 0) stroke(RawPPG[i][PulseWindowWidth-1]-400, 200, 255);
          //if (i == 0) stroke(20, 200, 255);

          if (i == 1) stroke(140, RawPPG[i][PulseWindowWidth-1]/3, 255 );
          //if (i == 1) stroke(140, 20, 255 );

          if (BPMOver == true) {
            stroke(255, 0, 0 );
           
          }

          //if (BPMOverArrayOne == true) {
          //  stroke(255, 0, 0 );
          //  println("Array 1: BPM over 50");
          //}

          //if (BPMOverArrayTwo == true) {
          //  stroke(0, 0, 255 );
          //  println("Array 2: BPM over 50");
          //}

          point(x[k], y[k]);
        }
      }
    }
  } else { // SCAN TO FIND THE SERIAL PORT
    autoScanPorts();

    if (refreshPorts) {
      refreshPorts = false;
      //drawDataWindows();
      //drawHeart();

      listAvailablePorts();
    }
    for (int i=0; i<numPorts+1; i++) {
      button[i].overRadio(mouseX, mouseY);
      button[i].displayRadio();
    }
  }

  BPMOver = false;
  BPMOverArrayOne = false;
  for (int l = 0; l < BPMWindowWidth; l++) {
    if (ScaledBPM[0][l] > 50) 
    {
      BPMOverArrayOne = true;
      break;
    }
  }

  BPMOverArrayTwo = false;
  for (int l = 0; l < BPMWindowWidth; l++) {
    if (ScaledBPM[1][l] > 50) 
    {
      BPMOverArrayTwo = true;
      break;
    }
  }

  if ((BPMOverArrayOne == true) && (BPMOverArrayTwo == true)) {
    BPMOver = true;
     println("BPM over 50");
  }

  //BPMOver = false;
  //for (int l = 0; l < BPMWindowWidth; l++) {
  //  for (int j = 0; j < numSensors; j++) {    
  //    if (ScaledBPM[j][l] > 54) {
  //      BPMOver = true;
  //      println("BPM over 50");
  //      //stroke(255, 0, 0 );
  //    }
  //  }
  //}
}

//::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

void reset() {
  for (int i = 0; i < n; i++) {
    m[i] = randomGaussian() * 16;
    x[i] = random(width);
    y[i] = random(height);
  }
}

//::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

//void mousePressed() {
//  reset();
//}

//::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
//:::::::::::::::::::::::SENSOR STUFF BEGINS:::::::::::::::::::::::::::::::::::::::::::::::::::

void listAvailablePorts() {
  println(Serial.list());    // print a list of available serial ports to the console
  serialPorts = Serial.list();

  fill(255);
  textFont(font, 16);
  textAlign(LEFT);
  // set a counter to list the ports backwards
  int yPos = 0;

  for (int i=numPorts-1; i>=0; i--) {
    button[i] = new Radio(35, 95+(yPos*20), 12, color(180), color(80), color(255), i, button);
    fill(255);
    text(serialPorts[i], 50, 100+(yPos*20));
    yPos++;
  }
  int p = numPorts;
  fill(233, 0, 0);
  button[p] = new Radio(35, 95+(yPos*20), 12, color(180), color(80), color(255), p, button);
  text("Refresh Serial Ports List", 50, 100+(yPos*20));

  textFont(font);
  textAlign(CENTER);
}

void autoScanPorts() {
  if (Serial.list().length != numPorts) {
    if (Serial.list().length > numPorts) {
      println("New Ports Opened!");
      int diff = Serial.list().length - numPorts;  // was serialPorts.length
      serialPorts = expand(serialPorts, diff);
      numPorts = Serial.list().length;
    } else if (Serial.list().length < numPorts) {
      println("Some Ports Closed!");
      numPorts = Serial.list().length;
    }
    refreshPorts = true;
    return;
  }
}

void resetDataTraces() {
  for (int i=0; i<numSensors; i++) {
    BPM[i] = 0;
    for (int j=0; j<BPMWindowWidth; j++) {
      ScaledBPM[i][j] = BPMWindowY[i] + BPMWindowHeight;
    }
  }
  for (int i=0; i<numSensors; i++) {
    Sensor[i] = 512;
    for (int j=0; j<PulseWindowWidth; j++) {
      RawPPG[i][j] = 1024 - Sensor[i]; // initialize the pulse window data line to V/2
    }
  }
}

void createSerialPort() {
  try { 
    port = new Serial(this, serialNum, 250000);  // make sure Arduino is talking serial at this baud rate
    delay(1000);
    println(port.read());
    port.clear();            // flush buffer
    port.bufferUntil('\n');  // set buffer full flag on receipt of carriage return
    serialPortFound = true;
  }
  catch(Exception e) {
    println("Couldn't open port " + serialNum);
    fill(255, 0, 0);
    textFont(font, 12);
    textAlign(LEFT);
    text("Couldn't open port " + serialNum, 60, 70);
    textFont(font);
    textAlign(CENTER);
  }
}
