/*

 MindWave MIDI experiment by Avi Goldberg
 MindWave and JSON implementation based on 
 Mindwave processing experiment by Recipient.cc collective 
 
 +------------------------------------------------------------------------------------+
 | 
 | This program is free software: you can redistribute it and/or modify |
 | it under the terms of the GNU General Public License as published by |
 | the Free Software Foundation, either version 3 of the License, or |
 | (at your option) any later version. |
 | |
 | This program is distributed in the hope that it will be useful, |
 | but WITHOUT ANY WARRANTY; without even the implied warranty of |
 | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the |
 | GNU General Public License for more details. |
 | |
 | You should have received a copy of the GNU General Public License |
 | along with this program. If not, see <http://www.gnu.org/licenses/>. |
 | |
 | REFERENCES |
 | http://processing.org |
 | http://blog.blprnt.com/blog/blprnt/processing-json-the-new-york-times |
 | http://recipient.cc |
 | |
 | LIBRARIES |
 | JSON Processing Library. | http://www.blprnt.com/processing/json.zip |
 | an alternative library | https://github.com/agoransson/JSON-processing |
 |  |
 | MIDIBus library: http://smallbutdigital.com/themidibus.php|
 | LoopBe internal MIDI port: http://nerds.de/en/loopbe1.html |
 | OSX alternative to LoopBe -- ipMIDI (Not Yet Tested!): http://nerds.de/en/ipmidi_osx.html
 +------------------------------------------------------------------------------------+
 */


import themidibus.*;
import processing.net.*;
// I am assuming here that you are using the Processing 1.0 release or higher. Libraries are added to your processing sketchbook folder (~user/Documents/Processing on a Mac) in a directory called ‘libraries’.
//If it doesn’t already exist, create it, and drop the unzipped ‘json’ folder inside)
import org.json.*;

Client myBrainwave; //JSON client
MidiBus midiBus; //MidiBus
PrintWriter output; //output file
int fps, i, lastHit; 
int data, oldData, newData;
int[] intPoints; //interpolated points for the next second
float floatPoint;
color COLOR_GREEN = color(0,200,0);
color COLOR_RED = color(200,0,0);
color highColor = COLOR_GREEN; //initialize colors of ends
color lowColor = COLOR_RED;
String dataIn; //string for data from thinkgear driver


Boolean debug = true;


int HIGH_THRESH = 93;
int LOW_THRESH = 20;
boolean LOW = false;
boolean HIGH = true;
boolean lastSwitch = false;

int time1, time2, loopCounter;

void setup() {
  
  String outputFileName = "output_" + month() +"_"+ day() +"_"+ year() +"_"+ hour()+minute() +".txt";
  output = createWriter(outputFileName);
  if (debug) output.println("printWriter online.");
  output.println(outputFileName);
  
  
  size(300, 100);
  fps = 60;
  frameRate(fps);
  intPoints = new int[fps];

  //initialize MidiBus with no input, and LoopBe as output
  midiBus = new MidiBus(this, -1, "LoopBe Internal MIDI");

  // Connect to the local machine at port 13854.
  // This will not run if you haven't
  // previously started "ThinkGear connector" server
  myBrainwave = new Client(this, "127.0.0.1", 13854);
  //initialize brainwave with raw data disabled, JSON format
  myBrainwave.write("{\"enableRawOutput\": false, \"format\": \"Json\"}");
}

