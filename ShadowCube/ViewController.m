//
//  ViewController.m
//  ShadowCube
//
//  Created by Borna Noureddin on 2016-03-03.
//  Copyright © 2016 Borna Noureddin. All rights reserved.
//
//  Adapted from https://github.com/rmaz/Shadow-Mapping (Copyright (c) 2012 Richard Mazorodze)

#import "ViewController.h"
#import "Cube.h"
#import "GLShader.h"


@interface ViewController ()
{
    EAGLContext *_context;
    Cube *theCube;
    GLShader *mainShader, *shadowShader;
    float _rotation;
    GLKMatrix4 _biasMatrix;

    GLuint bufferID;
    GLuint texture;
    CGSize bufferSize;
    float fieldOfView;
}

@end

@implementation ViewController

#pragma mark - Constants

static const float kCubeRotationZ = -5.0;
static const float kCubeRotationRadius = 1.0;
static const float kCubeRotationSpeed = 1.0;
static const float kWallZ = -50.0;
static const float kWallSize = 40.0;
static const GLKVector3 kLightPosition = { -0.5, 1.0, 0.0 };
static const GLKVector3 kLightLookAt = { 0.0, 0.0, -15.0 };
static float near = 1.0;
static float far = 1.0 - kWallZ;

- (void)loadView
{
    GLKView *glkView = [[GLKView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    glkView.delegate = self;
    self.view = glkView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!_context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = _context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    fieldOfView = GLKMathDegreesToRadians(65);
    
    [self setupGL];
}

- (void)setupGL
{
    [EAGLContext setCurrentContext:_context];
    
    glEnable(GL_CULL_FACE);
    glEnable(GL_DEPTH_TEST);
    glClearColor(0.1, 0.1, 0.1, 1.0);
    
    // we use a bias matrix to shift the depth texture range from [0 1] to [-1 +1]
    _biasMatrix = GLKMatrix4Make(0.5, 0, 0, 0, 0, 0.5, 0, 0, 0, 0, 0.5, 0, 0.5, 0.5, 0.5, 1.0);

    // create the shader objects and get the uniform locations
    shadowShader = [[GLShader alloc] init];
    NSArray *attributes = [NSArray arrayWithObjects:
                           @"position",
                           nil];
    NSArray *uniforms = [NSArray arrayWithObjects:
                         @"modelViewProjectionMatrix",
                         nil];
    shadowShader = [shadowShader initWithShaderName:@"ShadowShader" attributes:attributes uniforms:uniforms];
    mainShader = [[GLShader alloc] init];
    attributes = [NSArray arrayWithObjects:
                           @"position",
                           @"normal",
                           @"colour",
                           nil];
    
    uniforms = [NSArray arrayWithObjects:
                         @"modelViewProjectionMatrix",
                         @"normalMatrix",
                         @"lightDirection",
                         @"shadowProjectionMatrix",
                         @"shadowMap",
                         nil];
    mainShader = [mainShader initWithShaderName:@"MainShader" attributes:attributes uniforms:uniforms];

    // create and set up the cube object
    GLKVector3 lightDirection = GLKVector3Normalize(GLKVector3Subtract(kLightLookAt, kLightPosition));
    theCube = [[Cube alloc] init];
    theCube.lightDirection = lightDirection;
    theCube.shadowShader = shadowShader;
    theCube.mainShader = mainShader;
    theCube.billboardModelMatrix = GLKMatrix4Multiply(GLKMatrix4MakeTranslation(0, 0, kWallZ), GLKMatrix4MakeScale(kWallSize, kWallSize, 1.0));
}

- (void)tearDownGL
{
    if ([EAGLContext currentContext] == _context) {
        [EAGLContext setCurrentContext:nil];
    }
    _context = nil;
    mainShader = nil;
    shadowShader = nil;
    theCube = nil;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [self tearDownGL];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - GLKView Delegate Methods

- (void)update
{
    NSTimeInterval dt = self.timeSinceLastUpdate;
    _rotation += dt * kCubeRotationSpeed;
    
    // rotate the cube around it's axes
    GLKMatrix4 worldMatrix = GLKMatrix4MakeRotation(_rotation, 1.0, 1.0, 1.0);
    // move the cube to the rotation radius
    worldMatrix = GLKMatrix4Multiply(GLKMatrix4MakeTranslation(0, 0, kCubeRotationRadius), worldMatrix);
    // rotate the cube around the origin
    worldMatrix = GLKMatrix4Multiply(GLKMatrix4MakeYRotation(_rotation), worldMatrix);
    // shift the cube into the distance
    worldMatrix = GLKMatrix4Multiply(GLKMatrix4MakeTranslation(0, 0, kCubeRotationZ), worldMatrix);

    theCube.modelMatrix = worldMatrix;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    CGSize fboSize = theCube.bufferSize;
    
    // first we render to the shadow FBO from the lights perspective
    glBindFramebuffer(GL_FRAMEBUFFER, theCube.bufferID);
    glViewport(0, 0, fboSize.width, fboSize.height);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // create the projection matrix from the cameras view
    GLKMatrix4 cameraViewMatrix = GLKMatrix4MakeLookAt(kLightPosition.x, kLightPosition.y, kLightPosition.z, kLightLookAt.x, kLightLookAt.y, kLightLookAt.z, 0, 1, 0);
    float shadowAspect = fboSize.width / fboSize.height;
    GLKMatrix4 cameraProjectionMatrix = GLKMatrix4MakePerspective(fieldOfView, shadowAspect, near, far);
    GLKMatrix4 shadowMatrix = GLKMatrix4Multiply(cameraProjectionMatrix, cameraViewMatrix);
    
    // render only back faces, this avoids self shadowing
    glCullFace(GL_FRONT);
    
    // we only draw the shadow casting objects as fast as possible
    [theCube renderShadow:shadowMatrix];
    
    glCullFace(GL_BACK);
    
    // switch back to the main render buffer
    // this will also restore the viewport
    [view bindDrawable];
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);
    
    // calculate a perspective matrix for the current view size
    float aspectRatio = rect.size.width / rect.size.height;
    GLKMatrix4 perspectiveMatrix = GLKMatrix4MakePerspective(fieldOfView, aspectRatio, near, far);
    
    // calculate the texture projection matrix, takes the pixels from world space
    // to light projection space
    GLKMatrix4 textureMatrix = GLKMatrix4Multiply(_biasMatrix, shadowMatrix);
    
    [theCube render:perspectiveMatrix textureMatrix:textureMatrix];
}

@end
