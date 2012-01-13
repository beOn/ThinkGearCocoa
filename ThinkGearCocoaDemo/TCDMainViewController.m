//
//  TCDMainViewController.m
//  thinkGearCocoa
//
//  Created by Ben Acland on 1/16/12.
//  Copyright (c) 2012 Ben Acland. All rights reserved.
//  See License.txt for details.
//

#import "TCDMainViewController.h"

@implementation TCDMainViewController
@synthesize graphController;
@synthesize statusLabel;
@synthesize poorSignalLabel;

#pragma mark - Lifecycle

- (id)init {
    if ((self = [super initWithNibName:@"TCDMainViewController" bundle:nil])) {
        // nothing for now
    }

    return self;
}

- (void)loadView {
    [super loadView];
    self.graphController = [[TCEventGraphController alloc] init];
    self.graphController.view.frame = graphContainer_.bounds;
    [graphContainer_ addSubview:self.graphController.view];
}

#pragma mark - Button actions

- (IBAction)connect:(id)sender {
    [self.graphController startSession];
    [TCReader connectToReader];
}

- (IBAction)disconnect:(id)sender {
    [self.graphController endSession];
    self.poorSignalLabel.hidden = YES;
    [TCReader disconnectFromReader];
}

@end
