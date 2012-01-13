//
//  TCEventGraphController.h
//  thinkGearCocoa
//
//  Created by Ben Acland on 1/19/12.
//  Copyright (c) 2012 Ben Acland. All rights reserved.
//  See License.txt for details.
//

#import <Cocoa/Cocoa.h>
#import <CorePlot/CorePlot.h>
#import "TCReader.h"

@interface TCEventGraphController : NSViewController <CPTPlotDataSource>

- (void)startSession;
- (void)endSession;
- (void)addTCReadEvent:(TCReadEvent)readEvent;

@end
