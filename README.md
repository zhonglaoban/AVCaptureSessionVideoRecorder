# 使用AVCaptureSession录制视频
在iOS上，音频有很多种录制方法。但是视频录制，只有AVCaptureSession这一种，它可以实现iPhone相机上的大部分功能。包括对焦、曝光、设置分辨率等多种功能。

## 初始化
录制视频和处理视频数据有一些耗时操作，我们这里创建一个队列。然后在另一个线程中处理。
```objc
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
    }
    
    return self;
}
```
## 设置AVCaptureSession
获取音频采集设备，为AVCaptureSession添加音频输入和数据输出。设置输出的代理为self，线程为我们创建的那个queue所在的线程。
```objc
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
```
### 对焦、曝光、设置分辨率等功能实现
#### 切换摄像头
切换摄像头之后videoConnection就是新的连接了，我们这里需要写一个方法重新获取一下。
```objc
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
```
#### 设置采集分辨率
分辨率的可选集合有限，我们可以采集出相近的，然后再进行裁剪。
```objc
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
```
#### 设置视频采集方向
```objc
//设置视频采集方向
- (void)setVideoOrientation:(AVCaptureVideoOrientation)orientation
{
    _orientation = orientation;
    dispatch_async(_queue, ^{
        self.videoConnection.videoOrientation = orientation;
    });
}
```
#### 设置是否镜像
这里需要注意的是，有些业务上前置摄像头和后置摄像头的镜像需求可能不一样，我们需要用两个变量来记录。
```objc
//设置是否镜像
- (void)setVideoMirrored:(BOOL)isMirrored
{
    _isMirrored = isMirrored;
    dispatch_async(_queue, ^{
        self.videoConnection.videoMirrored = isMirrored;
    });
}
```
#### 设置对焦
对焦这个point，是横屏模式下（状态栏在左，home健在右）的坐标系，取值范围是{0, 0}到{1, 1}。在显示的View中，是画面大小相对于view大小的点。
![point取值](https://github.com/zhonglaoban/AVCaptureSessionVideoRecorder/blob/master/images/point.png)
```objc
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
```
#### 设置曝光
```objc
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
```

## 控制AVCaptureSession
这里我们需要使用设备的摄像头，开始采集的时候先请求摄像头权限
权限判断逻辑：
```objc
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
```
AVCaptureSession的开始和结束：
```objc
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
```
## 获取视频数据
在回调里面我们会拿到一个引用CMSampleBufferRef，CMSampleBuufer的结构如下：
![CMSampleBuffer的结构图](https://upload-images.jianshu.io/upload_images/1185175-63b540861019f31d.png?imageMogr2/auto-orient/strip|imageView2/2/w/620/format/webp)
我们可以直接使用AVCaptureVideoPreviewLayer来展示数据。
也可以取到CMSampleBuufer里面的视频频数据，来做一些转码和展示。然后使用AVSampleBufferDisplayLayer或者OpenGL展示。
```objc
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    //切换线程访问，需要先retain，再release确保sampleBuffer不被系统回收。
    CFRetain(sampleBuffer);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(videoRecorder:didRecoredVideoData:)]) {
            [self.delegate videoRecorder:self didRecoredVideoData:sampleBuffer];
        }
        CFRelease(sampleBuffer);
    });
}
```
这里还有一些实现细节没有贴出来，完整代码请到[项目地址](https://github.com/zhonglaoban/AVCaptureSessionVideoRecorder.git)下载