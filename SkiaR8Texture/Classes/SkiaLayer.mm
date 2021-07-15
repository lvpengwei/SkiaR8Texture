//
//  SkiaLayer.mm
//  SkiaR8Texture
//
//  Created by lvpengwei on 2021/7/15.
//

#import "SkiaLayer.h"
#import <GrDirectContext.h>
#import <gl/GrGLInterface.h>
#import <SkCanvas.h>
#import <SkGraphics.h>
#import <SkSurface.h>
#import <SkString.h>
#import <SkTypeface.h>
#import <SkTextBlob.h>
#import <OpenGLES/ES3/gl.h>

@interface SkiaLayer () {
    sk_sp<SkSurface> _surface;
    sk_sp<GrDirectContext> _context;
    SkCanvas *_canvas;
    EAGLContext *_eaglContext;
    GLuint framebuffer;
    GLuint colorRenderbuffer;
    GLuint depthRenderbuffer;
}

@end

@implementation SkiaLayer

- (instancetype)init {
    self = [super init];
    if (self) {
        self.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
         [NSNumber numberWithBool:NO],
         kEAGLDrawablePropertyRetainedBacking,
         kEAGLColorFormatRGBA8,
         kEAGLDrawablePropertyColorFormat,
         nil];
        _eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    }
    return self;
}

- (void)dealloc {
    [self releaseSurface];
}

- (void)releaseSurface {
    if (_context == NULL) return;
    [EAGLContext setCurrentContext:_eaglContext];
    if (framebuffer) {
        glDeleteFramebuffers(1, &framebuffer);
        framebuffer = 0;
    }
    if (colorRenderbuffer) {
        glDeleteRenderbuffers(1, &colorRenderbuffer);
        colorRenderbuffer = 0;
    }
    if (depthRenderbuffer) {
        glDeleteRenderbuffers(1, &depthRenderbuffer);
        depthRenderbuffer = 0;
    }
    // Free up all gpu resources in case that we get squares when rendering texts.
    _context->freeGpuResources();
    [EAGLContext setCurrentContext:nil];
}

- (void)createSurface {
    if (_eaglContext == nil) return;
    if (self.bounds.size.width == 0 || self.bounds.size.height == 0) return;
    if (_context != NULL && _canvas != NULL) return;
    [EAGLContext setCurrentContext:_eaglContext];
    
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    
    glGenRenderbuffers(1, &colorRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer);
    [_eaglContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self];
    
    GLint width = self.bounds.size.width;
    GLint height = self.bounds.size.height;
    
    glGenRenderbuffers(1, &depthRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, width, height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer);
    
    glViewport(0, 0, width, height);
    glClearStencil(0);
    glClearColor(1.0, 1.0, 1.0, 1.0);
    glStencilMask(0xffffffff);
    glClear(GL_STENCIL_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        printf("无法使完整的framebuffer对象");
        exit(1);
    }
    _context = GrDirectContext::MakeGL(GrGLMakeNativeInterface());
    if (NULL == _context) {
        printf("Failed to initialize GL.");
        exit(1);
    }
    
    GrGLFramebufferInfo info{};
    info.fFBOID = framebuffer;
    info.fFormat = GL_RGBA8;
    GrBackendRenderTarget glRenderTarget(width, height, 0, 0, info);
    
    _surface = SkSurface::MakeFromBackendRenderTarget(_context.get(), glRenderTarget, kBottomLeft_GrSurfaceOrigin, kN32_SkColorType, nullptr, nullptr);
    _canvas = _surface->getCanvas();
    
    glBindRenderbuffer(GL_RENDERBUFFER, 0);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    [EAGLContext setCurrentContext:nil];
}

- (GLuint)createR8Texture {
    GLint width = self.bounds.size.width;
    GLint height = self.bounds.size.height;
    GLuint texID = 0;
    glGenTextures(1, &texID);
    glBindTexture(GL_TEXTURE_2D, texID);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_R8, width, height, 0, GL_RED, GL_UNSIGNED_BYTE, nullptr);
    return texID;
}

- (void)drawTextOnR8Texture:(GLuint)texID {
    GLint width = self.bounds.size.width;
    GLint height = self.bounds.size.height;
    
    GrGLTextureInfo info{};
    info.fID = texID;
    info.fTarget = GL_TEXTURE_2D;
    info.fFormat = GL_R8;
    
    GrBackendTexture glTexture(width, height, GrMipMapped::kNo, info);
    
    SkSurfaceProps props(0, kRGB_H_SkPixelGeometry);
    auto surface = SkSurface::MakeFromBackendTexture(_context.get(), glTexture, kBottomLeft_GrSurfaceOrigin, 0, kAlpha_8_SkColorType, nullptr, &props);
    if (surface == nullptr) {
        NSLog(@"create R8 surface error.");
        return;
    }
    SkPaint p;
    p.setAntiAlias(true);
    NSString *text = @"text";
    SkFont font{};
    font = font.makeWithSize(170);
    font.setEdging(SkFont::Edging::kSubpixelAntiAlias);
    auto textBlob = SkTextBlob::MakeFromText([text UTF8String], text.length, font);
    surface->getCanvas()->drawTextBlob(textBlob, 20, 200, p);
}

- (void)drawTexture:(GLuint)texID {
    GLint width = self.bounds.size.width;
    GLint height = self.bounds.size.height;
    GrGLTextureInfo textureInfo = {};
    textureInfo.fTarget = GL_TEXTURE_2D;
    textureInfo.fID = texID;
    textureInfo.fFormat = GL_R8;
    GrBackendTexture backendTexture(width, height, GrMipMapped::kNo, textureInfo);
    auto image = SkImage::MakeFromTexture(_context.get(), backendTexture, kBottomLeft_GrSurfaceOrigin, kAlpha_8_SkColorType,
                                          kPremul_SkAlphaType, nullptr);
    _canvas->drawImage(image, 0, 0);
}

- (void)draw {
    [self createSurface];
    if (_canvas == NULL) return;
    [EAGLContext setCurrentContext:_eaglContext];
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    
    GLuint r8Texture = [self createR8Texture];
    [self drawTextOnR8Texture:r8Texture];
    
    _canvas->drawColor(SK_ColorCYAN);
    
    [self drawTexture:r8Texture];
    
    _context->flush();
    [_eaglContext presentRenderbuffer:GL_RENDERBUFFER];
    
    glBindRenderbuffer(GL_RENDERBUFFER, 0);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    [EAGLContext setCurrentContext:nil];
}

@end
