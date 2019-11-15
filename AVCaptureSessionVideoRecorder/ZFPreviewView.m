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
@end
