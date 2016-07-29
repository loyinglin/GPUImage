//
//  ViewController.m
//  LearnOpenGLESWithGPUImage
//
//  Created by 林伟池 on 16/5/10.
//  Copyright © 2016年 林伟池. All rights reserved.
//

attribute vec4 position;
attribute vec2 texCoord;

varying vec2 texCoordVarying;

void main()
{
    gl_Position = position;
    texCoordVarying = texCoord;
}

