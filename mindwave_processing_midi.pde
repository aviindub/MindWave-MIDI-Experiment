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
 | an alternative library |
 | https://github.com/agoransson/JSON-processing |
 | |
 +------------------------------------------------------------------------------------+
 */


import themidibus.*;
import processing.net.*;
// I am assuming here that you are using the Processing 1.0 release or higher. Libraries are added to your processing sketchbook folder (~user/Documents/Processing on a Mac) in a directory called ‘libraries’.
//If it doesn’t already exist, create it, and drop the unzipped ‘json’ folder inside)
import org.json.*;

Client myBrainwave;
MidiBus midiBus;
int fps, i;
int data, oldData, newData;
int[] intPoints;
float floatPoint;

Boolean Debug = true;
Boolean DynamicRange = false;

//setting global variables to make range of slider dynamically based on input range if wanted
//set here your maxvalue for sliders
int Max1 = 0;
int Max2 = 0;
int Max3 = 0;
int Max4 = 0;
int Max5 = 0;
int Max6 = 0;
int Max7 = 0;
int Max8 = 0;

int time1, time2, loopCounter;

//strings 4 data in
String dataIn;

void setup() {

  fps = 60;
  frameRate(fps);
  intPoints = new int[fps];

  //initialize MidiBus with no input, and LoopBe as output
  midiBus = new MidiBus(this, -1, "LoopBe Internal MIDI");

  // Connect to the local machine at port 13854.
  //we use socket connection.
  // This example will not run if you haven't
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

  if (Debug) {
    //should print on each iteration of loop regardless of dataIn
    println("loop time: " + time2 + "  loop number " + loopCounter);
  }

  if (myBrainwave.available() > 0) {

    dataIn = myBrainwave.readString();

    if (Debug) {
      //made it to dataIn
      println(dataIn);

      try {
        //parse JSON object from dataIn string
        JSONObject nytData = new JSONObject(dataIn);

        //parse individual datasets from main JSON object
        JSONObject results = nytData.getJSONObject("eegPower"); //eegPower dataset

          JSONObject resultsM = nytData.getJSONObject("eSense"); //eSense dataset

          //JSONObject rawData = nytData.getJSONObject("rawEeg");
        //JSONObject resultsB = nytData.getJSONObject("blinkStrength");

        //pull individual values from eSense and eegPower JSON objects
        //this is the eegPower stuff
        int delta = results.getInt("delta");
        int theta = results.getInt("theta");
        int lowAlpha = results.getInt("lowAlpha");
        int highAlpha = results.getInt("highAlpha");
        int lowBeta = results.getInt("lowBeta");
        int highBeta = results.getInt("highBeta");
        int lowGamma = results.getInt("lowGamma");
        int highGamma = results.getInt("highGamma");
        //this is the eSense stuff
        int attention = resultsM.getInt("attention");
        int meditation = resultsM.getInt("meditation");

        newData = attention;
        println("data = " + data + " newData = " + newData);
      } 
      catch (JSONException e) {
        if (Debug) {
          println ("There was an error parsing the JSONObject.");
          println(e);
        }
      }
    }
  }
  if (newData != data) { //check if we actually got new data
    //save new data and recalc interpolation points
    data = newData;
    recalculatePoints(intPoints[i], data);
    if (Debug) println("recalculated points");
    i = 0;
  } 
  else {
    //SEND MIDI CONTRTOL
    midiBus.sendControllerChange(0, 3, intPoints[i]);
    if (Debug) println("sent midi control " + intPoints[i] + " i = " + i);
    i++;
    if (i >= fps) { //make sure i doesnt go out of bounds for intPoints[] if no update in >1sec
      i = fps - 1;
    }
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

void keyPressed() {

  if (Debug) {
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

void DebugMode(boolean theFlag) {
  if (theFlag==true) {
    Debug = true;
    println("DEBUG TOGGLE ON.");
  } 
  else {
    Debug = false;
    println("DEBUG TOGGLE OFF.");
  }
}

