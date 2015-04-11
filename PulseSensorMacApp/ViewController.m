//
//  ViewController.m
//  PulseSensorMacApp
//
//  Created by GrownYoda on 12/30/14.
//  Copyright (c) 2014 World Famous Electronics llc. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController


NSMutableArray *beatsHappenedTimeStampedArray;
NSMutableArray *beatQualifyArray;
int counter;

//  Vars for   - (void)PulseSensorFullCode
Boolean Pulse = false;
Boolean RealQualifiedBeat = false;
int PulseSensorValue;
int Signal;
int Trough = 512;
int Peak = 512;
int Threshold = 512;
int Amplitude = 100;

int beatsSampleCounter = 0;


/////////////////////////////////////
#pragma mark - Default Project Methods
/////////////////////////////////////
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //  For App Store
    
    
    //  Arduino Stuff
    // we don't have a serial port open yet
    serialFileDescriptor = -1;
    readThreadRunning = FALSE;
    
    // first thing is to refresh the serial port list
    [self refreshSerialList:@"Select a Serial Port"];
    
    
    //   Setup PS Interface Elements
    [self resetPulseSensorAlgoVariablesToDefault];
    
    //   Setup PS BPM Elements
    beatsHappenedTimeStampedArray = [@[@"0",@"0",@"0",@"0",@"0",@"0",@"0",@"0",@"0",@"0"]mutableCopy];
    beatQualifyArray = [@[@"0",@"0"]mutableCopy];
    beatQualifyArray[0]= [NSDate date];
    [levelBeatHappened setIntValue:0];
    
    
    // UI Stuff
    [self printArray];   // for debugging
    [labelHeart setTitleWithMnemonic:@"❤"];
    [labelHeart setAlphaValue:0.2];
    [level2 setIntValue:51];

        [self ArduinoHeartOff] ;
    
    
    
    
    
    
}

-(void) viewWillDisappear{
    // Safely disconnect
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}





/////////////////////////////////////
#pragma mark - Arduino Connection Stuff
/////////////////////////////////////
// open the serial port
//   - nil is returned on success
//   - an error message is returned otherwise
- (NSString *) openSerialPort: (NSString *)serialPortFile baud: (speed_t)baudRate {
    int success;
    
    // close the port if it is already open
    if (serialFileDescriptor != -1) {
        close(serialFileDescriptor);
        serialFileDescriptor = -1;
        
        // wait for the reading thread to die
        while(readThreadRunning);
        
        // re-opening the same port REALLY fast will fail spectacularly... better to sleep a sec
        sleep(0.5);
    }
    
    // c-string path to serial-port file
    const char *bsdPath = [serialPortFile cStringUsingEncoding:NSUTF8StringEncoding];
    
    // Hold the original termios attributes we are setting
    struct termios options;
    
    // receive latency ( in microseconds )
    unsigned long mics = 3;
    
    // error message string
    NSMutableString *errorMessage = nil;
    
    // open the port
    //     O_NONBLOCK causes the port to open without any delay (we'll block with another call)
    serialFileDescriptor = open(bsdPath, O_RDWR | O_NOCTTY | O_NONBLOCK );
    
    if (serialFileDescriptor == -1) {
        // check if the port opened correctly
        errorMessage = @"Error: couldn't open serial port";
    } else {
        // TIOCEXCL causes blocking of non-root processes on this serial-port
        success = ioctl(serialFileDescriptor, TIOCEXCL);
        if ( success == -1) {
            errorMessage = @"Error: couldn't obtain lock on serial port";
        } else {
            success = fcntl(serialFileDescriptor, F_SETFL, 0);
            if ( success == -1) {
                // clear the O_NONBLOCK flag; all calls from here on out are blocking for non-root processes
                errorMessage = @"Error: couldn't obtain lock on serial port";
            } else {
                // Get the current options and save them so we can restore the default settings later.
                success = tcgetattr(serialFileDescriptor, &gOriginalTTYAttrs);
                if ( success == -1) {
                    errorMessage = @"Error: couldn't get serial attributes";
                } else {
                    // copy the old termios settings into the current
                    //   you want to do this so that you get all the control characters assigned
                    options = gOriginalTTYAttrs;
                    
                    /*
                     cfmakeraw(&options) is equivilent to:
                     options->c_iflag &= ~(IGNBRK | BRKINT | PARMRK | ISTRIP | INLCR | IGNCR | ICRNL | IXON);
                     options->c_oflag &= ~OPOST;
                     options->c_lflag &= ~(ECHO | ECHONL | ICANON | ISIG | IEXTEN);
                     options->c_cflag &= ~(CSIZE | PARENB);
                     options->c_cflag |= CS8;
                     */
                    cfmakeraw(&options);
                    
                    // set tty attributes (raw-mode in this case)
                    success = tcsetattr(serialFileDescriptor, TCSANOW, &options);
                    if ( success == -1) {
                        errorMessage = @"Error: coudln't set serial attributes";
                    } else {
                        // Set baud rate (any arbitrary baud rate can be set this way)
                        success = ioctl(serialFileDescriptor, IOSSIOSPEED, &baudRate);
                        if ( success == -1) {
                            errorMessage = @"Error: Baud Rate out of bounds";
                        } else {
                            // Set the receive latency (a.k.a. don't wait to buffer data)
                            success = ioctl(serialFileDescriptor, IOSSDATALAT, &mics);
                            if ( success == -1) {
                                errorMessage = @"Error: coudln't set serial latency";
                            }
                        }
                    }
                }
            }
        }
    }
    
    // make sure the port is closed if a problem happens
    if ((serialFileDescriptor != -1) && (errorMessage != nil)) {
        close(serialFileDescriptor);
        serialFileDescriptor = -1;
    }
    
    return errorMessage;
}

