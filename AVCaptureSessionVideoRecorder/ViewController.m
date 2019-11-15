//
//  ViewController.m
//  AVCaptureSessionVideoRecorder
//
//  Created by 钟凡 on 2019/10/31.
//  Copyright © 2019 钟凡. All rights reserved.
//

#import "ViewController.h"
#import "ZFVideoRecorder.h"
#import "ZFVideoView.h"
#import "ZFPreviewView.h"

@interface ViewController ()<ZFVideoRecorderDelegate>

@property (nonatomic, strong) ZFVideoRecorder *videoRecorder;
@property (nonatomic, strong) ZFPreviewView *preview;

@end


@implementation ViewController
- (IBAction)swapCamera:(UIButton *)sender {
    [sender setSelected:!sender.isSelected];
    [self.videoRecorder swapFrontAndBackCameras];
}
- (IBAction)changeVideoDimension:(UIButton *)sender {
    [sender setSelected:!sender.isSelected];
    if (sender.isSelected) {
        [self.videoRecorder setVideoDimension:AVCaptureSessionPresetLow];
    }else {
        [self.videoRecorder setVideoDimension:AVCaptureSessionPresetHigh];
    }
}
- (IBAction)setVideoMirrored:(UIButton *)sender {
    [sender setSelected:!sender.isSelected];
    [self.videoRecorder setVideoMirrored:sender.isSelected];
}
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    UIInterfaceOrientation orientation = UIApplication.sharedApplication.statusBarOrientationAnimationDuration;
    if (orientation == UIInterfaceOrientationPortrait) {
        [self.videoRecorder setVideoOrientation:AVCaptureVideoOrientationPortrait];
    }
    if (orientation == UIInterfaceOrientationLandscapeLeft) {
        [self.videoRecorder setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
    }
    if (orientation == UIInterfaceOrientationLandscapeRight) {
        [self.videoRecorder setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    _preview = [[ZFPreviewView alloc] init];
    _preview.videoPreviewLayer.session = self.videoRecorder.session;
    [self.view insertSubview:_preview atIndex:0];
    
    [self.videoRecorder startRecord];
    [self.videoRecorder setVideoOrientation:AVCaptureVideoOrientationPortrait];
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    _preview.frame = self.view.bounds;
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:_preview];
    CGPoint point = [_preview.videoPreviewLayer captureDevicePointOfInterestForPoint:location];
    [self.videoRecorder setFocusAtPoint:point];
    [self.videoRecorder setExposureAtPoint:point];
}
-(ZFVideoRecorder *)videoRecorder {
    if (_videoRecorder == nil) {
        _videoRecorder = [[ZFVideoRecorder alloc] init];
        _videoRecorder.delegate = self;
    }
    return _videoRecorder;
}
- (void)videoRecorder:(ZFVideoRecorder *)videoRecorder didRecoredVideoData:(CMSampleBufferRef)sampleBuffer {
    
}
@end
