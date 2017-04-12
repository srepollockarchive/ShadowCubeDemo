//
//  Cube.m
//  ShadowCube
//
//  Created by Borna Noureddin on 2016-03-03.
//  Copyright © 2016 Borna Noureddin. All rights reserved.
//
//  Adapted from https://github.com/rmaz/Shadow-Mapping (Copyright (c) 2012 Richard Mazorodze)

#import "Cube.h"

@implementation Cube

@synthesize mainShader = _mainShader;
@synthesize shadowShader = _shadowShader;
@synthesize modelMatrix = _modelMatrix;
@synthesize billboardModelMatrix = _billboardModelMatrix;
@synthesize lightDirection = _lightDirection;
@synthesize shadowTexture = _shadowTexture;

#pragma mark - Constants

static const CGSize kShadowMapSize = { 256, 256 };

static const GLfloat CubeVertexData[] =
{
    // data layout for each line below is:
    // positionX, positionY, positionZ,     normalX, normalY, normalZ,      colourR, colourG, colourB
    0.5f, -0.5f, -0.5f,        1.0f, 0.0f, 0.0f,        0.4f, 1.0f, 0.4f,
    0.5f, 0.5f, -0.5f,         1.0f, 0.0f, 0.0f,        0.4f, 1.0f, 0.4f,
    0.5f, -0.5f, 0.5f,         1.0f, 0.0f, 0.0f,        0.4f, 1.0f, 0.4f,
    0.5f, -0.5f, 0.5f,         1.0f, 0.0f, 0.0f,        0.4f, 1.0f, 0.4f,
    0.5f, 0.5f, -0.5f,          1.0f, 0.0f, 0.0f,        0.4f, 1.0f, 0.4f,
    0.5f, 0.5f, 0.5f,         1.0f, 0.0f, 0.0f,        0.4f, 1.0f, 0.4f,
    
    0.5f, 0.5f, -0.5f,         0.0f, 1.0f, 0.0f,        0.4f, 1.0f, 0.4f,
    -0.5f, 0.5f, -0.5f,        0.0f, 1.0f, 0.0f,        0.4f, 1.0f, 0.4f,
    0.5f, 0.5f, 0.5f,          0.0f, 1.0f, 0.0f,        0.4f, 1.0f, 0.4f,
    0.5f, 0.5f, 0.5f,          0.0f, 1.0f, 0.0f,        0.4f, 1.0f, 0.4f,
    -0.5f, 0.5f, -0.5f,        0.0f, 1.0f, 0.0f,        0.4f, 1.0f, 0.4f,
    -0.5f, 0.5f, 0.5f,         0.0f, 1.0f, 0.0f,        0.4f, 1.0f, 0.4f,
    
    -0.5f, 0.5f, -0.5f,        -1.0f, 0.0f, 0.0f,        0.4f, 1.0f, 0.4f,
    -0.5f, -0.5f, -0.5f,       -1.0f, 0.0f, 0.0f,        0.4f, 1.0f, 0.4f,
    -0.5f, 0.5f, 0.5f,         -1.0f, 0.0f, 0.0f,        0.4f, 1.0f, 0.4f,
    -0.5f, 0.5f, 0.5f,         -1.0f, 0.0f, 0.0f,        0.4f, 1.0f, 0.4f,
    -0.5f, -0.5f, -0.5f,       -1.0f, 0.0f, 0.0f,        0.4f, 1.0f, 0.4f,
    -0.5f, -0.5f, 0.5f,        -1.0f, 0.0f, 0.0f,        0.4f, 1.0f, 0.4f,
    
    -0.5f, -0.5f, -0.5f,       0.0f, -1.0f, 0.0f,        0.4f, 1.0f, 0.4f,
    0.5f, -0.5f, -0.5f,        0.0f, -1.0f, 0.0f,        0.4f, 1.0f, 0.4f,
    -0.5f, -0.5f, 0.5f,        0.0f, -1.0f, 0.0f,        0.4f, 1.0f, 0.4f,
    -0.5f, -0.5f, 0.5f,        0.0f, -1.0f, 0.0f,        0.4f, 1.0f, 0.4f,
    0.5f, -0.5f, -0.5f,        0.0f, -1.0f, 0.0f,        0.4f, 1.0f, 0.4f,
    0.5f, -0.5f, 0.5f,         0.0f, -1.0f, 0.0f,        0.4f, 1.0f, 0.4f,
    
    0.5f, 0.5f, 0.5f,          0.0f, 0.0f, 1.0f,        0.4f, 1.0f, 0.4f,
    -0.5f, 0.5f, 0.5f,         0.0f, 0.0f, 1.0f,        0.4f, 1.0f, 0.4f,
    0.5f, -0.5f, 0.5f,         0.0f, 0.0f, 1.0f,        0.4f, 1.0f, 0.4f,
    0.5f, -0.5f, 0.5f,         0.0f, 0.0f, 1.0f,        0.4f, 1.0f, 0.4f,
    -0.5f, 0.5f, 0.5f,         0.0f, 0.0f, 1.0f,        0.4f, 1.0f, 0.4f,
    -0.5f, -0.5f, 0.5f,        0.0f, 0.0f, 1.0f,        0.4f, 1.0f, 0.4f,
    
    0.5f, -0.5f, -0.5f,        0.0f, 0.0f, -1.0f,        0.4f, 1.0f, 0.4f,
    -0.5f, -0.5f, -0.5f,       0.0f, 0.0f, -1.0f,        0.4f, 1.0f, 0.4f,
    0.5f, 0.5f, -0.5f,         0.0f, 0.0f, -1.0f,        0.4f, 1.0f, 0.4f,
    0.5f, 0.5f, -0.5f,         0.0f, 0.0f, -1.0f,        0.4f, 1.0f, 0.4f,
    -0.5f, -0.5f, -0.5f,       0.0f, 0.0f, -1.0f,        0.4f, 1.0f, 0.4f,
    -0.5f, 0.5f, -0.5f,        0.0f, 0.0f, -1.0f,        0.4f, 1.0f, 0.4f
};