void draw() {

  //debugging loop counter/timer
  loopCounter++;
  time2 = millis() - time1;
  time1 = millis();

  if (debug) {
    //should print on each iteration of loop regardless of dataIn
    println("loop time: " + time2 + "  loop number " + loopCounter);
  }

  if (myBrainwave.available() > 0) {

    dataIn = myBrainwave.readString();

    if (debug) {
      //made it to dataIn
      println(dataIn);
    }
    
    try {
      //parse JSON object from dataIn string
      JSONObject headsetData = new JSONObject(dataIn);
      //parse individual datasets from main JSON object
      JSONObject results = headsetData.getJSONObject("eegPower"); //eegPower dataset
      JSONObject resultsM = headsetData.getJSONObject("eSense"); //eSense dataset
      
      //parse rawEeg data, need to change drivers mode to enable this
      //JSONObject rawData = nytData.getJSONObject("rawEeg");
      //parse blink data. also off by default.
      //JSONObject resultsB = nytData.getJSONObject("blinkStrength");

      //pull individual values from eSense and eegPower JSON objects
      //this is the eegPower stuff
      // int delta = results.getInt("delta");
      // int theta = results.getInt("theta");
      // int lowAlpha = results.getInt("lowAlpha");
      // int highAlpha = results.getInt("highAlpha");
      // int lowBeta = results.getInt("lowBeta");
      // int highBeta = results.getInt("highBeta");
      // int lowGamma = results.getInt("lowGamma");
      // int highGamma = results.getInt("highGamma");
      //this is the eSense stuff
      int attention = resultsM.getInt("attention");
      // int meditation = resultsM.getInt("meditation");

      //map the point coming in based on high and low cutoffs
      newData = constrain(attention, 0, 70); 
      newData = (int) map(newData, 0, 70, 1, 99);
      println("data = " + data + " newData = " + newData);
    } 
    catch (JSONException e) {
      if (debug) {
        println ("There was an error parsing the JSONObject.");
        println(e);
      }
    }
  }

  if (newData != data) { //check if we actually got new data
    //save new data and recalc interpolation points
    data = newData;
    
    recalculatePoints(intPoints[i], data);
    if (debug) println("recalculated points");
    i = 0;
  } 
  else {
    //SEND MIDI CONTRTOL
    midiBus.sendControllerChange(0, 3, intPoints[i]);
    if (debug) println("sent midi control " + intPoints[i] + " i = " + i);
    output.println("cursor:" + intPoints[i]);
    i++;
    if (i >= fps) { //make sure i doesnt go out of bounds for intPoints[] if no update in >1sec
      i = fps - 1;
    }
    //draw cursor and track thing
    background(255);
    fill(0);
    rect(20, 40, 260, 5);
    int cursorPos = (int) map(intPoints[i], 1, 99, 22, 275);
    rect(cursorPos, 27, 5, 30);
    
    //switch colors if just passed a threshold
    if (intPoints[i] <= LOW_THRESH && lastSwitch == HIGH) {
      switchColors();
      lastSwitch = LOW;
      //LOG THE SWITCH
      int lapTime = millis() - lastHit;
      String outputString = "Low Hit:" + millis() +":"+ lapTime;
      println(outputString);
      output.println(outputString);
      lastHit = millis();
    }
    else if (intPoints[i] >= HIGH_THRESH && lastSwitch == LOW) {
      switchColors();
      lastSwitch = HIGH;
      //LOG THE SWITCH
      int lapTime = millis() - lastHit;
      String outputString = "High Hit:" + millis() +":"+ lapTime;
      println(outputString);
      output.println(outputString);
      lastHit = millis();
    }

    fill(lowColor);
    rect(15, 27, 5, 30);
    fill(highColor);
    rect(280, 27, 5, 30);
  }
}

void recalculatePoints (int oldData, int data) {
  //recalculates the array of interpolation points 
  //based on current position and new target position

  float increment = ((float) data - oldData) / fps;
  for (int ii = 0; ii < fps; ii++) {
    float pointFloat = (oldData + (increment * ii));
    intPoints[ii] = (int) pointFloat;
  }
}

void switchColors() {
  if (highColor == COLOR_GREEN) {
    highColor = COLOR_RED;
    lowColor = COLOR_GREEN;
  }
  else {
    highColor = COLOR_GREEN;
    lowColor = COLOR_RED;
  }
}

void keyPressed() {
  if (key == 'x') {
    stop();
  }   
}

/* OLD DEBUGGING STUFF
void keyPressed() {

  if (debug) {
    if (key == 'q') {
      print("___---====Json + Raw OFF====---___");
      myBrainwave.write("{\"enableRawOutput\": false, \"format\": \"Json\"}");
    }
    if (key == 'w') {
      print("___---====Json + Raw ON====---___");
      myBrainwave.write("{\"enableRawOutput\": true, \"format\": \"Json\"}");
    }
    if (key == 'e') {
      print("___---====BinaryPacket + Raw OFF====---___");
      myBrainwave.write("{\"enableRawOutput\": false, \"format\": \"BinaryPacket\"}");
    }
    if (key == 'r') {
      print("___---====BinaryPacket + Raw ON====---___");
      myBrainwave.write("{\"enableRawOutput\": true, \"format\": \"BinaryPacket\"}");
    }
  } 
  else {
    println("enable debug mode to view data in and modify format");
  }
}

void debugMode(boolean theFlag) {
  if (theFlag==true) {
    debug = true;
    println("DEBUG TOGGLE ON.");
  } 
  else {
    debug = false;
    println("DEBUG TOGGLE OFF.");
  }
}
END OLD DEBUGGING STUFF */


void stop () {
  output.flush(); // Writes the remaining data to the file
  output.close(); // Finishes the file
  midiBus.close(); //closes midi connections
  exit();
}

