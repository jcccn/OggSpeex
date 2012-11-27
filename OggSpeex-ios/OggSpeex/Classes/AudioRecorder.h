//
//  AudioRecorder.h
//  OggSpeex
//
//  Created by Jiang Chuncheng on 11/27/12.
//  Copyright (c) 2012 Sense Force. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "AudioFileContainerDelegate.h"

@interface AudioRecorder : NSObject {
    BOOL prepared;
    AudioStreamBasicDescription audioStreamBasicDescription;
    AudioQueueRef audioQueueRef;
}

@property (nonatomic, readonly) BOOL recording;
@property (nonatomic, strong) id<AudioFileContainerDelegate> fileContainer;

- (void)prepareToRecord:(id<AudioFileContainerDelegate>)theFileContainer;
- (void)record;
- (void)stop;

@end
