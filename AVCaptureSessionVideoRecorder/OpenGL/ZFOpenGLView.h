//
//  ZFOpenGLView.h
//  AVCaptureSessionVideoRecorder
//
//  Created by 钟凡 on 2020/4/15.
//  Copyright © 2020 钟凡. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreVideo/CoreVideo.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZFOpenGLView : UIView

- (void)displayYUV420Data:(void *)data width:(int)width height:(int)height;
- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

NS_ASSUME_NONNULL_END
