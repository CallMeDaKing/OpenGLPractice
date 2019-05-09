//
//  ViewController.m
//  OpenGLGLKitTest
//
//  Created by apple on 2019/4/19.
//  Copyright © 2019 apple. All rights reserved.
//

#import "ViewController.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@interface ViewController ()

@property (nonatomic, strong) EAGLContext *mContext;
@property (nonatomic, strong) GLKBaseEffect *mEffect;

@property (nonatomic, assign) int mCount;
@property (nonatomic, assign) float mDegreeX;
@property (nonatomic, assign) float mDegreeY;
@property (nonatomic, assign) float mDegreeZ;

@property (nonatomic, assign) BOOL mBoolX;
@property (nonatomic, assign) BOOL mBoolY;
@property (nonatomic, assign) BOOL mBoolZ;

@end

@implementation ViewController
{
    dispatch_source_t timer;
}
- (void)viewDidLoad {
    [super viewDidLoad];

    // 新建上下文
    self.mContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.mContext;
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [EAGLContext setCurrentContext:self.mContext];
    glEnable(GL_DEPTH_TEST);
    
    // 渲染图形
    [self renderView];
}

- (void)renderView
{
    //顶点数据，前三个是顶点坐标， 中间三个是顶点颜色，    最后两个是纹理坐标
    GLfloat attrArr[] =
    {
        -0.5f, 0.5f, 0.0f,      0.0f, 0.0f, 0.5f,       0.0f, 1.0f,//左上
        0.5f, 0.5f, 0.0f,       0.0f, 0.5f, 0.0f,       1.0f, 1.0f,//右上
        -0.5f, -0.5f, 0.0f,     0.5f, 0.0f, 1.0f,       0.0f, 0.0f,//左下
        0.5f, -0.5f, 0.0f,      0.0f, 0.0f, 0.5f,       1.0f, 0.0f,//右下
        0.0f, 0.0f, 1.0f,       1.0f, 1.0f, 1.0f,       0.5f, 0.5f,//顶点
    };
    
    //顶点索引
    /*
     void glDrawElements(
     
         GLenum mode,
         GLsizei count,
         GLenum type,
         const GLvoid * indices);
     
     
     Parameters :
     mode
     指定要渲染何种图元. 可接受的符号常量有 GL_POINTS, GL_LINE_STRIP, GL_LINE_LOOP,
     
     GL_LINES,GL_TRIANGLE_STRIP, GL_TRIANGLE_FAN, 和 GL_TRIANGLES
     
     count
     指定要渲染的元素数量
     
     type
     指定indices中的值的类型。必须为GL_UNSIGNED_BYTE或者GL_UNSIGNED_SHORT。
     
     indices
     指定存指向索引存储位置的指针
    glDrawElements使用很少的子例程调用来指定多重几何图元。除了调用GL方法来传递每一个顶点的属性，你还可以使用glVertexAttribPointer函数来设置独立的顶点、法线、颜色矩阵，以及纹理坐标，并仅需调用glDrawArrays就可以通过它们构建一系列图元。
     glDrawElements函数被调用时，它使用启用的数组中的从indices开始的count个连续的元素构建一系列几何图元。mode指定了要构建何种图元以及数组元素怎样构建图元。如果启用了不止一个数组，那么每个数组都会被使用。
     */
    
    GLuint indices[] =
    {
        0, 3, 2,
        0, 1, 3,
        0, 2, 4,
        0, 4, 1,
        2, 3, 4,
        1, 4, 3,
    };
    self.mCount = sizeof(indices) / sizeof(GLuint);
    
    GLuint buffer;
    glGenBuffers(1, &buffer);
    glBindBuffer(GL_ARRAY_BUFFER, buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_STATIC_DRAW);
    
    GLuint index;
    glGenBuffers(1, &index);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
    
    // 顶点位置
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 8, (GLfloat *)NULL);
    
    // 顶点颜色
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 8, (GLfloat *)NULL + 3);
    
    // 顶点纹理
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 8, (GLfloat *)NULL + 6);
    
    // 获取纹理
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"for_test" ofType:@"png"];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@(1),GLKTextureLoaderOriginBottomLeft, nil];
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile:filePath options:options error:nil];
    
    // 着色器
    self.mEffect = [[GLKBaseEffect alloc] init];
    self.mEffect.texture2d0.enabled = GL_TRUE;
    self.mEffect.texture2d0.name = textureInfo.name;
    
    //初始的投影 矩阵
    CGSize size = self.view.bounds.size;
    float aspect = fabs(size.width / size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(90.0), aspect, 0.1f, 10.f);
    projectionMatrix = GLKMatrix4Scale(projectionMatrix, 1.0f, 1.0f, 1.0f);
    self.mEffect.transform.projectionMatrix = projectionMatrix;
    
    // 偏移旋转矩阵
    GLKMatrix4 modelViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0.0f, 0.0f, -2.0f);
    self.mEffect.transform.modelviewMatrix = modelViewMatrix;
    
    // 定时器
    double delayInSeconds = 0.1;
    timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC, 0.0);
    dispatch_source_set_event_handler(timer, ^{
        self.mDegreeX += 0.1 * self.mBoolX;
        self.mDegreeY += 0.1 * self.mBoolY;
        self.mDegreeZ += 0.1 * self.mBoolZ;
    });
    dispatch_resume(timer);
}
- (IBAction)XRotate:(id)sender {
    self.mBoolX = !self.mBoolX;
}
- (IBAction)YRotate:(id)sender {
    self.mBoolY = !self.mBoolY;
}
- (IBAction)ZRotate:(id)sender {
    self.mBoolZ = !self.mBoolZ;
}

/**
 *  场景数据变化
 */
- (void)update {
    GLKMatrix4 modelViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0.0f, 0.0f, -2.0f);
    
    modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, self.mDegreeX);
    modelViewMatrix = GLKMatrix4RotateY(modelViewMatrix, self.mDegreeY);
    modelViewMatrix = GLKMatrix4RotateZ(modelViewMatrix, self.mDegreeZ);
    
    self.mEffect.transform.modelviewMatrix = modelViewMatrix;
}


-(void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(0.3f, 0.3f, 0.3f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    [self.mEffect prepareToDraw];
    glDrawElements(GL_TRIANGLES, self.mCount, GL_UNSIGNED_INT, 0);
}

@end

#pragma clang diagnostic pop

