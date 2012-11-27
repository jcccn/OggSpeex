//
//  AudioFileContainerDelegate.h
//  OggSpeex
//
//  Created by Jiang Chuncheng on 11/28/12.
//  Copyright (c) 2012 Sense Force. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AudioFileContainerDelegate <NSObject>

- (void)inputPCMDataFromBuffer:(Byte *)buffer size:(UInt32)dataSize;

@end
