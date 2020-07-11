//
//  ZFPreviewView.m
//  AVCaptureSessionVideoRecorder
//
//  Created by 钟凡 on 2019/11/15.
//  Copyright © 2019 钟凡. All rights reserved.
//

#import "ZFPreviewView.h"

@interface ZFPreviewView()
@property(nonatomic,strong)AVSampleBufferDisplayLayer*displayLayer;
@end

@implementation ZFPreviewView

-(instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.displayLayer = [AVSampleBufferDisplayLayer layer];
        self.displayLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        [self.layer addSublayer:self.displayLayer];
    }
    return self;
}
+ (Class)layerClass {
    return [AVCaptureVideoPreviewLayer class];
}
- (AVCaptureVideoPreviewLayer *)videoPreviewLayer {
    return (AVCaptureVideoPreviewLayer *)self.layer;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.displayLayer.frame = self.bounds;
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
- (void)displaySampleBuffer:(CMSampleBufferRef)sampleBuffer {
    if (self.displayLayer.status == AVQueuedSampleBufferRenderingStatusFailed) {
        [self.displayLayer flush];
    }
    
    [self.displayLayer enqueueSampleBuffer:sampleBuffer];
}
@end
