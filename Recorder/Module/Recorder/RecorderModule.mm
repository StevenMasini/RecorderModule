//
//  RecorderModule.m
//  Recorder
//
//  Created by Steven Masini on 8/17/15.
//  Copyright (c) 2015 Steven Masini. All rights reserved.
//

#import "RecorderModule.h"

#import <FAKFontAwesome.h>
#import "NSString+Reverse.h"
#import "MeterTable.h"

#define MAX_BAR_METRIC_NUMBER   14
#define MIN_DECIBEL_VALUE      -160

@interface RecorderModule () <AVAudioRecorderDelegate, AVAudioPlayerDelegate>
{
    MeterTable *_meterTable;
}

// views
@property (weak, nonatomic) IBOutlet UIView     *recorderContainerView;
@property (weak, nonatomic) IBOutlet UILabel    *recorderMicrophoneLabel;
@property (weak, nonatomic) IBOutlet UILabel    *recorderDurationLabel;
@property (weak, nonatomic) IBOutlet UIButton   *recorderPlayButton;
@property (weak, nonatomic) IBOutlet UIButton   *recorderDeleteButton;
@property (weak, nonatomic) IBOutlet UILabel    *recorderBarMetricLeftLabel;
@property (weak, nonatomic) IBOutlet UILabel    *recorderBarMetricsRightLabel;
@property (weak, nonatomic) IBOutlet UILabel    *recorderPressToRecordLabel;

// gestures
@property (strong, nonatomic) IBOutlet UILongPressGestureRecognizer *recorderLongPressGesture;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer       *recorderTapGesture;

// constraint
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *deleteHorizontalSpacingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *sendHorizontalSpacingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *sendCenterYAlignmentConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *deleteCenterYAlignmentConstraint;

// properties
@property (strong, nonatomic) AVAudioRecorder   *recorder;
@property (strong, nonatomic) AVAudioPlayer     *player;
@property (strong, nonatomic) NSTimer           *timerUpdateMetrics;
@property (strong, nonatomic) NSMutableArray    *metrics;
@property (assign, nonatomic) NSUInteger        metricIndex;

@end

@implementation RecorderModule

#pragma mark - UIViewController inherited methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 1) setup the user interface
    [self setupUserInterface];
    
    // 2) setup the recorder
    [self setupAudioRecorder];
    
    // 3) setup the bar metrics
    [self resetBarMetrics];
    [self updateMetricsLabels];
    
    // 4) localization
    self.recorderPressToRecordLabel.text = NSLocalizedString(@"Hold to record", nil);
}

#pragma mark - RecorderModule setup methods

- (void)setupUserInterface {
    self.sendHorizontalSpacingConstraint.constant   = -60.0f;
    self.deleteHorizontalSpacingConstraint.constant = -60.0f;
    self.sendCenterYAlignmentConstraint.constant    = 0.0f;
    self.deleteCenterYAlignmentConstraint.constant  = 0.0f;
    self.recorderPlayButton.alpha   = 0.0f;
    self.recorderDeleteButton.alpha = 0.0f;
    
    self.recorderContainerView.layer.cornerRadius   = CGRectGetWidth(self.recorderContainerView.frame) / 2.0f;
    self.recorderContainerView.layer.borderColor    = RGB(225, 225, 225).CGColor;
    self.recorderContainerView.layer.borderWidth    = 1.0f;
    
    self.recorderMicrophoneLabel.layer.cornerRadius = CGRectGetWidth(self.recorderMicrophoneLabel.frame) / 2.0f;
    
    self.recorderDeleteButton.layer.cornerRadius = CGRectGetWidth(self.recorderDeleteButton.frame) / 2.0f;
    self.recorderDeleteButton.layer.borderColor  = RGB(225, 225, 225).CGColor;
    self.recorderDeleteButton.layer.borderWidth  = 1.0f;
    
    self.recorderPlayButton.layer.cornerRadius   = CGRectGetWidth(self.recorderPlayButton.frame) / 2.0f;
    self.recorderPlayButton.layer.borderColor    = RGB(225, 225, 225).CGColor;
    self.recorderPlayButton.layer.borderWidth    = 1.0f;
}

