//
//  TCAppDelegate.m
//  ThinkGearCocoaDemo
//
//  Created by Ben Acland on 1/16/12.
//  Copyright (c) 2012 Ben Acland. All rights reserved.
//  See License.txt for details.
//

#import "TCAppDelegate.h"

@implementation TCAppDelegate

@synthesize window = _window;
@synthesize mainVC;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // set up a view controller with a couple of buttons.
    self.mainVC = [[TCDMainViewController alloc] init];
    mainVC.view.frame = [self.window.contentView bounds];
    [self.window.contentView addSubview:mainVC.view];

    // this class will be the reader's delegate.
    [[TCReader instance] setDelegate:self];
}

#pragma mark - TCReaderDelegate

- (void)TCReaderDidReadEvent:(TCReadEvent)readEvent {
    [mainVC.graphController addTCReadEvent:readEvent];
    mainVC.poorSignalLabel.hidden = (readEvent.poorSignal < 1.f);
}

- (void)TCReaderConnectionStateDidChange:(TCReader *)reader {
    [self.mainVC.statusLabel setTitleWithMnemonic:TCReaderConnectionState_toString[reader.connectionState]];
}

@end
