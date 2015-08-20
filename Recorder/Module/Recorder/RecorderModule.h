//
//  RecorderModule.h
//  Recorder
//
//  Created by Steven Masini on 8/17/15.
//  Copyright (c) 2015 Steven Masini. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>

#define RGB(_r_, _g_, _b_) [UIColor colorWithRed:(float)_r_/255. green:(float)_g_/255. blue:(float)_b_/255. alpha:1.0]

@protocol RecorderModuleDelegate;

@interface RecorderModule : UIViewController
@property (nonatomic, assign) id<RecorderModuleDelegate>delegate;
@end

@protocol RecorderModuleDelegate <NSObject>

- (void)recorderModule:(RecorderModule *)recorderModule didRecordFileToSendAtPath:(NSURL *)filePathURL;

@end