- (void)setupAudioRecorder {
    
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        if (granted) {
            NSLog(@"AUTHORIZATION GRANTED");
            
            // 1) define the options
            NSDictionary *settings = @{AVFormatIDKey            : @(kAudioFormatLinearPCM),
                                       AVSampleRateKey          : @16000,
                                       AVNumberOfChannelsKey    : @2};
            // 2) init the recorder
            NSError *outError;
            self.recorder = [[AVAudioRecorder alloc] initWithURL:[self audioFileURL]
                                                        settings:settings
                                                           error:&outError];
            if (outError) {
                NSLog(@"RECORDER MODULE ERROR: %@", outError);
            }
            [self.recorder recordForDuration:10.0f];
            self.recorder.meteringEnabled = YES;
            self.recorder.delegate = self;
        } else {
            NSLog(@"AUTHORIZATION NOT GRANTED");
        }
    }];
}

- (void)setupRecordUpdateMetricsLoop {
    [self resetUpdateMetricsTimer];
    [self resetBarMetrics];
    self.timerUpdateMetrics = [NSTimer scheduledTimerWithTimeInterval:0.04f target:self selector:@selector(updateRecordMetrics) userInfo:nil repeats:YES];
}

- (void)setupPlayUpdateMetricLoop {
    [self resetUpdateMetricsTimer];
    [self resetBarMetrics];
    self.timerUpdateMetrics = [NSTimer scheduledTimerWithTimeInterval:0.04f target:self selector:@selector(updatePlayerMetrics) userInfo:nil repeats:YES];
}

#pragma mark - AVAudioRecorderDelegate

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    NSLog(@"SAVED");
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error {
    NSLog(@"ERROR: %@", error);
}

#pragma mark - AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    [self stopToPlay];
}

#pragma mark - RecorderModule update metrics

- (void)updateRecordMetrics {
    [self.recorder updateMeters];
    
    MeterTable *meterTable = new MeterTable(MIN_DECIBEL_VALUE);
    float value = meterTable->ValueAt([self.recorder averagePowerForChannel:0]);
    int rounded = floor(value * 20);
    
    if (self.metrics.count == MAX_BAR_METRIC_NUMBER && [self.metrics objectAtIndex:self.metricIndex] != nil) {
        [self.metrics replaceObjectAtIndex:self.metricIndex withObject:@(rounded)];
    } else {
        [self.metrics addObject:@(rounded)];
    }
    self.metricIndex = (self.metricIndex < MAX_BAR_METRIC_NUMBER - 1) ? self.metricIndex + 1 : 0;
    NSLog(@"%@", [self.metrics componentsJoinedByString:@" | "]);
    
    [self updateMetricsLabels];
    
    NSTimeInterval duration = self.recorder.currentTime;
    [self updateTimeDurationLabelWithDuration:duration];
    
    if (duration > 10) {
        [self stopToRecord];
        [self showSendAndDeleteButtons:YES];
        [self showPlayButtonWhetherRecordButton:YES];
        return;
    }
}

- (void)updatePlayerMetrics {
    [self.player updateMeters];
    
    MeterTable *meterTable = new MeterTable(MIN_DECIBEL_VALUE);
    float value = meterTable->ValueAt([self.player averagePowerForChannel:0]);
    int rounded = floor(value * 20);
    
    if (self.metrics.count == MAX_BAR_METRIC_NUMBER && [self.metrics objectAtIndex:self.metricIndex] != nil) {
        [self.metrics replaceObjectAtIndex:self.metricIndex withObject:@(rounded)];
    } else {
        [self.metrics addObject:@(rounded)];
    }
    self.metricIndex = (self.metricIndex < MAX_BAR_METRIC_NUMBER - 1) ? self.metricIndex + 1 : 0;
    NSLog(@"%@", [self.metrics componentsJoinedByString:@" | "]);
    
    [self updateMetricsLabels];
    
    NSTimeInterval duration = self.player.currentTime;
    [self updateTimeDurationLabelWithDuration:duration];
}

