//
//  TCEventGraphController.m
//  thinkGearCocoa
//
//  Created by Ben Acland on 1/19/12.
//  Copyright (c) 2012 Ben Acland. All rights reserved.
//  See License.txt for details.
//

#import "TCEventGraphController.h"
#import "TCReader.h"

NSString *const TCEG_TIME_KEY = @"TCEG_TIME_KEY";
NSString *const TCEG_DATAPOINT_KEY = @"TCEG_DATAPOINT_KEY";

@interface TCEventGraphController () {
    CPTGraphHostingView *hostView_;
    CPTXYGraph *graph_;
    NSMutableArray *plotData;
    NSMutableArray *plotSpaces;
    NSArray *plotIdentifiers;
    NSTimeInterval mostRecentTime_;
    NSTimer *timer;
    NSArray *plotColors_;
}
@property (nonatomic, strong) CPTGraphHostingView *hostView;
@property (nonatomic, strong) CPTXYGraph *graph;
@property (nonatomic, strong) NSMutableArray *plotData;
@property (nonatomic, strong) NSMutableArray *plotSpaces;
@property (nonatomic, strong) NSArray *plotIdentifiers;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSArray *plotColors;
@end

@implementation TCEventGraphController
@synthesize hostView=hostView_;
@synthesize graph=graph_;
@synthesize plotData;
@synthesize plotSpaces;
@synthesize plotIdentifiers;
@synthesize timer;
@synthesize plotColors=plotColors_;

#pragma mark - Lifecycle

- (id)init {
    if (([super init])) {
        self.plotData = [[NSMutableArray alloc] init];
        self.plotSpaces = [[NSMutableArray alloc] init];
    }
    return self;
}


#pragma mark - View lifecycle

- (void)loadView {
    self.view = self.hostView;
    self.view.autoresizingMask = NSViewWidthSizable|NSViewHeightSizable;
    self.hostView.hostedGraph = self.graph;
}


#pragma mark - Graph building

- (void)updateMostRecentTime {
    mostRecentTime_ = [NSDate timeIntervalSinceReferenceDate];
    
    // reset the axis dimensions
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph_.defaultPlotSpace;
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(mostRecentTime_ - 20.)
                                                    length:CPTDecimalFromDouble(20.)];
    plotSpace.allowsUserInteraction = YES;
    [self.graph reloadData];
}

- (void)killTimer {
    [self.timer invalidate];
    self.timer = nil;
}

- (void)setupTimer {
    [self killTimer];
    [self updateMostRecentTime];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:.05
                                                  target:self
                                                selector:@selector(timerFired:)
                                                userInfo:nil
                                                 repeats:YES];
}

- (void)timerFired:(NSTimer*)timer {
    // update the x-axis range
    [self updateMostRecentTime];
}

- (void)startSession {
    // start the refresh timer going
    [self setupTimer];
    [self.graph reloadData];
}

- (void)endSession {
    // really, we just need to kill the timer
    [self killTimer];
}

- (void)addTCReadEvent:(TCReadEvent)readEvent {
    // unpack the record and append its results to the appropriate structures
    NSDecimalNumber *timeNumber = [[NSDecimalNumber alloc] initWithDouble:readEvent.dateReceived];

    for (int i = 0; i < TCReadEventGraphableComponentCount; i++) {
        double val = TCReadEventGetComponentValue(readEvent, i);

        // 0 -> no record
        if (val <= 0.f) {
            continue;
        }

        // get the plot
        CPTPlot *thePlot = [graph_ plotWithIdentifier:[self.plotSpaces objectAtIndex:i]];

        // build and insert the record
        NSMutableArray *records = [plotData objectAtIndex:i];

        [records addObject:[[NSDictionary alloc] initWithObjectsAndKeys:
                            [NSDecimalNumber numberWithDouble:val], TCEG_DATAPOINT_KEY,
                            timeNumber, TCEG_TIME_KEY,
                            nil]];
        [thePlot insertDataAtIndex:[records count] -1 numberOfRecords:1];

        // remove any records that happened more than 20s before now
        NSDecimalNumber *cutoffTime = [[NSDecimalNumber alloc] initWithDouble:[NSDate timeIntervalSinceReferenceDate] - 1000.];
        NSRange doomedRange = NSMakeRange(0, 0);
        for (int i=0; i < [records count]; i++) {
            NSDictionary *record = [records objectAtIndex:i];
            if ([cutoffTime isLessThan:[record objectForKey:TCEG_TIME_KEY]]) {
                break;
            }
            doomedRange.length += 1;
        }
        [records removeObjectsInRange:doomedRange];
        [thePlot deleteDataInIndexRange:doomedRange];
    }
    [self.graph reloadData];
}


#pragma mark CPTPlotDataSource

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot {
    NSInteger idx = [(NSNumber*)plot.identifier integerValue];
    return [(NSArray*)[plotData objectAtIndex:idx] count];
}

