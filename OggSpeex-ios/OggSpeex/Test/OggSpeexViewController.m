//
//  OggSpeexViewController.m
//  OggSpeex
//
//  Created by Jiang Chuncheng on 6/25/13.
//  Copyright (c) 2013 Sense Force. All rights reserved.
//

#import "OggSpeexViewController.h"
#import "RecorderManager.h"
#import "PlayerManager.h"

@interface OggSpeexViewController () <RecordingDelegate, PlayingDelegate>

@property (nonatomic, weak) IBOutlet UIProgressView *levelMeter;
@property (nonatomic, weak) IBOutlet UILabel *consoleLabel;
@property (nonatomic, weak) IBOutlet UIButton *recordButton;
@property (nonatomic, weak) IBOutlet UIButton *playButton;

@property (nonatomic, assign) BOOL isRecording;
@property (nonatomic, assign) BOOL isPlaying;

@property (nonatomic, copy) NSString *filename;

- (IBAction)recordButtonClicked:(id)sender;
- (IBAction)playButtonClicked:(id)sender;

@end

@implementation OggSpeexViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self addObserver:self forKeyPath:@"isRecording" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];
    [self addObserver:self forKeyPath:@"isPlaying" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];
	
    self.title = @"Speex";
    
    self.levelMeter.progress = 0;
    
    self.consoleLabel.numberOfLines = 0;
    self.consoleLabel.text = @"A demo for recording and playing speex audio.";
    
    [self.recordButton addTarget:self action:@selector(recordButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.playButton addTarget:self action:@selector(playButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"isRecording"];
    [self removeObserver:self forKeyPath:@"isPlaying"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"isRecording"]) {
        [self.recordButton setTitle:(self.isRecording ? @"停止录音" : @"录音") forState:UIControlStateNormal];
    }
    else if ([keyPath isEqualToString:@"isPlaying"]) {
        [self.playButton setTitle:(self.isPlaying ? @"停止播放" : @"播放") forState:UIControlStateNormal];
    }
}

- (IBAction)recordButtonClicked:(id)sender {
    if (self.isPlaying) {
        return;
    }
    if ( ! self.isRecording) {
        self.isRecording = YES;
        self.consoleLabel.text = @"正在录音";
        [RecorderManager sharedManager].delegate = self;
        [[RecorderManager sharedManager] startRecording];
    }
    else {
        self.isRecording = NO;
        [[RecorderManager sharedManager] stopRecording];
    }
}

- (IBAction)playButtonClicked:(id)sender {
    if (self.isRecording) {
        return;
    }
    if ( ! self.isPlaying) {
        [PlayerManager sharedManager].delegate = nil;
        
        self.isPlaying = YES;
        self.consoleLabel.text = [NSString stringWithFormat:@"正在播放: %@", [self.filename substringFromIndex:[self.filename rangeOfString:@"Documents"].location]];
        [[PlayerManager sharedManager] playAudioWithFileName:self.filename delegate:self];
    }
    else {
        self.isPlaying = NO;
        [[PlayerManager sharedManager] stopPlaying];
    }
}

#pragma mark - Recording & Playing Delegate

- (void)recordingFinishedWithFileName:(NSString *)filePath time:(NSTimeInterval)interval {
    self.isRecording = NO;
    self.levelMeter.progress = 0;
    self.filename = filePath;
    [self.consoleLabel performSelectorOnMainThread:@selector(setText:)
                                        withObject:[NSString stringWithFormat:@"录音完成: %@", [self.filename substringFromIndex:[self.filename rangeOfString:@"Documents"].location]]
                                     waitUntilDone:NO];
}

- (void)recordingTimeout {
    self.isRecording = NO;
    self.consoleLabel.text = @"录音超时";
}

- (void)recordingStopped {
    self.isRecording = NO;
}

- (void)recordingFailed:(NSString *)failureInfoString {
    self.isRecording = NO;
    self.consoleLabel.text = @"录音失败";
}

- (void)levelMeterChanged:(float)levelMeter {
    self.levelMeter.progress = levelMeter;
}

- (void)playingStoped {
    self.isPlaying = NO;
    self.consoleLabel.text = [NSString stringWithFormat:@"播放完成: %@", [self.filename substringFromIndex:[self.filename rangeOfString:@"Documents"].location]];
}

@end
