//
//  ZFVideoRecorder.h
//  AVCaptureSessionVideoRecorder
//
//  Created by 钟凡 on 2019/11/7.
//  Copyright © 2019 钟凡. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ZFVideoRecorder;

@protocol ZFVideoRecorderDelegate <NSObject>

///获取到视频数据
- (void)videoRecorder:(ZFVideoRecorder *)videoRecorder didRecoredVideoData:(CMSampleBufferRef)sampleBuffer;
///获取到视频数据
- (void)didReceivedVideoData:(ZFVideoRecorder *)videoRecorder data:(void *)data width:(int)width height:(int) height;

@end


@interface ZFVideoRecorder : NSObject
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, weak) id<ZFVideoRecorderDelegate> delegate;

- (void)startRecord;
- (void)stopRecord;

//切换前后摄像头
- (void)swapFrontAndBackCameras;
//设置采集分辨率
- (void)setVideoDimension:(AVCaptureSessionPreset)preset;
//设置视频采集方向
- (void)setVideoOrientation:(AVCaptureVideoOrientation)orientation;
//设置是否镜像
- (void)setVideoMirrored:(BOOL)isMirrored;
//设置对焦
- (void)setFocusAtPoint:(CGPoint)point;
//设置曝光
- (void)setExposureAtPoint:(CGPoint)point;

@end

NS_ASSUME_NONNULL_END