- (NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index {
    NSInteger componentInt = [(NSNumber*)plot.identifier integerValue];
    NSString *key = (fieldEnum == CPTScatterPlotFieldX) ? TCEG_TIME_KEY : TCEG_DATAPOINT_KEY;
    NSDecimalNumber *num = (NSDecimalNumber*)[[[plotData objectAtIndex:componentInt]
                                               objectAtIndex:index]
                                              objectForKey:key];
    return num;
}


#pragma mark - Self-inflating objects

- (CPTXYGraph *)graph {
    if (!graph_) {
        graph_ = [[CPTXYGraph alloc] initWithFrame:self.hostView.bounds];
        [graph_ applyTheme:[CPTTheme themeNamed:kCPTDarkGradientTheme]];

        // Grid line styles
        CPTMutableLineStyle *majorGridLineStyle = [CPTMutableLineStyle lineStyle];
        majorGridLineStyle.lineWidth = 0.75;
        majorGridLineStyle.lineColor = [[CPTColor colorWithGenericGray:0.2] colorWithAlphaComponent:0.75];
        
        CPTMutableLineStyle *minorGridLineStyle = [CPTMutableLineStyle lineStyle];
        minorGridLineStyle.lineWidth = 0.25;
        minorGridLineStyle.lineColor = [[CPTColor whiteColor] colorWithAlphaComponent:0.1];
        
        // axis padding and styles
        graph_.plotAreaFrame.paddingTop = 15.0;
        graph_.plotAreaFrame.paddingRight = 15.0;
        graph_.plotAreaFrame.paddingBottom = 55.0;
        graph_.plotAreaFrame.paddingLeft = 55.0;

        CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph_.axisSet;

        // X
        CPTXYAxis *x = axisSet.xAxis;
        x.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
        x.majorIntervalLength = CPTDecimalFromFloat(1.f);
        x.orthogonalCoordinateDecimal = CPTDecimalFromUnsignedInteger(0);
        x.majorGridLineStyle = majorGridLineStyle;
        x.minorGridLineStyle = minorGridLineStyle;
        x.minorTicksPerInterval = 9;
        x.title = @"X Axis";
        x.titleOffset = 35.0;
        NSNumberFormatter *labelFormatter = [[NSNumberFormatter alloc] init];
        labelFormatter.numberStyle = NSNumberFormatterNoStyle;
        x.labelFormatter = labelFormatter;

        // Y
        CPTXYAxis *y = axisSet.yAxis;
        y.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
        y.orthogonalCoordinateDecimal = CPTDecimalFromUnsignedInteger(0);
        y.majorGridLineStyle = majorGridLineStyle;
        y.minorGridLineStyle = minorGridLineStyle;
        y.minorTicksPerInterval = 3;
        y.labelOffset = 5.0;
        y.title = @"Y Axis";
        y.titleOffset = 30.0;
        y.axisConstraints = [CPTConstraints constraintWithLowerOffset:0.0];
        
        // flare
        y.labelRotation = M_PI * 0.5;
        
        // build the plots and warm the data structure
        NSMutableArray *newIdentifiers = [[NSMutableArray alloc] init];
        for (int i=0; i < TCReadEventGraphableComponentCount; i++) {
            // plot's backing data array will be in plotData[idx]
            [plotData addObject:[[NSMutableArray alloc] init]];

            // identifier obj will be a TCReadEventComponent -> NSNumber
            NSNumber *newIdObj = [[NSNumber alloc] initWithInteger:i];
            [newIdentifiers addObject:newIdObj];

            // the plot itself
            CPTScatterPlot *dataSourceLinePlot = [[CPTScatterPlot alloc] init];
            dataSourceLinePlot.identifier = newIdObj;
            dataSourceLinePlot.cachePrecision = CPTPlotCachePrecisionDouble;
            dataSourceLinePlot.bounds = CGRectMake(0, 0, 200, 100);
            [self.plotSpaces addObject:dataSourceLinePlot];
            
            CPTMutableLineStyle *lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];
            lineStyle.lineWidth = 3.0;
            lineStyle.lineColor = [self.plotColors objectAtIndex:i];
            dataSourceLinePlot.dataLineStyle = lineStyle;
            
            dataSourceLinePlot.dataSource = self;
            [graph_ addPlot:dataSourceLinePlot];
        }
        self.plotIdentifiers = newIdentifiers;
        
        // plot space initial configuration
        CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace*)graph_.defaultPlotSpace;
        NSTimeInterval epoch = [NSDate timeIntervalSinceReferenceDate];
        plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(epoch-20.f) length:CPTDecimalFromFloat(20.f)];
        plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.0) length:CPTDecimalFromFloat(102.)];
    }
    return graph_;
}

- (CPTGraphHostingView *)hostView {
    if (!hostView_) {
        hostView_ = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    }
    return hostView_;
}

- (NSArray *)plotColors {
    if (!plotColors_) {
        NSMutableArray *newColors = [[NSMutableArray alloc] initWithCapacity:TCReadEventGraphableComponentCount];
        for (int i=0; i < TCReadEventGraphableComponentCount; i++) {
            CPTColor *plotColor = nil;
            switch (i) {
                case TCReadEventComponentMeditation:
                    plotColor = [CPTColor cyanColor];
                    break;
                case TCReadEventComponentAttention:
                    plotColor = [CPTColor magentaColor];
                    break;
                case TCReadEventComponentDelta:
                    plotColor = [CPTColor brownColor];
                    break;
                case TCReadEventComponentTheta:
                    plotColor = [CPTColor orangeColor];
                    break;
                case TCReadEventComponentAlphaLow:
                    plotColor = [CPTColor grayColor];
                    break;
                case TCReadEventComponentAlphaHigh:
                    plotColor = [CPTColor grayColor];
                    break;
                case TCReadEventComponentBetaLow:
                    plotColor = [CPTColor blueColor];
                    break;
                case TCReadEventComponentBetaHigh:
                    plotColor = [CPTColor blueColor];
                    break;
                case TCReadEventComponentGammaLow:
                    plotColor = [CPTColor purpleColor];
                    break;
                case TCReadEventComponentGammaHigh:
                    plotColor = [CPTColor purpleColor];
                    break;
                default:
                    plotColor = [CPTColor greenColor];
                    break;
            }
            [newColors addObject:plotColor];
        }
        plotColors_ = newColors;
    }
    return plotColors_;
}

@end