// updates the textarea for incoming text by appending text
- (void)appendToIncomingText: (id) text {
    
    //
    [self receivedString:text];
    
    
    // add the text to the textarea
    NSAttributedString* attrString = [[NSMutableAttributedString alloc] initWithString: text];
    NSTextStorage *textStorage = [serialOutputArea textStorage];
    [textStorage beginEditing];
    [textStorage appendAttributedString:attrString];
    [textStorage endEditing];
    // [attrString release];
    
    // scroll to the bottom
    NSRange myRange;
    myRange.length = 1;
    myRange.location = [textStorage length];
    [serialOutputArea scrollRangeToVisible:myRange];
}

// This selector/function will be called as another thread...
//  this thread will read from the serial port and exits when the port is closed
- (void)incomingTextUpdateThread: (NSThread *) parentThread {
    
    
    // mark that the thread is running
    readThreadRunning = TRUE;
    
    const int BUFFER_SIZE = 100;
    char byte_buffer[BUFFER_SIZE]; // buffer for holding incoming data
    int numBytes=0; // number of bytes read during read
    NSString *text; // incoming text from the serial port
    
    // assign a high priority to this thread
    [NSThread setThreadPriority:1.0];
    
    // this will loop unitl the serial port closes
    while(TRUE) {
        // read() blocks until some data is available or the port is closed
        numBytes = read(serialFileDescriptor, byte_buffer, BUFFER_SIZE); // read up to the size of the buffer
        if(numBytes>0) {
            // create an NSString from the incoming bytes (the bytes aren't null terminated)
            text = [NSString stringWithCString:byte_buffer length:numBytes];
            
            // this text can't be directly sent to the text area from this thread
            //  BUT, we can call a selctor on the main thread.
            [self performSelectorOnMainThread:@selector(appendToIncomingText:)
                                   withObject:text
                                waitUntilDone:YES];
            
            [self receivedString:text];
            
         
            
        } else {
            break; // Stop the thread if there is an error
        }
    }
    
    // make sure the serial port is closed
    if (serialFileDescriptor != -1) {
        close(serialFileDescriptor);
        serialFileDescriptor = -1;
    }
    
    // mark that the thread has quit
    readThreadRunning = FALSE;
    
    // give back the pool
    //  [pool release];
}

- (void) refreshSerialList: (NSString *) selectedText {
    io_object_t serialPort;
    io_iterator_t serialPortIterator;
    
    // remove everything from the pull down list
    [serialListPullDown removeAllItems];
    
    // ask for all the serial ports
    IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching(kIOSerialBSDServiceValue), &serialPortIterator);
    
    // loop through all the serial ports and add them to the array
    while (serialPort = IOIteratorNext(serialPortIterator)) {
        [serialListPullDown addItemWithTitle:
         (__bridge NSString*)IORegistryEntryCreateCFProperty(serialPort, CFSTR(kIOCalloutDeviceKey),  kCFAllocatorDefault, 0)];
        IOObjectRelease(serialPort);
    }
    
    // add the selected text to the top
    [serialListPullDown insertItemWithTitle:selectedText atIndex:0];
    [serialListPullDown selectItemAtIndex:0];
    
    IOObjectRelease(serialPortIterator);
}

