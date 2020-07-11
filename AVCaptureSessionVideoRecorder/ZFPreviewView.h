//
//  ZFPreviewView.h
//  AVCaptureSessionVideoRecorder
//
//  Created by 钟凡 on 2019/11/15.
//  Copyright © 2019 钟凡. All rights reserved.
//
#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#else
#import <UIKit/UIKit.h>
#endif

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZFPreviewView : UIView

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;

- (void)displaySampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end

NS_ASSUME_NONNULL_END