static const GLfloat BillboardVertexData[] = {
    -0.5, -0.5, 0.0,    0.0, 0.0, 1.0,  0.4, 0.4, 0.4,
    0.5, -0.5, 0.0,    0.0, 0.0, 1.0,  0.4, 0.4, 0.4,
    -0.5,  0.5, 0.0,    0.0, 0.0, 1.0,  0.4, 0.4, 0.4,
    0.5,  0.5, 0.0,    0.0, 0.0, 1.0,  0.4, 0.4, 0.4
};



#pragma mark - Init & Dealloc

- (id)init
{
    self = [super init];

    if (self != nil) {

        self.modelMatrix = GLKMatrix4Identity;
        
        ///// Create a texture and framebuffer for the shadow /////

        // create a texture to use to render the depth from the lights point of view
        GLuint depthTexture;
        glGenTextures(1, &depthTexture);
        glBindTexture(GL_TEXTURE_2D, depthTexture);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        
        // we do not want to wrap, this will cause incorrect shadows to be rendered
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        // set up the depth compare function to check the shadow depth in hardware
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_FUNC_EXT, GL_LEQUAL);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_MODE_EXT, GL_COMPARE_REF_TO_TEXTURE_EXT);
        
        // create the depth texture
        glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT, kShadowMapSize.width, kShadowMapSize.height, 0, GL_DEPTH_COMPONENT, GL_UNSIGNED_INT, 0);
        
        // unbind it for now
        glBindTexture(GL_TEXTURE_2D, 0);
        
        // create a framebuffer object to attach the depth texture to
        GLuint bufferID;
        glGenFramebuffers(1, &bufferID);
        glBindFramebuffer(GL_FRAMEBUFFER, bufferID);
        self.bufferID = bufferID;
        
        // attach the depth texture to the render buffer
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, depthTexture, 0);
        GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"error creating shadow FBO, status code 0x%4x", status);
        
        // unbind the FBO
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
        
        self.shadowTexture = depthTexture;
    }
    return self;
}

- (void)dealloc
{
    GLuint texture = self.shadowTexture;
    GLuint bufferID = self.bufferID;
    glDeleteTextures(1, &texture);
    glDeleteFramebuffers(1, &bufferID);
}

#pragma mark - Properties

- (CGSize)bufferSize
{
    return kShadowMapSize;
}

#pragma mark - Public Methods

