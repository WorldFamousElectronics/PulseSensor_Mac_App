![logo](https://avatars0.githubusercontent.com/u/7002937?v=3&s=200)

## Pulse Sensor Mac App 
This is repo for our Mac App. 
 **Download Pulse Sensor Mac App** <a href="https://itunes.apple.com/us/app/pulse-sensor/id974284569?ls=1&mt=12"> "Pulse Sensor Mac App"</a>
 
This App:
1. Beat's Heart Image to User's Live Heartbeat   
2. Show User's Pulse activity in realtime
3. Displays BPM
4. Allows for Serial Port selectiona. 

## Screen Shot
![ScreenShot](https://github.com/WorldFamousElectronics/PulseSensor_Mac_App/blob/master/pics/macappscreen.png) 


## Installation
1. Before running this program, install our <a href="https://https://github.com/WorldFamousElectronics/PulseSensor_Amped_Arduinor"> "Pulse Sensor Arduino Code"</a>

2.  Change Serial settings in Arduino App

Change:
```
// Regards Serial OutPut  -- Set This Up to your needs
static boolean serialVisual = true;   // Set to 'true' by Default. 

```
too:
```
// Regards Serial OutPut  -- Set This Up to your needs
static boolean serialVisual = false;   // Re-set to 'false' to sendDataToSerial instead. : ) 

```
That's it!.  Fire up this app. 
