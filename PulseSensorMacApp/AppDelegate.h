//
//  AppDelegate.h
//  PulseSensorMacApp
//
//  Created by GrownYoda on 12/30/14.
//  Copyright (c) 2014 World Famous Electronics llc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "ViewController.h"


@interface AppDelegate : NSObject <NSApplicationDelegate>
{
//  
//// Window
  NSWindow *window;
//
//// Matatino
//    Matatino *arduino;
//    
////  MISC
//    NSString* globalDeviceString;
//    
////  All UI Elements
//    IBOutlet NSTextField *myLabel;
//    IBOutlet NSTextField *labelMultiLine;
//    IBOutlet NSButton *buttonConnection;
//    IBOutlet NSLevelIndicator *level2;
//    IBOutlet NSLevelIndicator *levelBeatHappened;
//    IBOutlet NSTextField *labelHeart;
//    IBOutlet NSTextField *labelBPM;


    
}

- (IBAction)openClicked:(id)sender;

//// Window
////@property (assign) IBOutlet NSWindow *window;
//
////  UI Outlets
//@property (assign) IBOutlet NSLevelIndicator *level;
//@property (assign) IBOutlet NSPopUpButton *buttonPopUpOutlet;
//
////  UI Actoins
//- (IBAction)button1Pressed:(NSButton *)sender;
//- (IBAction)buttonPopUpAction:(id)sender;
//- (IBAction)buttonResetPressed:(id)sender;


@end

