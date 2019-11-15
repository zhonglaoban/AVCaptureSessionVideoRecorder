//
//  ZFPreviewView.h
//  AVCaptureSessionVideoRecorder
//
//  Created by 钟凡 on 2019/11/15.
//  Copyright © 2019 钟凡. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZFPreviewView : UIView

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;

@end

NS_ASSUME_NONNULL_END
