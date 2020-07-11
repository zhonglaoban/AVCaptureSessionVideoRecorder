//
//  DBYOpenGLView.m
//  DBYSDK_dylib
//
//  Created by 钟凡 on 2020/4/15.
//  Copyright © 2020 钟凡. All rights reserved.
//

#import "ZFOpenGLView.h"
#import "ZFShader.h"

#import <OpenGLES/ES2/glext.h>

GLenum glCheckError_(const char *file, int line)
{
    GLenum errorCode = glGetError();
    NSString *error;
    switch (errorCode)
    {
        case GL_INVALID_ENUM:                  error = @"INVALID_ENUM"; break;
        case GL_INVALID_VALUE:                 error = @"INVALID_VALUE"; break;
        case GL_INVALID_OPERATION:             error = @"INVALID_OPERATION"; break;
        case GL_OUT_OF_MEMORY:                 error = @"OUT_OF_MEMORY"; break;
        case GL_INVALID_FRAMEBUFFER_OPERATION: error = @"INVALID_FRAMEBUFFER_OPERATION"; break;
    }
    if (errorCode != GL_NO_ERROR) {
        NSLog(@"glGetError:%@, %s, %d", error, file, line);
    }
    return errorCode;
}
#define glCheckError() glCheckError_(__FILE__, __LINE__)

typedef enum {
    DBYVertexAttribPosition = 0,
    DBYVertexAttribTexture
} DBYVertexAttributes;

@interface ZFOpenGLView()

@property (nonatomic, strong) EAGLContext *glContext;
@property (nonatomic, strong) CAEAGLLayer *eaglLayer;
@property (nonatomic, strong) GLKTextureInfo *woodTexture;
@property (nonatomic, strong) ZFShader *shader;
@property (nonatomic, assign) GLint framebufferWidth;
@property (nonatomic, assign) GLint framebufferHeight;
@property (nonatomic, assign) GLuint texture_y;
@property (nonatomic, assign) GLuint texture_u;
@property (nonatomic, assign) GLuint texture_v;
@property (nonatomic, assign) GLuint frameBuffer;
@property (nonatomic, assign) GLuint colorBuffer;

@property (nonatomic, assign) GLuint VAO;
@property (nonatomic, assign) GLuint videoVBO;
@property (nonatomic, assign) GLuint textureVBO;

@property (nonatomic, assign) int viewWidth;
@property (nonatomic, assign) int viewHeight;
@property (nonatomic, assign) float viewScale;

@property (nonatomic, assign) BOOL shouldRender;

@end

