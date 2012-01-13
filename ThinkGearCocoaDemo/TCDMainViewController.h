//
//  TCDMainViewController.h
//  thinkGearCocoa
//
//  Created by Ben Acland on 1/16/12.
//  Copyright (c) 2012 Ben Acland. All rights reserved.
//  See License.txt for details.
//

#import <Cocoa/Cocoa.h>
#import "TCReader.h"
#import "TCEventGraphController.h"

@interface TCDMainViewController : NSViewController {
    IBOutlet NSView *graphContainer_;
    TCEventGraphController *graphController;
}

@property (nonatomic, strong) TCEventGraphController *graphController;
@property (nonatomic, strong) IBOutlet NSTextField *statusLabel;
@property (nonatomic, strong) IBOutlet NSTextField *poorSignalLabel;

- (IBAction)connect:(id)sender;
- (IBAction)disconnect:(id)sender;

@end
