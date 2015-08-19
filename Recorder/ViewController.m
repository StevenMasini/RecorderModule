//
//  ViewController.m
//  Recorder
//
//  Created by Steven Masini on 8/17/15.
//  Copyright (c) 2015 Steven Masini. All rights reserved.
//

#import "ViewController.h"
#import "RecorderModule.h"

#define degreesToRadians(x) x * M_PI / 180

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *containerViewBottomSpacingConstraint;

@property (assign, nonatomic) BOOL isRecorderClosed;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self.containerView];
    
    UIView *subview = [self.containerView hitTest:location withEvent:event];   
    if (!subview) {
        self.isRecorderClosed = !self.isRecorderClosed;
        CGFloat height = -1 * CGRectGetHeight(self.containerView.frame);
        self.containerViewBottomSpacingConstraint.constant = self.isRecorderClosed ? height : 0.0f;
        
        [UIView animateWithDuration:0.45f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self.view layoutIfNeeded];
        } completion:NULL];
    }
}

@end