// action sent when serial port selected
- (IBAction) serialPortSelected: (id) cntrl {
    // open the serial port
    NSString *error = [self openSerialPort: [serialListPullDown titleOfSelectedItem] baud:[baudInputField intValue]];
    
    if(error!=nil) {
        [self refreshSerialList:error];
        [self appendToIncomingText:error];
    } else {
        [self refreshSerialList:[serialListPullDown titleOfSelectedItem]];
        [self performSelectorInBackground:@selector(incomingTextUpdateThread:) withObject:[NSThread currentThread]];
    }
}

// action from baud rate change
- (IBAction) baudAction: (id) cntrl {
    if (serialFileDescriptor != -1) {
        speed_t baudRate = [baudInputField intValue];
        
        // if the new baud rate isn't possible, refresh the serial list
        //   this will also deselect the current serial port
        if(ioctl(serialFileDescriptor, IOSSIOSPEED, &baudRate)==-1) {
            [self refreshSerialList:@"Error: Baud Rate out of bounds"];
            [self appendToIncomingText:@"Error: Baud Rate out of bounds"];
        }
    }
}

// action from refresh button
- (IBAction) refreshAction: (id) cntrl {
    [self refreshSerialList:@"Select a Serial Port"];
    
    // close serial port if open
    if (serialFileDescriptor != -1) {
        close(serialFileDescriptor);
        serialFileDescriptor = -1;
    }
}



// Old Code Hack Together With New
- (void) receivedString:(NSString *)rx {
   //   NSLog(@"Received string! %@", rx);
    
//    if ([rx hasPrefix:@"S"] ) {
//        NSString* cleanedString = [rx substringFromIndex:1];
//        
//        if ([cleanedString intValue] > 90 ) {
//         
//        
//            Signal = [cleanedString intValue];
//            [_level setIntValue:Signal];
//            [self PulseSensorFullCode:Signal];
//            
//        }
//    
//  
//    }
    
    if (!([rx hasPrefix:@"S"]) && (![rx  isEqual: @" "] ) ) {
        
   //     if ([rx hasPrefix:@"B"] ) {

            labelBPM2.stringValue = rx;

    //    }
        
//        NSLog(@"Not S or Space %@", rx);

//        NSString* cleanedString = [rx substringFromIndex:1];
        
//               [self ArduinoHeartOn];
        
        
        }

    if ([rx hasPrefix:@"B"] ) {
        
        NSLog(@"  BBB   Received string! %@", rx);

        NSString* cleanedString = [rx substringFromIndex:1];
        
        labelBPM2.stringValue = cleanedString;
      //  Signal = [cleanedString intValue];
      //  [_level setIntValue:Signal];
        
        [self ArduinoHeartOn];
        
        }
    }



