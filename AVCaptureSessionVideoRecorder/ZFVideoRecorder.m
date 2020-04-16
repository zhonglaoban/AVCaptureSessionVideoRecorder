//
//  ZFVideoRecorder.m
//  AVCaptureSessionVideoRecorder
//
//  Created by 钟凡 on 2019/11/7.
//  Copyright © 2019 钟凡. All rights reserved.
//

#import "ZFVideoRecorder.h"
#import <UIKit/UIKit.h>
#include "libyuv/libyuv.h"

@interface ZFVideoRecorder()<AVCaptureVideoDataOutputSampleBufferDelegate>

//@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureConnection *videoConnection;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
@property (nonatomic, assign) AVCaptureDevicePosition devicePosition;
@property (nonatomic, assign) AVCaptureVideoOrientation orientation;
@property (nonatomic, assign) AVCaptureSessionPreset preset;
@property (nonatomic, assign) BOOL isMirrored;
@property (nonatomic) dispatch_queue_t queue;

@end


@implementation ZFVideoRecorder

- (instancetype)init
{
    if (self = [super init]) {
        _queue = dispatch_queue_create("zf.videoRecorder", DISPATCH_QUEUE_SERIAL);
        _session = [[AVCaptureSession alloc] init];
        _devicePosition = AVCaptureDevicePositionBack;
        _isMirrored = NO;
        _orientation = AVCaptureVideoOrientationPortrait;
        dispatch_async(_queue, ^{
            [self configureSession];
        });
        [self setVideoOutputFormatType];
        [self setVideoFrameDuration];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(detectAndSetOrientation) name:UIDeviceOrientationDidChangeNotification object:nil];
    }
    
    return self;
}
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
// Call this on the session queue.
- (void)configureSession
{
    NSError *error = nil;
    //输入设备
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    
    //数据输出
    AVCaptureVideoDataOutput *videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    [videoOutput setSampleBufferDelegate:self queue:_queue];
    
    if (error) {
        NSLog(@"Error getting video input device: %@", error.description);
        return;
    }
    [self.session beginConfiguration];
    // 添加输入
    if ([self.session canAddInput:videoInput]) {
        [self.session addInput:videoInput];
        self.videoInput = videoInput;
    }
    // 添加输出
    if ([self.session canAddOutput:videoOutput]) {
        [self.session addOutput:videoOutput];
        self.videoOutput = videoOutput;
    }
    [self.session commitConfiguration];
    
    //获取videoConnection
    self.videoConnection = [self getVideoConnection];
}
- (void)startRecord {
    [self checkVideoAuthorization:^(int code, NSString *message) {
        NSLog(@"checkVideoAuthorization code: %d, message: %@", code, message);
    }];
    dispatch_async(_queue, ^{
        [self.session startRunning];
    });
}
- (void)stopRecord {
    dispatch_async(_queue, ^{
        [self.session stopRunning];
    });
}
- (void)setVideoFrameDuration {
    dispatch_async(_queue, ^{
        NSError *error;
        AVCaptureDevice *videoDevice = [self videoDeviceWitchPosition:self.devicePosition];
        
        [videoDevice lockForConfiguration: &error];
        [videoDevice setActiveVideoMinFrameDuration:CMTimeMake(1, 15)];
        [videoDevice setActiveVideoMaxFrameDuration:CMTimeMake(1, 15)];
        [videoDevice unlockForConfiguration];
    });
}
- (void)setVideoOutputFormatType {
    dispatch_async(_queue, ^{
        NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithUnsignedInteger:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange],
                                  kCVPixelBufferPixelFormatTypeKey, nil];
        self.videoOutput.videoSettings = settings;
    });
}
- (AVCaptureConnection *)getVideoConnection {
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in [_videoOutput connections])
    {
        for (AVCaptureInputPort *port in [connection inputPorts])
        {
            if ([[port mediaType] isEqual:AVMediaTypeVideo])
            {
                videoConnection = connection;
            }
        }
    }
    return videoConnection;
}
- (void)detectAndSetOrientation  {
    UIInterfaceOrientation statusBarOrientation = UIApplication.sharedApplication.statusBarOrientation;
    AVCaptureVideoOrientation captureOrientation = AVCaptureVideoOrientationPortrait;
    if (statusBarOrientation == UIInterfaceOrientationLandscapeLeft) {
        captureOrientation = AVCaptureVideoOrientationLandscapeRight;
    }else if (statusBarOrientation == UIInterfaceOrientationLandscapeRight) {
        captureOrientation = AVCaptureVideoOrientationLandscapeLeft;
    }else {
        captureOrientation = AVCaptureVideoOrientationPortrait;
    }
    [self setVideoOrientation:captureOrientation];
}
#pragma mark - public functions
//切换前后摄像头
- (void)swapFrontAndBackCameras
{
    dispatch_async(_queue, ^{
        NSError *error = nil;
        if (self.devicePosition == AVCaptureDevicePositionFront) {
            self.devicePosition = AVCaptureDevicePositionBack;
        }else {
            self.devicePosition = AVCaptureDevicePositionFront;
        }
        AVCaptureDevice *videoDevice = [self videoDeviceWitchPosition:self.devicePosition];
        
        [self.session beginConfiguration];
        // 移除输入
        [self.session removeInput:self.videoInput];
        // 获取新的输入
        self.videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
        if (!self.videoInput || error) {
            NSLog(@"Could not create video device input: %@", error);
            return;
        }
        // 添加输入
        if ([self.session canAddInput:self.videoInput]) {
            [self.session addInput:self.videoInput];
        }
        [self.session commitConfiguration];
        
        //获取videoConnection
        self.videoConnection = [self getVideoConnection];
    });
    [self setVideoOrientation:_orientation];
    [self setVideoDimension:_preset];
    [self setVideoMirrored:_isMirrored];
}
//设置采集分辨率
- (void)setVideoDimension:(AVCaptureSessionPreset)preset
{
    _preset = preset;
    dispatch_async(_queue, ^{
        [self.session beginConfiguration];
        if ([self.session canSetSessionPreset:preset]) {
            [self.session setSessionPreset:preset];
        };
        [self.session commitConfiguration];
    });
}
//设置视频采集方向
- (void)setVideoOrientation:(AVCaptureVideoOrientation)orientation
{
    _orientation = orientation;
    dispatch_async(_queue, ^{
        self.videoConnection.videoOrientation = orientation;
    });
}
//设置是否镜像
- (void)setVideoMirrored:(BOOL)isMirrored
{
    _isMirrored = isMirrored;
    dispatch_async(_queue, ^{
        self.videoConnection.videoMirrored = isMirrored;
    });
}
//设置对焦
- (void)setFocusAtPoint:(CGPoint)point
{
    dispatch_async(_queue, ^{
        NSError *error;
        AVCaptureDevice *videoDevice = self.videoInput.device;

        [videoDevice lockForConfiguration:&error];
        if ([videoDevice isFocusPointOfInterestSupported]) {
            videoDevice.focusPointOfInterest = point;
            videoDevice.focusMode = AVCaptureFocusModeAutoFocus;
        }
        [videoDevice unlockForConfiguration];
    });
}
//设置曝光
- (void)setExposureAtPoint:(CGPoint)point
{
    dispatch_async(_queue, ^{
        NSError *error;
        AVCaptureDevice *videoDevice = self.videoInput.device;
        
        [videoDevice lockForConfiguration:&error];
        if ([videoDevice isExposurePointOfInterestSupported]) {
            videoDevice.exposurePointOfInterest = point;
            videoDevice.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
        }
        [videoDevice unlockForConfiguration];
    });
}
#pragma mark - private functions
- (AVCaptureDevice *)videoDeviceWitchPosition:(AVCaptureDevicePosition)position
{
    AVCaptureDevice *videoDevice;
    
    if (@available(iOS 11.1, *)) {
        NSArray<AVCaptureDeviceType> *deviceTypes = @[AVCaptureDeviceTypeBuiltInWideAngleCamera,
                                                      AVCaptureDeviceTypeBuiltInDualCamera,
                                                      AVCaptureDeviceTypeBuiltInTrueDepthCamera];
        AVCaptureDeviceDiscoverySession *session = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:deviceTypes
                                                                                                          mediaType:AVMediaTypeVideo
                                                                                                           position:position];
        for (AVCaptureDevice *device in session.devices) {
            if (device.position == position) {
                videoDevice = device;
                break;
            }
        }
    } else if (@available(iOS 10.0, *)) {
        videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera
                                                         mediaType:AVMediaTypeVideo
                                                          position:position];
    } else {
        NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        for (AVCaptureDevice *device in cameras) {
            if (device.position == position) {
                videoDevice = device;
                break;
            }
        }
    }
    
    return videoDevice;
}
- (BOOL)canDeviceOpenCamera {
    //判断应用是否有使用麦克风的权限
    NSString *mediaType = AVMediaTypeVideo;//读取媒体类型
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];//读取设备授权状态
    BOOL result = NO;
    switch (authStatus) {
        case AVAuthorizationStatusRestricted:
            result = NO;
            break;
        case AVAuthorizationStatusDenied:
            result = NO;
            break;
        case AVAuthorizationStatusAuthorized:
            result = YES;
            break;
        default:
            result = NO;
            break;
    }
    return result;
}
- (void)checkVideoAuthorization:(void (^)(int code, NSString *message))completeBlock
{
    BOOL result = [self canDeviceOpenCamera];
    if (result) {
        completeBlock(0, @"可以使用摄像头");
        return;
    }
    dispatch_suspend(_queue);
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        if (granted == NO) {
            completeBlock(-1, @"用户拒绝使用摄像头");
        }else {
            completeBlock(0, @"可以使用摄像头");
        }
        dispatch_resume(self->_queue);
    }];
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    [self sampleBufferToYUV:sampleBuffer];
}
- (void)sampleBufferToYUV:(CMSampleBufferRef)sampleBuffer
{
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    int pixelWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
    int pixelHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
    int yuv_size = pixelHeight * pixelWidth * 1.5;
    int uv_size = pixelHeight * pixelWidth * 0.5;
    
    int stride_y = (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
    int stride_uv = (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
    
    uint8_t *base_y = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    uint8_t *base_uv = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    
    uint8_t *dest_y = malloc(yuv_size);
    uint8_t *dest_u = dest_y + pixelWidth * pixelHeight;
    uint8_t *dest_v = dest_u + pixelWidth * pixelHeight / 4;
    
    int result = NV12ToI420(base_y, stride_y, base_uv, stride_uv, dest_y, pixelWidth, dest_u, pixelWidth/2, dest_v, pixelWidth/2, pixelWidth, pixelHeight);
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    //回调数据
    [self processYUVData:dest_y width:pixelWidth height:pixelHeight];
    free(dest_y);
}
- (void)processYUVData:(void *)data width:(int)width height:(int)height {
    if ([self.delegate respondsToSelector:@selector(didReceivedVideoData:data:width:height:)]) {
        [self.delegate didReceivedVideoData:self data:data width:width height:height];
    }
}
@end
