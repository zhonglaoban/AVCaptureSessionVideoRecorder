//
//  ZFShader.h
//  AVCaptureSessionVideoRecorder
//
//  Created by 钟凡 on 2020/4/15.
//  Copyright © 2020 钟凡. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZFShader : NSObject

@property (nonatomic, assign) GLuint programHandle;

- (id)initWithVertexShader:(NSString *)vertexShader
            fragmentShader:(NSString *)fragmentShader;

- (void)prepareToDraw;

- (void)setTexture:(const GLchar *)name value:(int)value;

@end

NS_ASSUME_NONNULL_END
