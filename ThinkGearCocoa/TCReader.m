//
//  TCReader.m
//  ThinkGearCocoa
//
//  Created by Ben Acland on 1/12/12.
//  Copyright (c) 2012 Ben Acland. All rights reserved.
//  See License.txt for details.
//

#import "TCReader.h"

// keep this in sync with TCReaderConnectionState
NSString *const TCReaderConnectionState_toString[] = {
    @"TCReaderDisconnected",
    @"TCReaderConnecting",
    @"TCReaderAuthorizing",
    @"TCReaderAuthorized",
    @"TCReaderConfiguring",
    @"TCReaderConnected",
};

NSString *const TCReadEventComponent_toString[] = {
    @"TCReadEventComponentMeditation",
    @"TCReadEventComponentAttention",
    @"TCReadEventComponentDelta",
    @"TCReadEventComponentTheta",
    @"TCReadEventComponentAlphaLow",
    @"TCReadEventComponentAlphaHigh",
    @"TCReadEventComponentBetaLow",
    @"TCReadEventComponentBetaHigh",
    @"TCReadEventComponentGammaLow",
    @"TCReadEventComponentGammaHigh",
    @"TCReadEventGraphableComponentCount",
    @"TCReadEventComponentPoorSignal",
    @"TCReadEventComponentBlinkStrength",
    @"TCReadEventComponentDateReceived"
};

@interface TCReader () {
    __weak id<TCReaderDelegate> delegate_;
    TCReaderConnectionState connectionState_;
    NSInputStream *inStream_;
    NSOutputStream *outStream_;
}
@property (nonatomic, readwrite) TCReaderConnectionState connectionState;
@property (strong) NSInputStream *inStream;
@property (strong) NSOutputStream *outStream;
- (void)postConnectionStateChange;
- (void)postNewReadEvent:(TCReadEvent)newEvent;
//- (void)startBinaryParser;
//- (void)killBinaryParser;
@end

@implementation TCReader
@synthesize delegate=delegate_;
@synthesize connectionState=connectionState_;
@synthesize inStream=inStream_;
@synthesize outStream=outStream_;

#pragma mark - Class Methods

static TCReader *TCReaderInstance;

+ (TCReader*)instance {
    if (!TCReaderInstance) {
        /** we'll check again within a synchronized loop, to make sure this only
         happens once. */
        @synchronized(self) {
            if (!TCReaderInstance) {
                TCReaderInstance = [[TCReader alloc] init];
            }
        }
    }
    return TCReaderInstance;
}


#pragma mark - Lifecycle

- (id)init {
    if ((self = [super init])) {
        
    }

    return self;
}


#pragma mark - Reader Relations

