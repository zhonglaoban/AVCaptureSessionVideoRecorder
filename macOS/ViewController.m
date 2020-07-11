//
//  ViewController.m
//  macOS
//
//  Created by 钟凡 on 2020/4/18.
//  Copyright © 2020 钟凡. All rights reserved.
//

#import "ViewController.h"
#import "ZFVideoRecorder.h"

@interface ViewController()<ZFVideoRecorderDelegate>
@property (nonatomic, strong) ZFVideoRecorder *videoRecorder;
@end
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _videoRecorder = [[ZFVideoRecorder alloc] init];
    _videoRecorder.delegate = self;
    [_videoRecorder setVideoDimension:AVCaptureSessionPreset640x480];
    [_videoRecorder startRecord];
    // Do any additional setup after loading the view.
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}
- (void)videoRecorder:(ZFVideoRecorder *)videoRecorder didRecoredVideoData:(CMSampleBufferRef)sampleBuffer {
    
}
@end
