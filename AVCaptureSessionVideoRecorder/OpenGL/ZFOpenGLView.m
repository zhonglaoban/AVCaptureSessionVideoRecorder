//
//  ZFOpenGLView.m
//  AVCaptureSessionVideoRecorder
//
//  Created by 钟凡 on 2020/4/15.
//  Copyright © 2020 钟凡. All rights reserved.
//

#import "ZFOpenGLView.h"
#import "ZFShader.h"

#import <OpenGLES/ES2/glext.h>

typedef enum {
    DBYVertexAttribPosition = 0,
    DBYVertexAttribTexture
} DBYVertexAttributes;

GLfloat textureCoords[] = {
    0.0f, 0.0f, // bottom left
    0.0f, 1.0f, // top left
    1.0f, 1.0f, // top right
    1.0f, 0.0f, // bottom right
};
GLfloat vertices[] = {
    -1.0f,  1.0f, 0.0f, // 0
    -1.0f, -1.0f, 0.0f, // 1
     1.0f, -1.0f, 0.0f, // 2
     1.0f,  1.0f, 0.0f, // 3
};

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
@property (nonatomic, assign) GLuint frameBufferHandle;
@property (nonatomic, assign) GLuint colorBufferHandle;
@property (nonatomic, assign) GLuint VAO;

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
        [self setupRender];
        [self setupTexture];
        [self setupVAO];
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
        [self setupRender];
        [self setupTexture];
        [self setupVAO];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
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
    // Initialize OpenGL ES 2
    _glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    [EAGLContext setCurrentContext:_glContext];

    _shader = [[ZFShader alloc] initWithVertexShader:@"video.vs" fragmentShader:@"video.fs"];
}
- (void)setupRender {
    //帧缓冲
    glGenFramebuffers(1, &_frameBufferHandle);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBufferHandle);
    
    //渲染缓冲
    glGenRenderbuffers(1, &_colorBufferHandle);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorBufferHandle);
    
    //为绘制缓冲分配存储空间
    BOOL result = [_glContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
    if (!result) {
        printf("failed to renderbufferStorage \n");
    }
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorBufferHandle);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (GL_FRAMEBUFFER_COMPLETE != status) {
        printf("gl check framebuffer status: %d \n", status);
    }
    GLenum glError = glGetError();
    if (GL_NO_ERROR != glError) {
        printf("gl error: %d \n", glError);
    }
}
- (void)setupTexture {
    int width = self.bounds.size.width;
    int height = self.bounds.size.height;
    
    _texture_y = [self createTexture:GL_LUMINANCE width:width height:height data:0];
    _texture_u = [self createTexture:GL_LUMINANCE width:width height:height data:0];
    _texture_v = [self createTexture:GL_LUMINANCE width:width height:height data:0];
    
    [_shader prepareToDraw];
    [_shader setTexture:"texSampler_y" value:0];
    [_shader setTexture:"texSampler_u" value:1];
    [_shader setTexture:"texSampler_v" value:2];
}
- (void)setupVAO {
    glGenVertexArraysOES(1, &_VAO);
    glBindVertexArrayOES(_VAO);
    
    GLuint vertexBuffer, textureBuffer;
    
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), 0);
    glEnableVertexAttribArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    glGenBuffers(1, &textureBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, textureBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(textureCoords), textureCoords, GL_STATIC_DRAW);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(float), 0);
    glEnableVertexAttribArray(1);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    glBindVertexArrayOES(0);
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
    
    glBindFramebuffer(GL_FRAMEBUFFER, self.frameBufferHandle);
    glViewport(0, 0, self.framebufferWidth, self.framebufferHeight);
    glClearColor(0.1, 0.1, 0.1, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    [self.shader prepareToDraw];
    
    glBindVertexArrayOES(self.VAO);
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    glBindVertexArrayOES(0);
    
    glBindRenderbuffer(GL_RENDERBUFFER, self.colorBufferHandle);
    [self.glContext presentRenderbuffer:GL_RENDERBUFFER];
}
- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    
}
@end
