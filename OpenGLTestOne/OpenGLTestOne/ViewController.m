//
//  ViewController.m
//  OpenGLTestOne
//
//  Created by apple on 2019/4/12.
//  Copyright © 2019 apple. All rights reserved.
//

#import "ViewController.h"
#import <GLKit/GLKit.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@interface ViewController ()
@property (nonatomic, strong) EAGLContext *mContext;
@property (nonatomic , strong) GLKBaseEffect* mEffect;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupConfig];
    [self setupVertexArray];
    [self uploadTexture];
}

- (void)setupConfig
{
    self.mContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    GLKView *view = (GLKView *)self.view; //storyboard记得将view 的类型改为 GLKView
    view.context = self.mContext;
    view.delegate = self;
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    [EAGLContext setCurrentContext:self.mContext];
}

- (void)setupVertexArray
{
    // 顶点数据，前三个是顶点坐标（x、y、z轴），后面两个是纹理坐标（x，y
    GLfloat vertexData[] =
    {
        0.5, -0.5, 0.0f,    1.0f, 0.0f, //右下
        0.5, 0.5, -0.0f,    1.0f, 1.0f, //右上
        -0.5, 0.5, 0.0f,    0.0f, 1.0f, //左上
        
        0.5, -0.5, 0.0f,    1.0f, 0.0f, //右下
        -0.5, 0.5, 0.0f,    0.0f, 1.0f, //左上
        -0.5, -0.5, 0.0f,   0.0f, 0.0f, //左下
    };
    
    // 顶点数据缓存
    GLuint buffer;
    // 申请一个标识符
    glGenBuffers(1, &buffer);
    // 把标识符绑定到 GL_ARRAY_BUFFER 上
    glBindBuffer(GL_ARRAY_BUFFER, buffer);
    // 把顶点的数据 从CPU 拷贝到 GPU内存
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertexData), vertexData, GL_STATIC_DRAW);
    
    /**
    开启对应的位置属性 作用就是确定着色器是否能够读取到 GPU（服务器）数据 默认未开起是读取不到的 默认情况下顶点着色器的属性（Attribute）变量都是关闭的，数据在着色器端是不可见的，glVertexAttribPointer或VBO只是建立CPU和GPU之间的逻辑连接，从而实现了CPU数据上传至GPU，这就是glEnableVertexAttribArray的功能，允许顶点着色器读取GPU（服务器端）数据。
     
     注意: glEnableVertexAttribArray应该在glVertexAttribPointer之前还是之后调用？答案是都可以，只要在绘图调用（glDraw*系列函数）前调用即可。
    */
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    
    /**
     内存中 采用交叉存储的方式 向GPU传入顶点数据 着色器读取GPU数据
     顶点数据 是分段存储顶点数据，sizeof(GLfloat) * 5  表示两个属性点(一个属性由五个点数据表示)之间的偏移量 一个属性有几个点数据表示 （x， y， z） (u , v)   一个 GLfloat 数据占 4个字节   共 5个 所以需要 乘 5
     3 ： 取出三个 顶点数据
     2 ： 取出两个纹理数据
     (GLfloat *)NULL + 0) ： 从第0 个索引开始取数据  顶点数据
     (GLfloat *)NULL + 3 ： 从第d三个索引 开始取数据 也就是取 纹理数据
     
      glVertexAttribPointer ： 指定了渲染时索引值为 index 的顶点属性数组的数据格式和位置
      参数解释  http://www.dreamingwish.com/article/glvertexattribpointer.html
     */
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 0);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0); // 开启纹理
    // glVertexAttribPointer设置合适的格式从buffer里面读取数据 建立cpu和 gpu 之间通道
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 3);
}

- (void)uploadTexture
{
    //纹理贴图
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"logo" ofType:@"png"];
    NSDictionary *option = [NSDictionary dictionaryWithObjectsAndKeys:@(1),GLKTextureLoaderOriginBottomLeft, nil];
    GLKTextureInfo *textinfo = [GLKTextureLoader textureWithContentsOfFile:filePath options:option error:nil];
    
    // 着色器
    self.mEffect = [[GLKBaseEffect alloc]init];
    self.mEffect.texture2d0.enabled = GL_TRUE;
    self.mEffect.texture2d0.name = textinfo.name;
}

-(void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(1.0f, 0.6f, 1.0f, 1.0f); // 背景色
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // 启动着色器
    [self.mEffect prepareToDraw];
    glDrawArrays(GL_TRIANGLES, 0, 6);
}

@end

#pragma clang diagnostic pop
