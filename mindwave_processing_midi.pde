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
//
Client myBrainwave;
MidiBus midiBus;


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

int time1,  time2, loopCounter;

//strings 4 data in
String dataIn;
 
void setup() {
  frameRate(60);
  
  //initialize MidiBus with no input, and LoopBe as output
  midiBus = new MidiBus(this, -1, "LoopBe Internal MIDI");
  
  // Connect to the local machine at port 13854.
  //we use socket connection.
  // This example will not run if you haven't
  // previously started "ThinkGear connector" server
  myBrainwave = new Client(this, "127.0.0.1", 13854);
  //initialize brainwave with raw data enabled, JSON format
  myBrainwave.write("{\"enableRawOutput\": true, \"format\": \"Json\"}");
  
}
 
void draw() {
  
  //debugging loop counter/timer
  loopCounter++;
  time2 = millis() - time1;
  time1 = millis();
  
  if (myBrainwave.available() > 0) {
   dataIn = myBrainwave.readString();
   if (Debug) {
   //debug print
   println("loop time: " + time2 + "  loop number " + loopCounter);
   println(dataIn);
   }
 try{
    //parse JSON object from dataIn string
    JSONObject nytData = new JSONObject(dataIn);
    //parse individual datasets from main JSON object
    JSONObject results = nytData.getJSONObject("eegPower");
    JSONObject resultsM = nytData.getJSONObject("eSense");
    JSONObject rawData = nytData.getJSONObject("rawEeg");
    //JSONObject resultsB = nytData.getJSONObject("blinkStrength");
    if(DynamicRange){
      
      int delta = results.getInt("delta");
      int theta = results.getInt("theta");
      int lowAlpha = results.getInt("lowAlpha");
      int highAlpha = results.getInt("highAlpha");
      int lowBeta = results.getInt("lowBeta");
      int highBeta = results.getInt("highBeta");
      int lowGamma = results.getInt("lowGamma");
      int highGamma = results.getInt("highGamma");

    }else{
      int delta = results.getInt("delta");
      int theta = results.getInt("theta");
      int lowAlpha = results.getInt("lowAlpha");
      int highAlpha = results.getInt("highAlpha");
      int lowBeta = results.getInt("lowBeta");
      int highBeta = results.getInt("highBeta");
      int lowGamma = results.getInt("lowGamma");
      int highGamma = results.getInt("highGamma");
    
    }
    int attention = resultsM.getInt("attention");
    int meditation = resultsM.getInt("meditation");

    //SEND MIDI CONTRTOL
    midiBus.sendControllerChange(0, 3, attention);
    
    } catch (JSONException e) {
              if (Debug){
              println ("There was an error parsing the JSONObject.");
              println(e);
              }
    }
}
}

void keyPressed() {
  
if (Debug){
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
  
  } else {
    println("enable debug mode to view data in and modify format");
  }
}

void DebugMode(boolean theFlag) {
  if(theFlag==true) {
    Debug = true;
    println("DEBUG TOGGLE ON.");
  } else {
    Debug = false;
    println("DEBUG TOGGLE OFF.");
  }
}

void DynamicRangeMode(boolean theFlag) {
  if(theFlag==true) {
    DynamicRange = true;
    println("DYNAMIC RANGE TOGGLE ON.");
  } else {
    DynamicRange = false;
    println("DYNAMIC RANGE TOGGLE OFF.");
  }
}