/////////////////////////////////////
#pragma Pulse Sensor Algo Code
/////////////////////////////////////
- (void)PulseSensorFullCode: (int)PSValueToCalculate
{
    
    
    /// Find, set, keep Peak and Trough of Raw Pulse Sensor Signal
    
    Signal = PSValueToCalculate;
    
    //    NSString* myString = [[NSString stringWithFormat:@"Signal = %i", Signal]];
    //   [labelMultiLine setTitleWithMnemonic:myString];
    
    
    if (Signal < Trough){                        // T is the trough
        Trough = Signal;                         // keep track of lowest point in pulse wave
        
    }
    
    
    if((Signal > Threshold && Signal > Peak) ){       // thresh condition helps avoid noise
        Peak = Signal;                             // P is the peak
    }                                              // keep track of highest point in pulse wave
    
    
    // new edge case
    if (Signal < Peak && Signal > Threshold) {
        Amplitude = Peak - Trough;                 //  get Amp of Pulse Wave
        Threshold = Amplitude/2 + Trough;       // set the Thresholdat 50% of Amp
        Peak = Threshold;                          //reset for next time
        Trough = Threshold;
        
    }
    
    // //  NOW IT'S TIME TO LOOK FOR THE HEART BEAT
    // signal surges up in value every time there is a pulse
    
    if ((Signal > Threshold) && (Pulse == false)) {
        
        [self qualifyBeat];
        
        
        if (RealQualifiedBeat) {
            Pulse = true;      // Pulse Happened, set the Pulse flag
            [self beatDetectedDoInterfaceStuff];
            [self calculateBPM];
            [levelBeatHappened setIntValue:2];
            
        }
        
        
    }
    
    
    if (Signal < Threshold && Pulse == true) {
        
        //   if (Pulse == true) {
        
        //        [self blinkLEDPin4OFF];     // when the values are going down, the beat is over, turn off pin 13 LED
        [labelHeart setAlphaValue:0.2];
        [levelBeatHappened setIntValue:0];
        
        Pulse = false;                          // reset Pulse Flag
        Amplitude = Peak - Trough;                 //  get Amp of Pulse Wave
        Threshold = Amplitude/2 + Trough;       // set the Thresholdat 50% of Amp
        Peak = Threshold;                          //reset for next time
        Trough = Threshold;
    }
    
    
    
    // new edge case
    //   if (Signal > Threshold && Signal > Trough  && Pulse == true) {
    
    
    //      [self blinkLEDPin4OFF];     // when the values are going down, the beat is over, turn off pin 13 LED
    //           [labelHeart setAlphaValue:0.2];
    
    //      Pulse = false;                          // reset Pulse Flag
    //      Amplitude = Signal - Trough;  //NEW               //  get Amp of Pulse Wave
    //      Threshold = Amplitude/2 + Trough;       // set the Thresholdat 50% of Amp
    //    Peak = Threshold;                          //reset for next time
    //    Trough = Threshold;
    // }
    
    
    
    
    
    
    [self updateLabelsPulseSensorInterfaceElements];
    
    
}

-(void) beatDetectedDoInterfaceStuff{
    
    //    [self blinkLEDPin4ON];
    //
    [labelHeart setAlphaValue:1.0];
    [labelHeart setTextColor:[NSColor redColor]];
    [labelHeart setTitleWithMnemonic:@"❤"];
    [levelBeatHappened setIntValue:2];
    
    
}

-(void) qualifyBeat{
    
    static float timeBetweenBeats = 1.0;
    static float timeSinceLastBeat;
    beatQualifyArray[1]=[NSDate date];
    
    
    timeBetweenBeats = [beatQualifyArray[1] timeIntervalSinceDate:beatQualifyArray[0]];
    NSLog(@"timeBetweenBeats is = %f",timeBetweenBeats);
    
    //    if (timeBetweenBeats > timeSinceLastBeat+0.20  || timeBetweenBeats < timeSinceLastBeat-0.20 || timeBetweenBeats < 0.5 || timeBetweenBeats > 1.3) {
    if (timeBetweenBeats < 0.5 || timeBetweenBeats > 1.3) {
        RealQualifiedBeat = FALSE;
        NSLog(@"RealQualifiedBeat is FALSE");
    } else{
        RealQualifiedBeat = TRUE;
        NSLog(@"RealQualifiedBeat is TRUE");
        
    }
    timeSinceLastBeat = timeBetweenBeats;
    
    [beatQualifyArray replaceObjectAtIndex:0 withObject:beatQualifyArray[1]];
    //beatQualifyArray[0] = beatQualifyArray[1];
    
    
    
}

-(void) calculateBPM{
    float timeBetweenTenBeats;
    int BPM;
    int static lastBPM = 75;
    beatsSampleCounter++;
    
    NSLog(@"---Before Array Shift---");
    [self printArray];
    
    for (int i = 0; i <9; i++) {
        [beatsHappenedTimeStampedArray replaceObjectAtIndex:i withObject:beatsHappenedTimeStampedArray [i+1]];
    }
    
    NSLog(@"---After Array Shift---");
    [self printArray];
    
    beatsHappenedTimeStampedArray[9]=[NSDate date];
    
    NSLog(@"---Element 10 updated---");
    [self printArray];
    
    if (beatsSampleCounter > 9) {
        timeBetweenTenBeats = [beatsHappenedTimeStampedArray[9] timeIntervalSinceDate:beatsHappenedTimeStampedArray[0]];
        BPM = (60/timeBetweenTenBeats)*10;    //  (60/time of Last Ten Beats) x 10 = formual for BPM
        
        if (BPM > BPM+20 || BPM < BPM-20|| BPM > 160 || BPM < 54) {   //qualifies BPM for a grown-up
            [labelBPM setTitleWithMnemonic:[NSString stringWithFormat:@"%i",BPM]];
            [labelBPM setTextColor:[NSColor lightGrayColor]];
            
            //  [labelBPM setTitleWithMnemonic:[NSString stringWithFormat:@"BPM = %i", BPM]];
            //  [level2 setIntValue:BPM];
            
            //      [labelHeart setTitleWithMnemonic:@"--"];
            //      [labelHeart setTextColor:[UIColor lightGrayColor]];
        } else{
            
            [labelBPM setTextColor:[NSColor redColor]];
            [labelBPM setTitleWithMnemonic:[NSString stringWithFormat:@"%i",BPM]];
            
            [labelBPM setTitleWithMnemonic:[NSString stringWithFormat:@"BPM = %i", BPM]];
            [level2 setIntValue:BPM];
            
        }
        
        lastBPM = BPM;
        
    } else if (beatsSampleCounter <= 9){
        [labelBPM setTitleWithMnemonic:[NSString stringWithFormat:@"%i",beatsSampleCounter]];
        
    }
    
    NSLog(@"BPM = %i", BPM);
    
    
}

