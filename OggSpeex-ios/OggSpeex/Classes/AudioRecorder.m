//
//  AudioRecorder.m
//  OggSpeex
//
//  Created by Jiang Chuncheng on 11/27/12.
//  Copyright (c) 2012 Sense Force. All rights reserved.
//

#import "AudioRecorder.h"

#define kNumberRecordBuffers	3
#define kBufferDurationSeconds  0.5

@interface AudioRecorder ()

- (void)setupAudioFormat;

void OnAudioQueueInputCallback(void *                                inUserData,
                               AudioQueueRef                         inAQ,
                               AudioQueueBufferRef                   inBuffer,
                               const AudioTimeStamp *                inStartTime,
                               UInt32                                inNumPackets,
                               const AudioStreamPacketDescription*	inPacketDesc);

- (int)computeRecordBufferSize:(const AudioStreamBasicDescription *)format time:(float)seconds;

@end

@implementation AudioRecorder {
    AudioQueueBufferRef audioQueueBufferRefs[kNumberRecordBuffers];
}

@synthesize recording;
@synthesize fileContainer;

- (id)init {
    if (self = [super init]) {
        prepared = NO;
    }
    return self;
}

- (void)prepareToRecord:(id<AudioFileContainerDelegate>)theFileContainer {
    prepared = YES;
    self.fileContainer = theFileContainer;
}

- (void)record {
    recording = YES;
    if ( ! prepared) {
        [self prepareToRecord:nil];
    }
    AudioQueueNewInput(&audioStreamBasicDescription, OnAudioQueueInputCallback, (__bridge void *)self, NULL, NULL, 0, &audioQueueRef);
    UInt32 ioDataSize = sizeof(audioStreamBasicDescription);
    AudioQueueGetProperty(audioQueueRef, kAudioQueueProperty_StreamDescription, &audioStreamBasicDescription, &ioDataSize);
    UInt32 inData = 1;
    AudioQueueSetProperty(audioQueueRef, kAudioQueueProperty_EnableLevelMetering, &inData, sizeof(inData));
    int bufferByteSize = [self computeRecordBufferSize:&audioStreamBasicDescription time:kBufferDurationSeconds];
    for (int i = 0; i < kNumberRecordBuffers; i++) {
        AudioQueueAllocateBuffer(audioQueueRef, bufferByteSize, &audioQueueBufferRefs[i]);
        AudioQueueEnqueueBuffer(audioQueueRef, audioQueueBufferRefs[i], 0, NULL);
    }
    AudioQueueStart(audioQueueRef, NULL);
}

- (void)stop {
    recording = NO;
}

- (void)setupAudioFormat {
    memset(&audioStreamBasicDescription, 0, sizeof(audioStreamBasicDescription));
    audioStreamBasicDescription.mFormatID = kAudioFormatLinearPCM;
    audioStreamBasicDescription.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    audioStreamBasicDescription.mBitsPerChannel = 16;
    audioStreamBasicDescription.mChannelsPerFrame = 1;
    audioStreamBasicDescription.mBytesPerFrame = (audioStreamBasicDescription.mBitsPerChannel / 8) * audioStreamBasicDescription.mChannelsPerFrame;
    audioStreamBasicDescription.mFramesPerPacket = 1;
    audioStreamBasicDescription.mBytesPerPacket = audioStreamBasicDescription.mBytesPerFrame * audioStreamBasicDescription.mFramesPerPacket;
    audioStreamBasicDescription.mSampleRate = 8000;
}

void OnAudioQueueInputCallback(void *                                inUserData,
                               AudioQueueRef                         inAQ,
                               AudioQueueBufferRef                   inBuffer,
                               const AudioTimeStamp *                inStartTime,
                               UInt32                                inNumPackets,
                               const AudioStreamPacketDescription*	inPacketDesc) {
    AudioRecorder *audioRecorder = (__bridge AudioRecorder *)inUserData;
    if (inNumPackets > 0) {
        [audioRecorder.fileContainer inputPCMDataFromBuffer:(unsigned char *)inBuffer->mAudioData size:inBuffer->mAudioDataByteSize];
        if (audioRecorder.recording) {
            AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
        }
    }
}

- (int)computeRecordBufferSize:(const AudioStreamBasicDescription *)format time:(float)seconds {
	int packets, frames, bytes = 0;
	@try {
		frames = (int)ceil(seconds * format->mSampleRate);
		
		if (format->mBytesPerFrame > 0)
			bytes = frames * format->mBytesPerFrame;
		else {
			UInt32 maxPacketSize;
			if (format->mBytesPerPacket > 0)
				maxPacketSize = format->mBytesPerPacket;	// constant packet size
			else {
				UInt32 propertySize = sizeof(maxPacketSize);
				AudioQueueGetProperty(audioQueueRef, kAudioQueueProperty_MaximumOutputPacketSize, &maxPacketSize, &propertySize);
			}
			if (format->mFramesPerPacket > 0)
				packets = frames / format->mFramesPerPacket;
			else
				packets = frames;	// worst-case scenario: 1 frame in a packet
			if (packets == 0)		// sanity check
				packets = 1;
			bytes = packets * maxPacketSize;
		}
	}
    @catch (NSException *exception) {
		NSLog(@"%@", exception);
		return 0;
	}	
	return bytes;
}

@end
