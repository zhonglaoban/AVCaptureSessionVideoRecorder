//
//  ZFPreviewView.m
//  AVCaptureSessionVideoRecorder
//
//  Created by 钟凡 on 2019/11/15.
//  Copyright © 2019 钟凡. All rights reserved.
//

#import "ZFPreviewView.h"

@implementation ZFPreviewView

+ (Class)layerClass {
    return [AVCaptureVideoPreviewLayer class];
}
- (AVCaptureVideoPreviewLayer *)videoPreviewLayer {
    return (AVCaptureVideoPreviewLayer *)self.layer;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    switch (orientation) {
        case UIInterfaceOrientationUnknown:
            break;
        case UIInterfaceOrientationPortrait:
            [self.videoPreviewLayer.connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            [self.videoPreviewLayer.connection setVideoOrientation:AVCaptureVideoOrientationPortraitUpsideDown];
            break;
        case UIInterfaceOrientationLandscapeLeft:
            [self.videoPreviewLayer.connection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
            break;
        case UIInterfaceOrientationLandscapeRight:
            [self.videoPreviewLayer.connection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
            break;
    }
}
@end
