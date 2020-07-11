//
//  ViewController.m
//  AVCaptureSessionVideoRecorder
//
//  Created by 钟凡 on 2019/10/31.
//  Copyright © 2019 钟凡. All rights reserved.
//

#import "ViewController.h"
#import "ZFVideoRecorder.h"
#import "ZFPreviewView.h"
#import "ZFOpenGLView.h"

@interface ViewController ()<ZFVideoRecorderDelegate>

@property (nonatomic, strong) ZFVideoRecorder *videoRecorder;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) IBOutlet ZFPreviewView *preview;
@property (nonatomic, strong) IBOutlet ZFOpenGLView *openglView;
@property (nonatomic, strong) ZFOpenGLView *testView;

@end


@implementation ViewController

- (IBAction)swapCamera:(UIButton *)sender {
    [sender setSelected:!sender.isSelected];
    if (sender.isSelected) {
        [_videoRecorder startRecord];
    }else {
        [_videoRecorder stopRecord];
    }
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
    
    _preview.videoPreviewLayer.session = self.videoRecorder.session;
    
    [self.videoRecorder startRecord];
    [self.videoRecorder setVideoOrientation:AVCaptureVideoOrientationPortrait];
    [self.videoRecorder swapFrontAndBackCameras];
    
//    _timer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(generateBuffer) userInfo:nil repeats:YES];
//    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
//    [_timer fire];
}
- (void)generateBuffer {
    int width = 1280;
    int height = 720;
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             @YES, kCVPixelBufferCGImageCompatibilityKey,
                             @YES, kCVPixelBufferCGBitmapContextCompatibilityKey, nil];
    CVPixelBufferRef pxbuffer = NULL;
    NSLog(@"generateBuffer");
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_24RGB, (__bridge CFDictionaryRef) options, &pxbuffer);
    size_t byteSize = width * height * 24;
    size_t bpr0 = CVPixelBufferGetBytesPerRowOfPlane(pxbuffer, 0);
    
    CVPixelBufferLockBaseAddress(pxbuffer,0);
    
    uint8_t *base_y = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pxbuffer, 0);
    for (int i = 0; i < bpr0 * 100; i++) {
        int src = 0xff0000;
        memcpy(base_y, &src, sizeof(int));
    }
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    //时间信息
    CMSampleTimingInfo timingInfo = {0};
    timingInfo.duration = kCMTimeInvalid;
    timingInfo.decodeTimeStamp = kCMTimeInvalid;
    timingInfo.presentationTimeStamp = kCMTimeInvalid;
    
    //获取视频信息
    CMVideoFormatDescriptionRef videoInfo = NULL;
    OSStatus result = CMVideoFormatDescriptionCreateForImageBuffer(NULL, pxbuffer, &videoInfo);
    if (result != noErr) {
        printf("get video format info: %d \n", (int)status);
    }
    
    //创建sampleBuffer
    CMSampleBufferRef sampleBuffer = NULL;
    result = CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault, pxbuffer, true, NULL, NULL, videoInfo, &timingInfo, &sampleBuffer);
    if (result != noErr) {
        printf("creat sample buffer: %d \n", (int)status);
    }
    NSParameterAssert(status == kCVReturnSuccess && sampleBuffer != NULL);
    CFRelease(pxbuffer);
    CFRelease(videoInfo);
    
    [_preview displaySampleBuffer:sampleBuffer];
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:_preview];
    CGPoint point = [_preview.videoPreviewLayer captureDevicePointOfInterestForPoint:location];
    [self.videoRecorder setFocusAtPoint:point];
    [self.videoRecorder setExposureAtPoint:point];
    _testView = [[ZFOpenGLView alloc] init];
    _testView.frame = _preview.frame;
    [self.view addSubview:_testView];
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
- (void)didReceivedVideoData:(ZFVideoRecorder *)videoRecorder data:(void *)data width:(int)width height:(int)height {
    [_openglView displayYUV420Data:data width:width height:height];
    [_testView displayYUV420Data:data width:width height:height];
}
@end