- (void)renderShadow:(GLKMatrix4)projectionMatrix
{
    ///// Render the shadow from the light's perspective to a texture /////

    // set the correct shader
    GLShader *shader = self.shadowShader;
    glUseProgram(shader.program);
    
    // set up the vertex attributes
    GLsizei stride = 9 * sizeof(GLfloat);
    glEnableVertexAttribArray(LightPositionAttribute);
    glVertexAttribPointer(LightPositionAttribute, 3, GL_FLOAT, GL_FALSE, stride, CubeVertexData);
    
    // set up the uniforms
    GLKMatrix4 mvpMatrix = GLKMatrix4Multiply(projectionMatrix, self.modelMatrix);
    glUniformMatrix4fv(shader.uniforms[LightMVPMatrixUniform], 1, GL_FALSE, mvpMatrix.m);
    
    // draw the cube
    glDrawArrays(GL_TRIANGLES, 0, 36);
    
    // cleanup
    glDisableVertexAttribArray(LightPositionAttribute);
    glUseProgram(0);
}

- (void)render:(GLKMatrix4)projectionMatrix textureMatrix:(GLKMatrix4)textureMatrix
{
    ///// Render billboard with the shadow texture /////
    
    // set the correct shader
    GLShader *shader = self.mainShader;
    glUseProgram(shader.program);
    
    // enable the vertex attributes
    GLsizei stride = 9 * sizeof(GLfloat);
    glEnableVertexAttribArray(ShadowPositionAttribute);
    glVertexAttribPointer(ShadowPositionAttribute, 3, GL_FLOAT, GL_FALSE, stride, BillboardVertexData);
    
    glEnableVertexAttribArray(ShadowNormalAttribute);
    glVertexAttribPointer(ShadowNormalAttribute, 3, GL_FLOAT, GL_FALSE, stride, BillboardVertexData + 3);
    
    glEnableVertexAttribArray(ShadowColourAttribute);
    glVertexAttribPointer(ShadowColourAttribute, 3, GL_FLOAT, GL_FALSE, stride, BillboardVertexData + 6);
    
    // set the uniforms
    GLKMatrix4 mvpMatrix = GLKMatrix4Multiply(projectionMatrix, self.billboardModelMatrix);
    glUniformMatrix4fv(shader.uniforms[ShadowMVPMatrixUniform], 1, GL_FALSE, mvpMatrix.m);
    
    GLKMatrix4 mvsMatrix = GLKMatrix4Multiply(textureMatrix, self.billboardModelMatrix);
    glUniformMatrix4fv(shader.uniforms[ShadowMatrixUniform], 1, GL_FALSE, mvsMatrix.m);
    
    GLKMatrix3 normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(self.billboardModelMatrix), NULL);
    glUniformMatrix3fv(shader.uniforms[ShadowNormalMatrixUniform], 1, GL_FALSE, normalMatrix.m);
    
    glUniform3fv(shader.uniforms[ShadowLightDirectionUniform], 1, self.lightDirection.v);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, self.shadowTexture);
    glUniform1i(shader.uniforms[ShadowSamplerUniform], 0);
    
    // draw the vertices
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    
    ///// Render the cube on top of the billboard /////
    
    // set up the vertex attributes
    glEnableVertexAttribArray(ShadowPositionAttribute);
    glVertexAttribPointer(ShadowPositionAttribute, 3, GL_FLOAT, GL_FALSE, stride, CubeVertexData);
    
    glEnableVertexAttribArray(ShadowNormalAttribute);
    glVertexAttribPointer(ShadowNormalAttribute, 3, GL_FLOAT, GL_FALSE, stride, CubeVertexData + 3);
    
    glEnableVertexAttribArray(ShadowColourAttribute);
    glVertexAttribPointer(ShadowColourAttribute, 3, GL_FLOAT, GL_FALSE, stride, CubeVertexData + 6);
    
    // calculate and set the uniforms
    mvpMatrix = GLKMatrix4Multiply(projectionMatrix, self.modelMatrix);
    glUniformMatrix4fv(shader.uniforms[ShadowMVPMatrixUniform], 1, GL_FALSE, mvpMatrix.m);
    
    mvsMatrix = GLKMatrix4Multiply(textureMatrix, self.modelMatrix);
    glUniformMatrix4fv(shader.uniforms[ShadowMatrixUniform], 1, GL_FALSE, mvsMatrix.m);
    
    normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(self.modelMatrix), NULL);
    glUniformMatrix3fv(shader.uniforms[ShadowNormalMatrixUniform], 1, GL_FALSE, normalMatrix.m);
    
    // draw the cube
    glDrawArrays(GL_TRIANGLES, 0, 36);
    
    // cleanup
    glBindTexture(GL_TEXTURE_2D, 0);
    glDisableVertexAttribArray(ShadowPositionAttribute);
    glDisableVertexAttribArray(ShadowNormalAttribute);
    glDisableVertexAttribArray(ShadowColourAttribute);
    glUseProgram(0);
}

@end