- (void)connectToReader {
    /** this should be called rarely, and we don't want to start a new connection
     running if we've already got one. */
    @synchronized(self) {
        if (self.connectionState > TCReaderDisconnected) return;
        self.connectionState = TCReaderConnecting;

        // set up a binary parser to handle the socket's initial output
        // we'll skip this, since it doesn't yeild useful info
//        [self startBinaryParser];

        // setup the socket reader and writer
        NSInputStream *newInStream;
        NSOutputStream *newOutStream;
        NSHost *host = [NSHost hostWithAddress:@"127.0.0.1"];
        [NSStream getStreamsToHost:host
                              port:13854
                       inputStream:&newInStream
                      outputStream:&newOutStream];

        self.inStream = newInStream;
        self.outStream = newOutStream;

        inStream_.delegate = self;
        outStream_.delegate = self;

        [inStream_ scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [outStream_ scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

        [inStream_ open];
        [outStream_ open];
    }
}

- (void)disconnectFromReader {
    // kill the socket reader and writer
    [inStream_ close];
    self.inStream = nil;
    [outStream_ close];
    self.outStream = nil;
    self.connectionState = TCReaderDisconnected;
}

- (void)setConnectionState:(TCReaderConnectionState)connectionState {
    if (connectionState_ != connectionState) {
        connectionState_ = connectionState;
        [self postConnectionStateChange];
    }
}

+ (void)connectToReader {
    [[self instance] connectToReader];
}

+ (void)disconnectFromReader {
    [[self instance] disconnectFromReader];
}


#pragma mark - Parsing

- (void)handleStreamInput:(id)deSerialized {
    //sample:
    //'{"eSense":{"attention":64,"meditation":29},"eegPower":{"delta":65195,"theta":9965,"lowAlpha":7798,"highAlpha":5284,"lowBeta":25413,"highBeta":22141,"lowGamma":1339,"highGamma":1926},"poorSignalLevel":0}

    if (![deSerialized isKindOfClass:[NSDictionary class]]) {
        // we need a dictionary
        return;
    }
    NSDictionary *dict = (NSDictionary*)deSerialized;

    NSDictionary *eSenseDict = [dict objectForKey:@"eSense"];
    NSDictionary *powerDict = [dict objectForKey:@"eegPower"];

    TCReadEvent rEvent = TCReadEventMake([[dict objectForKey:@"poorSignalLevel"] floatValue],
                                         [[eSenseDict objectForKey:@"meditation"] floatValue],
                                         [[eSenseDict objectForKey:@"attention"] floatValue],
                                         [[powerDict objectForKey:@"delta"] floatValue],
                                         [[powerDict objectForKey:@"theta"] floatValue],
                                         [[powerDict objectForKey:@"lowAlpha"] floatValue],
                                         [[powerDict objectForKey:@"highAlpha"] floatValue],
                                         [[powerDict objectForKey:@"lowBeta"] floatValue],
                                         [[powerDict objectForKey:@"highBeta"] floatValue],
                                         [[powerDict objectForKey:@"lowGamma"] floatValue],
                                         [[powerDict objectForKey:@"highGamma"] floatValue],
                                         [[dict objectForKey:@"blinkStrength"] floatValue],
                                         [NSDate timeIntervalSinceReferenceDate]);

    // pass along the actual values here if you get some
    [self postNewReadEvent:rEvent];
}

//static void handleParsedFromBinaryStream(unsigned char extendedCodeLevel,
//                                  unsigned char code,
//                                  unsigned char valueLength,
//                                  const unsigned char *value,
//                                  void *customData ) {
//    if( extendedCodeLevel == 0 ) {
//        switch( code ) {
//                /* Haven't seen anything too helpful come through here, but in
//                 theory this would be the place to authenticate. */
//            default:
//                NSLog(@"EXCODE level: %d CODE: 0x%02X vLength: %d\n",
//                       extendedCodeLevel, code, valueLength );
//                NSLog(@"Data value(s):" );
//                for(int i=0; i<valueLength; i++ ) NSLog(@" %02X", value[i] & 0xFF );
//        }
//    }
//}
//
//- (void)startBinaryParser {
//    NSLog(@"%@", NSStringFromSelector(_cmd));
//    [self killBinaryParser];
//
//    THINKGEAR_initParser( &binaryParser_, TGSP_PARSER_TYPE_PACKETS,
//                         handleParsedFromBinaryStream, NULL );
//}
//
//- (void)killBinaryParser {
//    NSLog(@"%@", NSStringFromSelector(_cmd));
//    binaryParser_.state = TGSP_PARSER_STATE_NULL;
//    binaryParser_.lastByte = 0;
//}


#pragma mark - NSStreamDelegate

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    if (aStream.streamError) {
        if (self.connectionState > TCReaderDisconnected) {
            [self disconnectFromReader];
        }
        return;
    }
    if ([aStream isEqual:self.inStream] && eventCode == NSStreamEventHasBytesAvailable) {
        // once we get to this point, we're considering ourselves authorized.
        // hacky... but will fix later
        if (self.connectionState < TCReaderAuthorized) {
            self.connectionState = TCReaderAuthorized;
        }

        // read the bytes off the socket
        uint8_t buf[4000];
        NSInteger len = 0;
        len = [inStream_ read:buf maxLength:4000];
        if (len > 0) {
            // see if you can get some json
            NSError *error;
            NSData *inData = [[NSData alloc] initWithBytes:buf length:len];

            id deserialized = [NSJSONSerialization JSONObjectWithData:inData
                                                         options:NSJSONReadingAllowFragments
                                                           error:&error];

            if (error) {
                // noo - no json! let's feed the bytes to the binary parser
//                if (binaryParser_.state != TGSP_PARSER_STATE_NULL) {
//                    unsigned char *theBytes = (unsigned char *)[inData bytes];
//                    for (int i=0; i < [inData length]; i++) {
//                        THINKGEAR_parseByte(&binaryParser_, theBytes[i]);
//                    }
//                } else {
//                    NSLog(@"parsing error: %@", error);
//                }
                return;
            }
            else if (self.connectionState < TCReaderConnected) {
                // json!
                self.connectionState = TCReaderConnected;
//                [self killBinaryParser];
            }

            [self handleStreamInput:deserialized];
            return;
        } else {
            NSLog(@"Nothing in the buffer.");
        }
    }
    else if ([aStream isEqual:self.outStream] && eventCode == NSStreamEventHasSpaceAvailable) {
        if (self.connectionState == TCReaderConnecting) {
            self.connectionState = TCReaderAuthorizing;

            // send the session start request, then close the output stream
            NSString *outString = [[NSString alloc] initWithString:@"{\"appName\": \"ThinkGearCocoa\", \"appKey\": \"525414124b4c567c568d3a76cb8d735cbde03096\"}"];
            const uint8_t * rawString = (const uint8_t *)[outString UTF8String];
            const char *ls = [outString UTF8String];
            [outStream_ write:rawString maxLength:strlen(ls)];
        } else {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                // wait till you're done with the authorization attempt, then configure
                while (self.connectionState == TCReaderAuthorizing) {
                    usleep(1000000);
                }

                if (self.connectionState != TCReaderAuthorized) {
                    // we don't wanna set prefs if we didn't get authorized
                    return;
                }

                self.connectionState = TCReaderConfiguring;
                NSString *outString = [[NSString alloc] initWithString:@"{\"format\": \"Json\"}"];
                const uint8_t * rawString = (const uint8_t *)[outString UTF8String];
                const char *ls = [outString UTF8String];
                [outStream_ write:rawString maxLength:strlen(ls)];
                [outStream_ close];
                self.outStream = nil;
            });
        }
    }
}


#pragma mark - Posting Notification

- (void)postConnectionStateChange {
    if (!self.delegate || ![self.delegate respondsToSelector:@selector(TCReaderConnectionStateDidChange:)])
        return;

    if (![[NSThread currentThread] isEqual:[NSThread mainThread]]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self postConnectionStateChange];
        });
        return;
    }
    [self.delegate TCReaderConnectionStateDidChange:self];
}

- (void)postNewReadEvent:(TCReadEvent)newEvent {
    if (!self.delegate)
        return;

    if (![[NSThread currentThread] isEqual:[NSThread mainThread]]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self postNewReadEvent:newEvent];
        });
        return;
    }
    [self.delegate TCReaderDidReadEvent:newEvent];
}

#pragma mark - Singleton Memory Management

- (id)copyWithZone:(NSZone *)zone { return self; }
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
