//
//  ViewController.m
//  LearnOpenGLESWithGPUImage
//
//  Created by loyinglin on 16/5/10.
//  Copyright © 2016年 loyinglin. All rights reserved.
//


#import "LYMultiTextureFilter.h"

@interface LYMultiTextureFilter ()

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, GPUImageFramebuffer *> *indexToFrameBufferDict;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSValue *> *indexToDrawRectDict;
@property (nonatomic, assign) NSInteger mainFilterIndex;
@property (nonatomic, assign) NSInteger maxFilterIndex;
@property (nonatomic, assign) NSInteger curFilterIndex;

@end


@implementation LYMultiTextureFilter

- (id)initWithMaxFilter:(NSInteger)maxFilter {
    if (!(self = [self initWithFragmentShaderFromString:kGPUImagePassthroughFragmentShaderString]))
    {
        return nil;
    }
    self.maxFilterIndex = maxFilter;
    self.curFilterIndex = 0;
    self.mainFilterIndex = 0;
    self.indexToFrameBufferDict = [[NSMutableDictionary<NSNumber *, GPUImageFramebuffer *> alloc] init];
    self.indexToDrawRectDict = [[NSMutableDictionary<NSNumber *, NSValue *> alloc] init];
    return self;
}

- (NSInteger)nextAvailableTextureIndex {
    NSInteger ret = 0;
    if (self.curFilterIndex < self.maxFilterIndex) {
        ret = self.curFilterIndex++;
    }
    else {
        NSAssert(NO, @"should not call，too much index");
    }
    return ret;
}

- (void)setInputFramebuffer:(GPUImageFramebuffer *)newInputFramebuffer atIndex:(NSInteger)filterIndex {
    self.indexToFrameBufferDict[@(filterIndex)] = newInputFramebuffer;
    [newInputFramebuffer lock];
}

- (void)setDrawRect:(CGRect)rect atIndex:(NSInteger)filterIndex {
    NSParameterAssert(rect.origin.x >= 0 && rect.origin.x <= 1 &&
                      rect.origin.y >= 0 && rect.origin.y <= 1 &&
                      rect.size.width >= 0 && rect.size.width <= 1 &&
                      rect.size.height >= 0 && rect.size.height <= 1);
    self.indexToDrawRectDict[@(filterIndex)] = [NSValue valueWithCGRect:rect];
}

- (void)setMainIndex:(NSInteger)filterIndex {
    self.mainFilterIndex = filterIndex;
}

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)filterIndex {
    
    if (self.indexToDrawRectDict[@(filterIndex)]) {
        CGRect rect = [self.indexToDrawRectDict[@(filterIndex)] CGRectValue];
        GLfloat vertices[] = {
            rect.origin.x * 2 - 1, rect.origin.y * 2 - 1, // 左下
            rect.origin.x * 2 - 1 + rect.size.width * 2, rect.origin.y * 2 - 1,// 右下
            rect.origin.x * 2 - 1, rect.origin.y * 2 - 1 + rect.size.height * 2, // 左上
            rect.origin.x * 2 - 1 + rect.size.width * 2, rect.origin.y * 2 - 1 + rect.size.height * 2,  // 右上
        };
        [self renderToTextureWithVertices:vertices textureCoordinates:[[self class] textureCoordinatesForRotation:inputRotation] atIndex:filterIndex];
        if (filterIndex == self.mainFilterIndex) {
            [self informTargetsAboutNewFrameAtTime:frameTime];
        }
    }
    else {
        NSAssert(NO, @"error empty draw rect");
    }
}


- (void)informTargetsAboutNewFrameAtTime:(CMTime)frameTime;
{
    if (self.frameProcessingCompletionBlock != NULL)
    {
        self.frameProcessingCompletionBlock(self, frameTime);
    }
    
    for (id<GPUImageInput> currentTarget in targets)
    {
        if (currentTarget != self.targetToIgnoreForUpdates)
        {
            NSInteger indexOfObject = [targets indexOfObject:currentTarget];
            NSInteger textureIndex = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
            
            [self setInputFramebufferForTarget:currentTarget atIndex:textureIndex];
            [currentTarget setInputSize:[self outputFrameSize] atIndex:textureIndex];
        }
    }
    
    [[self framebufferForOutput] unlock];
    
    if (usingNextFrameForImageCapture)
    {
    }
    else
    {
//        [self removeOutputFramebuffer];
    }
    
    for (id<GPUImageInput> currentTarget in targets)
    {
        if (currentTarget != self.targetToIgnoreForUpdates)
        {
            NSInteger indexOfObject = [targets indexOfObject:currentTarget];
            NSInteger textureIndex = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
            [currentTarget newFrameReadyAtTime:frameTime atIndex:textureIndex];
        }
    }
}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates atIndex:(NSInteger)filterIndex {
    GPUImageFramebuffer *frameBuffer;
    if (self.indexToFrameBufferDict[@(filterIndex)]) {
        frameBuffer = self.indexToFrameBufferDict[@(filterIndex)];
    }
    else {
        NSLog(@"lytest: not ready at index: %ld", filterIndex);
        return ;
    }
    
    if (self.preventRendering)
    {
        [frameBuffer unlock];
        return;
    }
    
    [GPUImageContext setActiveShaderProgram:filterProgram];
    
    if (!outputFramebuffer) {
        outputFramebuffer = [[GPUImageContext sharedFramebufferCache] fetchFramebufferForSize:[self sizeOfFBO] textureOptions:self.outputTextureOptions onlyTexture:NO];
        glClearColor(backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorAlpha);
        glClear(GL_COLOR_BUFFER_BIT);
    }
    else {
        [outputFramebuffer lock];
    }
    [outputFramebuffer activateFramebuffer];
    if (usingNextFrameForImageCapture)
    {
        [outputFramebuffer lock];
    }
    
    [self setUniformsForProgramAtIndex:filterIndex];

    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, [frameBuffer texture]);
    
    glUniform1i(filterInputTextureUniform, 2);
    
    glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    [frameBuffer unlock];
    
    if (usingNextFrameForImageCapture)
    {
        dispatch_semaphore_signal(imageCaptureSemaphore);
    }
}

- (void)dealloc {
    if (outputFramebuffer) {
        [outputFramebuffer unlock]; // 因为取消了unlock
        outputFramebuffer = nil;
    }
}


@end