#pragma mark - RecorderModule update user interface

- (void)updateTimeDurationLabelWithDuration:(NSTimeInterval)duration {
    dispatch_queue_t queue = dispatch_queue_create("SETUP_TIME_DURATION", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(queue, ^{
        NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
        dateComponents.second = duration;
        NSDate *date = [[NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian] dateFromComponents:dateComponents];
        
        NSDateFormatter *dateFormatter = [NSDateFormatter new];
        dateFormatter.dateFormat = @"mm:ss";
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.recorderDurationLabel.text = [dateFormatter stringFromDate:date];
        });
    });
}

- (void)updateMetricsLabels {
    dispatch_queue_t queue = dispatch_queue_create("SETUP_BAR_METRIC", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(queue, ^{
        NSMutableString *rightString = [NSMutableString string];
        for (NSInteger i = 0; i < MAX_BAR_METRIC_NUMBER; i++) {
            if (i < self.metrics.count) {
                NSNumber *v = self.metrics[i];
                if (v.integerValue >= 10) {
                    [rightString appendString:@"9"];
                } else if (v.integerValue < 0){
                    [rightString appendString:@"0"];
                } else {
                    [rightString appendString:v.stringValue];
                }
            }
        }
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.recorderBarMetricsRightLabel.text  = rightString;
            self.recorderBarMetricLeftLabel.text    = [rightString reversedString];
        });
    });
}



#pragma mark - RecorderModule utils methods

- (NSURL *)audioFileURL {
    NSURL *cacheURL = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    NSURL *audioFileURL = [cacheURL URLByAppendingPathComponent:@"currentAudioRecording.caf"];
    return audioFileURL;
}

- (void)resetUpdateMetricsTimer {
    [self.timerUpdateMetrics invalidate];
    self.timerUpdateMetrics = nil;
}

- (void)resetBarMetrics {
    
    [self.metrics removeAllObjects];
    self.metrics = nil;
    
    self.metrics = [NSMutableArray array];
    for (NSInteger i = 0; i < MAX_BAR_METRIC_NUMBER; i++) {
        [self.metrics addObject:@0];
    }
}

#pragma mark - RecorderModule event methods

- (void)startToRecord {
    // 1) setup the device to be ready to record voice
    NSError *outError;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord error:&outError];
    if (outError) {
        NSLog(@"RECORDER MODULE ERROR: %@", outError);
        return;
    }
    
    // 2) set the audio session active when the app is in foreground
    [[AVAudioSession sharedInstance] setActive:YES error:&outError];
    if (outError) {
        NSLog(@"RECORDER MODULE ERROR: %@", outError);
        return;
    }
    
    NSLog(@"START RECORDING");
    
    // 3) change the button color
    self.recorderMicrophoneLabel.backgroundColor = RGB(27, 149, 211);
    
    // 4) launch the recorder
    [self.recorder prepareToRecord];
    [self.recorder record];
    
    // 5) launch the update meters
    [self setupRecordUpdateMetricsLoop];
    [self.timerUpdateMetrics fire];
}

- (void)stopToRecord {
    NSLog(@"STOP RECORDING");
    
    [self.recorder stop];
    [self resetUpdateMetricsTimer];
    
    // update the button color
    self.recorderMicrophoneLabel.backgroundColor = RGB(41, 181, 234);
    
    [self showPlayButtonWhetherRecordButton:YES];
    [self showSendAndDeleteButtons:YES];
}

- (void)startToPlay {
    
    NSURL *audioPathURL = [self audioFileURL];
    BOOL fileExist = [[NSFileManager defaultManager] fileExistsAtPath:audioPathURL.path];
    
    if (fileExist) {
        NSError *outError;
        self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:audioPathURL error:&outError];
        if (!outError) {
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:&outError];
            if (!outError) {
                NSLog(@"START PLAYING");
                
                // 1) change the button color
                self.recorderMicrophoneLabel.backgroundColor = RGB(27, 149, 211);
                
                // 2) setup properties
                self.player.delegate = self;
                self.player.meteringEnabled = YES;
                
                // 3) play the record
                [self.player prepareToPlay];
                [self.player play];
                
                // 4) launch the update meters
                [self setupPlayUpdateMetricLoop];
                [self.timerUpdateMetrics fire];
            }
        }
    }
}

