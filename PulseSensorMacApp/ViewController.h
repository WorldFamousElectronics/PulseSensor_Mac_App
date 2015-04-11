//
//  ViewController.h
//  PulseSensorMacApp
//
//  Created by GrownYoda on 12/30/14.
//  Copyright (c) 2014 World Famous Electronics llc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/serial/IOSerialKeys.h>
#include <IOKit/IOBSD.h>
#include <IOKit/serial/ioss.h>
#include <sys/ioctl.h>


@interface ViewController : NSViewController
{
 
    // Pulse Sensor Related
    IBOutlet NSLevelIndicator *levelBeatHappened;
    IBOutlet NSLevelIndicator *level2;
    IBOutlet NSTextField *labelHeart;
    IBOutlet NSTextField *lableHeart2;
    IBOutlet NSTextFieldCell *levelBeatHappened2;
    IBOutlet NSTextField *labelBPM;
    IBOutlet NSTextField *labelBPM2;
    
    
    //  Arduino Connection Stuff
    IBOutlet NSPopUpButton *serialListPullDown;
    IBOutlet NSTextView *serialOutputArea;
    IBOutlet NSTextField *baudInputField;
    int serialFileDescriptor; // file handle to the serial port
    struct termios gOriginalTTYAttrs; // Hold the original termios attributes so we can reset them on quit ( best practice )
    bool readThreadRunning;
    NSTextStorage *storage;
    
    


   


}

// Pulse Sensor Related
- (IBAction)buttonResetPressed:(id)sender;
@property (assign) IBOutlet NSLevelIndicator *level;



// Arduino Connection Stuff
- (NSString *) openSerialPort: (NSString *)serialPortFile baud: (speed_t)baudRate;
- (void)appendToIncomingText: (id) text;
- (void)incomingTextUpdateThread: (NSThread *) parentThread;
- (void) refreshSerialList: (NSString *) selectedText;

- (IBAction) serialPortSelected: (id) cntrl;
- (IBAction) baudAction: (id) cntrl;
- (IBAction) refreshAction: (id) cntrl;
//- (IBAction) resetButton: (NSButton *) btn;

// UI Stuff







@end

