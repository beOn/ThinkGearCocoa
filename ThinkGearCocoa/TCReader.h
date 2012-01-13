//
//  TCReader.h
//  ThinkGearCocoa
//
//  Created by Ben Acland on 1/12/12.
//  Copyright (c) 2012 Ben Acland. All rights reserved.
//  See License.txt for details.
//

#import <Foundation/Foundation.h>

////////////////////////////////
/// @name Types And Structures
////////////////////////////////

typedef enum {
    TCReaderDisconnected,
    TCReaderConnecting,
    TCReaderAuthorizing,
    TCReaderAuthorized,
    TCReaderConfiguring,
    TCReaderConnected,
} TCReaderConnectionState;


// keep this in sync with TCReaderConnectionState
extern NSString *const TCReaderConnectionState_toString[];

typedef struct {
    float poorSignal;
    float meditation;
    float attention;
    float delta;
    float theta;
    float alphaLow;
    float alphaHigh;
    float betaLow;
    float betaHigh;
    float gammaLow;
    float gammaHigh;
    float blinkStrength;
    NSTimeInterval dateReceived;
} TCReadEvent;


////////////////////////////////
/// @name Protocols
////////////////////////////////

@class TCReader;
@protocol TCReaderDelegate <NSObject>
@required
- (void)TCReaderDidReadEvent:(TCReadEvent)readEvent;
@optional
- (void)TCReaderConnectionStateDidChange:(TCReader*)reader;
@end


////////////////////////////////
/// @name Interface
////////////////////////////////

@interface TCReader : NSObject <NSStreamDelegate>

+ (TCReader *)instance;
+ (void)connectToReader;
+ (void)disconnectFromReader;

@property (nonatomic, readonly) TCReaderConnectionState connectionState;
@property (nonatomic, weak) id<TCReaderDelegate> delegate;
@end


////////////////////////////////
/// @name Utility Functions
////////////////////////////////

static inline TCReadEvent
TCReadEventMake(float poorSignal,
                float meditation,
                float attention,
                float delta,
                float theta,
                float alphaLow,
                float alphaHigh,
                float betaLow,
                float betaHigh,
                float gammaLow,
                float gammaHigh,
                float blinkStrength,
                NSTimeInterval dateReceived)
{
    TCReadEvent event;
    event.poorSignal = poorSignal;
    event.meditation = meditation;
    event.attention = attention;
    event.delta = delta;
    event.theta = theta;
    event.alphaLow = alphaLow;
    event.alphaHigh = alphaHigh;
    event.betaLow = betaLow;
    event.betaHigh = betaHigh;
    event.gammaLow = gammaLow;
    event.gammaHigh = gammaHigh;
    event.blinkStrength = blinkStrength;
    event.dateReceived = dateReceived;
    return event;
}

typedef enum {
    TCReadEventComponentMeditation,
    TCReadEventComponentAttention,
    TCReadEventComponentDelta,
    TCReadEventComponentTheta,
    TCReadEventComponentAlphaLow,
    TCReadEventComponentAlphaHigh,
    TCReadEventComponentBetaLow,
    TCReadEventComponentBetaHigh,
    TCReadEventComponentGammaLow,
    TCReadEventComponentGammaHigh,
    TCReadEventGraphableComponentCount, // keep this one after any line-graphable components
    TCReadEventComponentPoorSignal,
    TCReadEventComponentBlinkStrength,
    TCReadEventComponentDateReceived,
    TCReadEventComponentCount, // keep this one at the end
} TCReadEventComponent;

// keep this in sync with TCReadEventComponent
extern NSString *const TCReadEventComponent_toString[];

static inline double TCReadEventGetComponentValue(TCReadEvent event, TCReadEventComponent component) {
        double val = 0.;
    switch (component) {
        case TCReadEventComponentMeditation:
            val = (double)event.meditation;
            break;
        case TCReadEventComponentAttention:
            val = (double)event.attention;
            break;
        case TCReadEventComponentDelta:
            val = (double)event.delta;
            break;
        case TCReadEventComponentTheta:
            val = (double)event.theta;
            break;
        case TCReadEventComponentAlphaLow:
            val = (double)event.alphaLow;
            break;
        case TCReadEventComponentAlphaHigh:
            val = (double)event.alphaHigh;
            break;
        case TCReadEventComponentBetaLow:
            val = (double)event.betaLow;
            break;
        case TCReadEventComponentBetaHigh:
            val = (double)event.betaHigh;
            break;
        case TCReadEventComponentGammaLow:
            val = (double)event.gammaLow;
            break;
        case TCReadEventComponentGammaHigh:
            val = (double)event.gammaHigh;
            break;
        case TCReadEventComponentPoorSignal:
            val = (double)event.poorSignal;
            break;
        case TCReadEventComponentBlinkStrength:
            val = (double)event.blinkStrength;
            break;
        case TCReadEventComponentDateReceived:
            val = event.dateReceived;
            break;
        case TCReadEventGraphableComponentCount:
        default:
            break;
    }
    return val;
}