- (void)stopToPlay {
    // update the button color
    self.recorderMicrophoneLabel.backgroundColor = RGB(41, 181, 234);
    
    [self resetUpdateMetricsTimer];
    
    if (self.player.isPlaying) {
        NSLog(@"STOP PLAYING");
        [self.player stop];
    }
}

#pragma mark - RecorderModule update user interface

- (void)showSendAndDeleteButtons:(BOOL)present {
    
    self.sendHorizontalSpacingConstraint.constant   = present ? 25.0f : -50.0f;
    self.deleteHorizontalSpacingConstraint.constant = present ? 25.0f : -50.0f;
    
    self.sendCenterYAlignmentConstraint.constant    = present ? 30.0f : 0.0f;
    self.deleteCenterYAlignmentConstraint.constant  = present ? 30.0f : 0.0f;
    [UIView animateWithDuration:0.25f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.recorderDeleteButton.alpha = present ? 1.0f : 0.0f;
        self.recorderPlayButton.alpha   = present ? 1.0f : 0.0f;;
        [self.view layoutIfNeeded];
    } completion:NULL];
}

- (void)showPlayButtonWhetherRecordButton:(BOOL)isPlayButton {
    
    if (isPlayButton) {
        FAKFontAwesome *icon = [FAKFontAwesome playCircleIconWithSize:84];
        self.recorderMicrophoneLabel.attributedText = icon.attributedString;
        self.recorderLongPressGesture.enabled   = NO;
        self.recorderTapGesture.enabled         = YES;
    } else {
        FAKFontAwesome *icon = [FAKFontAwesome microphoneIconWithSize:64.0f];
        self.recorderMicrophoneLabel.attributedText = icon.attributedString;
        self.recorderLongPressGesture.enabled   = YES;
        self.recorderTapGesture.enabled         = NO;
    }
}

#pragma mark - IBActions

- (IBAction)longPressRecordAction:(UILongPressGestureRecognizer *)sender {
    UIGestureRecognizerState state = sender.state;
    if (state == UIGestureRecognizerStateBegan) {
        [self startToRecord];
    } else if (state == UIGestureRecognizerStateEnded) {
        
        [self stopToRecord];
    }
}

- (IBAction)touchPlayAction:(id)sender {
    [self startToPlay];
}

- (IBAction)touchSendAction:(id)sender {
    NSURL *fileURL = [self audioFileURL];
    BOOL fileExist = [[NSFileManager defaultManager] fileExistsAtPath:fileURL.path];
    if (fileExist) {
        if (self.delegate && [self.delegate conformsToProtocol:@protocol(RecorderModuleDelegate)]) {
            [self.delegate recorderModule:self didRecordFileToSendAtPath:fileURL];
        }
    }
}

- (IBAction)touchDeleteAction:(id)sender {
    NSURL *audioPathURL = [self audioFileURL];
    BOOL fileExist = [[NSFileManager defaultManager] fileExistsAtPath:audioPathURL.path];
    if (fileExist) {
        // 1) delete the file, ignore the error, because the file will be overrided in any case
        [[NSFileManager defaultManager] removeItemAtURL:audioPathURL error:NULL];
        
        // 2) stop to play the record, if it was playing
        [self stopToPlay];
        
        // 3) reset the time duration, as long there no more record
        [self updateTimeDurationLabelWithDuration:0];
        
        // 4) dismiss the send and delete buttons
        [self showSendAndDeleteButtons:NO];
        
        // 5) reset the microphone icon on the main button
        [self showPlayButtonWhetherRecordButton:NO];
        
        // 6) reset the metrics array
        [self resetBarMetrics];
        [self updateMetricsLabels];
    }
}

@end