@implementation ZFOpenGLView
+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        if ([UIScreen instancesRespondToSelector:@selector(nativeScale)]) {
            self.contentScaleFactor = [UIScreen mainScreen].nativeScale;
        } else {
            self.contentScaleFactor = [UIScreen mainScreen].scale;
        }
        [self setupOpenGL];
        [self setupTexture];
        [self setupVAO];
        _shouldRender = [self setupRender];
    }
    return self;
}
- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        if ([UIScreen instancesRespondToSelector:@selector(nativeScale)]) {
            self.contentScaleFactor = [UIScreen mainScreen].nativeScale;
        } else {
            self.contentScaleFactor = [UIScreen mainScreen].scale;
        }
        [self setupOpenGL];
        [self setupTexture];
        [self setupVAO];
        _shouldRender = [self setupRender];
    }
    return self;
}
- (void)dealloc {
    glDeleteVertexArraysOES(1, &_VAO);
    glDeleteBuffers(1, &_videoVBO);
    glDeleteBuffers(1, &_textureVBO);
    glDeleteFramebuffers(1, &_frameBuffer);
    glDeleteRenderbuffers(1, &_colorBuffer);
    glDeleteTextures(1, &_texture_y);
    glDeleteTextures(1, &_texture_u);
    glDeleteTextures(1, &_texture_v);
}
- (void)layoutSubviews {
    [super layoutSubviews];
    BOOL needRerender = self.bounds.size.width != _viewWidth || self.bounds.size.height != _viewHeight;
    if (needRerender && !_shouldRender) {
        _viewWidth = self.bounds.size.width;
        _viewHeight = self.bounds.size.height;
        glDeleteFramebuffers(1, &_frameBuffer);
        glDeleteRenderbuffers(1, &_colorBuffer);
        _shouldRender = [self setupRender];
    }
    _viewScale = [self scaleFromWidth:_viewWidth height:_viewHeight];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_framebufferWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_framebufferHeight);
}
- (void)setupOpenGL {
    _eaglLayer = (CAEAGLLayer *)self.layer;
    _eaglLayer.opaque = YES;
    _eaglLayer.drawableProperties = @{
        kEAGLDrawablePropertyRetainedBacking : @(NO),
        kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8
    };
    // Initialize OpenGL ES 3
    _glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    [EAGLContext setCurrentContext:_glContext];
    
    _shader = [[ZFShader alloc] initWithVertexShader:@"video.vs" fragmentShader:@"video.fs"];
}
- (BOOL)setupRender {
    //帧缓冲
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    
    //渲染缓冲
    glGenRenderbuffers(1, &_colorBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorBuffer);
    
    //为绘制缓冲分配存储空间，iOS需要这么用
    BOOL result = [_glContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
    if (!result) {
        printf("failed to renderbufferStorage \n");
        return NO;
    }
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorBuffer);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (GL_FRAMEBUFFER_COMPLETE != status) {
        printf("gl check framebuffer status: %d \n", status);
        return NO;
    }
    GLenum error = glCheckError();
    if (error != GL_NO_ERROR) {
        return NO;
    }
    return YES;
}
- (void)setupTexture {
    int width = self.bounds.size.width;
    int height = self.bounds.size.height;
    
    _texture_y = [self createTexture:GL_LUMINANCE width:width height:height data:0];
    _texture_u = [self createTexture:GL_LUMINANCE width:width/2 height:height/2 data:0];
    _texture_v = [self createTexture:GL_LUMINANCE width:width/2 height:height/2 data:0];
    glCheckError();
    [_shader prepareToDraw];
    [_shader setTexture:"texSampler_y" value:0];
    [_shader setTexture:"texSampler_u" value:1];
    [_shader setTexture:"texSampler_v" value:2];
    glCheckError();
}
- (void)setupVAO {
    GLfloat textureCoords[] = {
        0.0f, 0.0f, // bottom left
        0.0f, 1.0f, // top left
        1.0f, 1.0f, // top right
        1.0f, 0.0f, // bottom right
    };
    GLfloat vertices[] = {
        -1.0f,  1.0f, // 0
        -1.0f, -1.0f, // 1
        1.0f, -1.0f, // 2
        1.0f,  1.0f, // 3
    };
    
    glGenVertexArraysOES(1, &_VAO);
    glBindVertexArrayOES(_VAO);
    
    glGenBuffers(1, &_videoVBO);
    glBindBuffer(GL_ARRAY_BUFFER, _videoVBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(float), 0);
    glEnableVertexAttribArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    glGenBuffers(1, &_textureVBO);
    glBindBuffer(GL_ARRAY_BUFFER, _textureVBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(textureCoords), textureCoords, GL_STATIC_DRAW);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(float), 0);
    glEnableVertexAttribArray(1);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    glBindVertexArrayOES(0);
    
    glCheckError();
}
- (GLuint)createTexture:(GLenum)format width:(int)width height:(int)height data:(void *)data
{
    GLuint texture;
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, format, width, height, 0, format, GL_UNSIGNED_BYTE, data);
    glGenerateMipmap(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, 0);
    return texture;
}
- (void)displayYUV420Data:(void *)data width:(int)width height:(int)height {
    if (!_shouldRender) {
        return;
    }
    float dataScale = [self scaleFromWidth:width height:height];
    
    if (dataScale == 0 || _viewScale == 0) {
        return;
    }
    float widthScale = 1;
    float heightScale = 1;
    
    //wider
    if (dataScale > _viewScale) {
        heightScale = _viewScale / dataScale;
    }
    
    //higher
    if (dataScale <= _viewScale) {
        widthScale = dataScale / _viewScale;
    }
    
    GLfloat vertices[] = {
        -widthScale,  heightScale, // 0
        -widthScale, -heightScale, // 1
        widthScale, -heightScale, // 2
        widthScale,  heightScale, // 3
    };
    
    uint8_t *base_y = data;
    uint8_t *base_u = base_y + width * height;
    uint8_t *base_v = base_u + width * height / 4;
    
    [EAGLContext setCurrentContext:_glContext];
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _texture_y);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, width, height, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, base_y);
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, _texture_u);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, width/2, height/2, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, base_u);
    
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, _texture_v);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, width/2, height/2, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, base_v);
    
    glBindFramebuffer(GL_FRAMEBUFFER, self.frameBuffer);
    glViewport(0, 0, self.framebufferWidth, self.framebufferHeight);
    glClearColor(0.1, 0.1, 0.1, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    [self.shader prepareToDraw];
    
    glBindVertexArrayOES(self.VAO);
    
    glBindBuffer(GL_ARRAY_BUFFER, _videoVBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

    //draw rectangle
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    
    glBindVertexArrayOES(0);
    
    glBindRenderbuffer(GL_RENDERBUFFER, self.colorBuffer);
    [self.glContext presentRenderbuffer:GL_RENDERBUFFER];
}
- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    
}
- (float)scaleFromWidth:(int)width height:(int)height {
    if (height == 0) {
        return 0;
    }
    return (float)width / (float)height;
}
@end