-(void) updateLabelsPulseSensorInterfaceElements{
    
    //  DEBUG
    //   NSLog(@"  Amp = %i,    Peak = %i,  Thresh = %i,  Signal = %i,  Trough = %i,  Pulse = %i  ", Amplitude, Peak,Threshold,Signal,Trough, Pulse);
    
    //    [labelAmplitude setText:[NSString stringWithFormat:@"Amp: %i",Amplitude]];
    //    [labelPeak setText:[NSString stringWithFormat:@"Peak: %i",Peak]];
    //    [labelThreshold setText:[NSString stringWithFormat:@"Thresh: %i",Threshold]];
    //    [labelTrough setText:[NSString stringWithFormat:@"Trough: %i",Trough]];
    //
    //    // Progress Bars Update
    //    [ progressBarAmp setProgress: Amplitude*0.001 ];
    //    [progressBarPeak setProgress: Peak*0.001];
    //    [progressBarThreshold setProgress:Threshold * 0.001];
    //    [progressBarTrough setProgress:Trough * 0.001];
}

-(void) printArray{
    
    NSLog(@"%@",[NSString stringWithFormat:@"%@",beatsHappenedTimeStampedArray]);
    
}

-(void) resetAllPulseSensorVariablesToZero{
    
    Trough = 0;
    Threshold = 0;
    Peak = 0;
    Amplitude= 0;
}

-(void) resetPulseSensorAlgoVariablesToDefault{
    
    Trough = 512;
    Peak = 512;
    Threshold = 512;
    Amplitude = 100;
    
}

-(void) pulseSensorReadingsResetTimer: (NSTimer*) timer {
    
    NSDate* lastBeatTime = beatQualifyArray[9];
    NSDate* timeNow = [NSDate date];
    NSDate* time7secondsEarlier = [timeNow dateByAddingTimeInterval:-7 ];
    
    if ([lastBeatTime isEqualToDate:[lastBeatTime earlierDate:time7secondsEarlier]]) {
        NSLog(@"lastBeatTime happened more then 7 seconds ago, reset PS Algo Vars");
        [self resetPulseSensorAlgoVariablesToDefault];
        
    }
    
    //    if ([time7secondsEarlier isEqualToDate:[lastBeatTime earlierDate:time7secondsEarlier]]) {
    //        NSLog(@"time7secondsEarlier Earlier");
    //
    //    }
    
    
}

-(void) resetBeatsHappenedTimeStampedArray{
    for (int i = 0; i<9; i++) {
        beatsHappenedTimeStampedArray[i]= @"0";
    }
    beatsSampleCounter = 0;
}

-(void) buttonResetPressed:(id)sender{
    [self resetPulseSensorAlgoVariablesToDefault];
}


// UI Stuff
-(void) ArduinoHeartOn{
    //
    
    [lableHeart2 setAlphaValue:1.0];
    [lableHeart2 setTextColor:[NSColor redColor]];
    [lableHeart2 setTitleWithMnemonic:@"❤"];
    [levelBeatHappened setIntValue:2];
    
    
}

-(void) ArduinoHeartOff{
    //
    
    [lableHeart2 setAlphaValue:0.2];
    [lableHeart2 setTextColor:[NSColor redColor]];
    [lableHeart2 setTitleWithMnemonic:@"❤"];
    [levelBeatHappened2 setIntValue:0];
    
}





@end
