//
//  TCAppDelegate.h
//  ThinkGearCocoaDemo
//
//  Created by Ben Acland on 1/16/12.
//  Copyright (c) 2012 Ben Acland. All rights reserved.
//  See License.txt for details.
//

#import <Cocoa/Cocoa.h>
#import "TCDMainViewController.h"

@interface TCAppDelegate : NSObject <NSApplicationDelegate, TCReaderDelegate> {
    TCDMainViewController *mainVC;
    NSWindow *_window;
}

@property (nonatomic, retain) IBOutlet NSWindow *window;
@property (nonatomic, retain) TCDMainViewController *mainVC;

@end
