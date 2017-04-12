//
//  Cube.h
//  ShadowCube
//
//  Created by Borna Noureddin on 2016-03-03.
//  Copyright © 2016 Borna Noureddin. All rights reserved.
//
//  Adapted from https://github.com/rmaz/Shadow-Mapping (Copyright (c) 2012 Richard Mazorodze)

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <GLKit/GLKit.h>
#import "GLShader.h"

typedef enum {
    LightPositionAttribute
} LightShaderAttributes;

typedef enum {
    LightMVPMatrixUniform
} LightShaderUniforms;

typedef enum {
    ShadowPositionAttribute,
    ShadowNormalAttribute,
    ShadowColourAttribute
} ShadowShaderAttributes;

typedef enum {
    ShadowMVPMatrixUniform,
    ShadowNormalMatrixUniform,
    ShadowLightDirectionUniform,
    ShadowMatrixUniform,
    ShadowSamplerUniform
} ShadowShaderUniforms;

@interface Cube : NSObject

@property (nonatomic, assign) GLuint bufferID;
@property (nonatomic, assign) CGSize bufferSize;
@property (nonatomic, strong) GLShader *mainShader;
@property (nonatomic, strong) GLShader *shadowShader;
@property (nonatomic, assign) GLKMatrix4 modelMatrix;
@property (nonatomic, assign) GLKVector3 lightDirection;
@property (nonatomic, assign) GLuint shadowTexture;
@property (nonatomic, assign) GLKMatrix4 billboardModelMatrix;

- (void)renderShadow:(GLKMatrix4)projectionMatrix;
- (void)render:(GLKMatrix4)projectionMatrix textureMatrix:(GLKMatrix4)textureMatrix;

@end
