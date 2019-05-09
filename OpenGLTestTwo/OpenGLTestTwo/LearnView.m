//
//  LearnView.m
//  OpenGLTestTwo
//
//  Created by apple on 2019/4/16.
//  Copyright © 2019 apple. All rights reserved.


//  该demo 不采用GLKBaseEffect，编译链接自定义的着色器（shader），用简单的glsl语言来实现顶点和片元着色器，并对图片用简单的图形变换。

#import "LearnView.h"
#import <OpenGLES/ES2//gl.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@interface LearnView ()

@property (nonatomic, strong) EAGLContext *myContext;
@property (nonatomic, strong) CAEAGLLayer *myEagLayer;
@property (nonatomic, assign) GLuint       myProgram;

@property (nonatomic, assign) GLuint myColorRenderBuffer;
@property (nonatomic, assign) GLuint myColorFramebuffer;

- (void)setupLayer;
@end

@implementation LearnView

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (void)layoutSubviews
{
    [self setupLayer];
    
    [self setupContext];
    
    [self destoryRenderAndFrameBuffer];
    
    [self setupRenderBuffer];
    
    [self setupFrameBuffer];
    
    [self render];
}

- (void)setupLayer
{
    self.myEagLayer = (CAEAGLLayer *)self.layer;
    // 设置放大倍数
    [self setContentScaleFactor:[[UIScreen mainScreen] scale]];
    
    // CALayer 默认是透明的，设置不透明 才可见
    self.myEagLayer.opaque = YES;
    
    // 设置描绘属性 ， 在这里设置不维持渲染内容 以及颜色格式为 RGBA8
    self.myEagLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
}

- (void)setupContext
{
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:api];
    if (!context) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        exit(1);
    }
    
    if (![EAGLContext setCurrentContext:context]) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        exit(1);
    }
    
    self.myContext = context;
}

- (void)destoryRenderAndFrameBuffer
{
    // 释放 FBO（frame buffer object）
    glDeleteFramebuffers(1, &_myColorFramebuffer);
    self.myColorFramebuffer = 0;
    glDeleteRenderbuffers(1, &_myColorRenderBuffer);
    self.myColorRenderBuffer = 0;
}

- (void)setupRenderBuffer
{
    /*
    渲染缓存对象（Renderbuffer Object） 渲染缓存是为离线渲染而新引进的。它允许将一个场景直接渲染到一个渲染缓存对象中，而不是渲染到纹理对象中。渲染缓存对象是用于存储单幅图像的数据存储区域。该图像按照一种可渲染的内部格式存储。它用于存储没有相关纹理格式的OpenGL逻辑缓存，比如模板缓存或者深度缓存。
     */
    GLuint buffer;
    glGenRenderbuffers(1, &buffer);
    self.myColorRenderBuffer = buffer;
    
    // 和OpenGL中其他对象一样，在引用渲染缓存之前必须绑定当前渲染缓存对象
    glBindRenderbuffer(GL_RENDERBUFFER, self.myColorRenderBuffer);
    // 为颜色缓冲区 分配存储空间(当一个渲染缓存被创建，它没有任何数据存储区域，所以我们还要为他分配空间。）
    [self.myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEagLayer];
}

- (void)setupFrameBuffer
{
    /*
    帧缓存对象 FBO
     */
    GLuint buffer;
    glGenFramebuffers(1, &buffer);
    self.myColorFramebuffer = buffer;
    /*
      一旦一个FBO被创建，在使用它之前必须绑定。
     第一个参数target应该是GL_FRAMEBUFFER_EXT，第二个参数是FBO的ID号。一旦FBO被绑定，之后的所有的OpenGL操作都会对当前所绑定的FBO造成影响。ID号为0表示缺省帧缓存，即默认的window提供的帧缓存。因此，在glBindFramebufferEXT()中将ID号设置为0可以解绑定当前FBO。
     */
    glBindFramebuffer(GL_FRAMEBUFFER, self.myColorFramebuffer);
    
    /*
     // 将renderbuffer对象附加到framebuffer对象
     glFramebufferRenderbuffer将renderbuffer指定的renderbuffer附加为当前绑定的framebuffer对象的逻辑缓冲区之一。 attachment指定是否应将renderbuffer附加到framebuffer对象的颜色，深度或模板缓冲区。 渲染缓冲区不可以附加到默认（名称为0）的帧缓冲对象。
     */
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.myColorRenderBuffer);
    
}

- (void)render
{
    glClearColor(0, 1.0, 0, 1.0);  // 作用就是设置背景色 为绿色
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    CGFloat scale = [[UIScreen mainScreen] scale]; // 获取视图的放大b倍数 ，可以把scale 设置为1
    // 确定绘图视图大小
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);  // 设置视口大小
    
    // 读取文件路径
    NSString * verFile = [[NSBundle mainBundle] pathForResource:@"shaderv" ofType:@"vsh"];
    NSString *fragFile = [[NSBundle mainBundle] pathForResource:@"shaderf" ofType:@"fsh"];
    
    // 加载shader
    self.myProgram = [self loadShaders:verFile frag:fragFile];
    
    // 链接
    glLinkProgram(self.myProgram);
    GLint linkSuccess;
    // 返回program 对象的参数值 在这里是linkSuccess
    glGetProgramiv(self.myProgram, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        // 链接错误 打印错误1
        GLchar message[256];
        /*
         glGetProgramInfoLog 参数含义
         
         program    指定要查询其信息日志的程序对象。
         
         maxLength  指定用于存储返回的信息日志的字符缓冲区的大小。
         
         length     返回infoLog中返回的字符串的长度（不包括空终止符）。

         infoLog    指定用于返回信息日志的字符数组。
         */
        glGetProgramInfoLog(self.myProgram, sizeof(message), 0, &message[0]);
        NSString *messageString = [NSString stringWithUTF8String:message];
        NSLog(@"error %@", messageString);
        return;
    } else {
        NSLog(@"link ok");
        // 成功以后使用
        glUseProgram(self.myProgram);
    }
    
    //前三个是顶点坐标， 后面两个是纹理坐标
    GLfloat attrArr[] =
    {
        0.5f, -0.5f, -1.0f,     1.0f, 0.0f,
        -0.5f, 0.5f, -1.0f,     0.0f, 1.0f,
        -0.5f, -0.5f, -1.0f,    0.0f, 0.0f,
        0.5f, 0.5f, -1.0f,      1.0f, 1.0f,
        -0.5f, 0.5f, -1.0f,     0.0f, 1.0f,
        0.5f, -0.5f, -1.0f,     1.0f, 0.0f,
    };
   
    GLuint attrBuffer;
    //在buffers数组中返回当前1 (可以是 n )个 未使用的名称，表示缓冲区对象
    glGenBuffers(1, &attrBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, attrBuffer);
   
    /*
     将顶点数据 copy到缓存对象中
     void glBufferData(GLenum target, GLsizeiptr size, const GLvoid *data, GLenum usage);
     //target:可以是GL_ARRAY_BUFFER()（顶点数据）或GL_ELEMENT_ARRAY_BUFFER(索引数据)
     //size:存储相关数据所需的内存容量
     //data:用于初始化缓冲区对象，可以是一个指向数据内存的指针，也可以是NULL
     //usage:数据在分配之后如何进行读写 ，缓存对象将如何使用 ,如GL_STREAM_READ，GL_STREAM_DRAW，GL_STREAM_COPY 等 静态 和 动态 操作
     */
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    
    GLuint position = glGetAttribLocation(self.myProgram, "position");
    // 着色器读取GPU数据 指定渲染索引为GLuint 类型顶点数据属性的格式和位置
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, NULL);
    glEnableVertexAttribArray(position);  // 开启对应的位置属性。确保着色器可以读取GPU数据

    GLuint textCoor = glGetAttribLocation(self.myProgram, "textCoordinate");
    glVertexAttribPointer(textCoor, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) *5, (float *)NULL + 3);
    glEnableVertexAttribArray(textCoor);
    
    [self setupTexture:@"for_test"];
    
    // 获取shader 里面的变量  需要放到 glLinkProgram 后面
    GLuint rotate = glGetUniformLocation(self.myProgram, "rotateMatrix");
    
    float radians = 10 * 3.14159f / 180.0f;
    float s = sin(radians);
    float c = cos(radians);
    
    // z 轴旋转矩阵
    GLfloat zRotation[16] = {
        c, -s, 0, 0.2, //
        s, c, 0, 0,//
        0, 0, 1.0, 0,//
        0.0, 0, 0, 1.0//
    };
    
    // 设置旋转矩阵
    glUniformMatrix4fv(rotate, 1, GL_FALSE, (GLfloat *)&zRotation[0]);
    glDrawArrays(GL_TRIANGLES, 0, 6);
    
    // 将buffer渲染到CALayer上面
    [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
    
}

- (GLuint)setupTexture:(NSString *)fileName
{
    // 1 、获取图片的CGImageRef
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    if (!spriteImage) {
        NSLog(@"Filed to load image%@",fileName);
        exit(1);
    }
    
    // 2 、读取图片大小
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    /* calloc 函数返回值为void型指针。如果执行成功，函数从堆上获得 (width * height * 4) * sizeof(GLubyte)的字节空间，并返回该空间的首地址。 calloc函数得到的内存空间是经过初始化的，其内容全为0。calloc函数适合为数组申请空间，可以将size设置为数组元素的空间长度，将n设置为数组的容量
    */
    GLubyte * spritData = (GLubyte *)calloc(width * height * 4, sizeof(GLubyte));
  
    /*
     data                                    指向要渲染绘制的数据内存的地址。这个内存块的大小至少是（bytesPerRow*height）个字节
     
     width                                  bitmap的宽度,单位为像素
     
     height                                bitmap的高度,单位为像素
     
     bitsPerComponent        内存中像素的每个组件的位数.例如，对于32位像素格式和RGB 颜色空间，你应该将这个值设为8.
     
     bytesPerRow                  bitmap的每一行在内存所占的比特数
     
     colorspace                      bitmap上下文使用的颜色空间。
     
     bitmapInfo                       指定bitmap是否包含alpha通道，像素中alpha通道的相对位置，像素组件是整形还是浮点型等信息的字符串。
     
  当你调用这个函数的时候，Quartz创建一个位图绘制环境，也就是位图上下文。当你向上下文中绘制信息时，Quartz把你要绘制的信息作为位图数据绘制到指定的内存块。一个新的位图上下文的像素格式由三个参数决定：每个组件的位数，颜色空间，alpha选项。alpha值决定了绘制像素的透明性。
     */
    CGContextRef spriteContext = CGBitmapContextCreate(spritData, width, height, 8, width * 4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    // 3 、在context 上面进行绘制  首先坐标转换，因为 context 是左下角 为原点（0.0） 需要转为左上角为原点
    CGRect originalRect = CGRectMake(0, 0, width, height);
    CGContextTranslateCTM(spriteContext, originalRect.origin.x, originalRect.origin.y);
    CGContextTranslateCTM(spriteContext, 0, originalRect.size.height);
    CGContextScaleCTM(spriteContext, 1, -1.0);
    CGContextTranslateCTM(spriteContext, -originalRect.origin.x, -originalRect.origin.y);
    
    // 绘制转换完坐标后的位图纹理
    CGContextDrawImage(spriteContext, originalRect, spriteImage);
    CGContextRelease(spriteContext);
    
    // 4 、绑定纹理到默认的纹理ID  （这里只有一张图片，相当于默认于片元着色器里面的colorMap ,如果多张图不可以这么做）
    /*
     void glBindTexture(GLenum  target, GLuint  texture);
     参数：
     target: 指明了纹理绑定的目标 必须是下面中的一个：GL_TEXTURE_1D, GL_TEXTURE_2D, GL_TEXTURE_3D, GL_TEXTURE_1D_ARRAY, GL_TEXTURE_2D_ARRAY, GL_TEXTURE_RECTANGLE, GL_TEXTURE_CUBE_MAP, GL_TEXTURE_CUBE_MAP_ARRAY, GL_TEXTURE_BUFFER, GL_TEXTURE_2D_MULTISAMPLE 或者 GL_TEXTURE_2D_MULTISAMPLE_ARRAY
     texture : 指名纹理的名字，是一个无符号整数。值0是被保留的，它代表了每一个纹理目标的默认纹理。对于当前的GL渲染上下文中的共享对象空间，纹理名称以及它们对应的纹理内容是局部的；只有在显式开启上下文之间的共享，两个渲染上下文才可以共享纹理名称。
     当一张纹理被第一次绑定时，它假定成为指定的目标类型。例如，一张纹理若第一次被绑定到GL_TEXTURE_1D上，就变成了一张一维纹理；若第一次被绑定到GL_TEXTURE_2D上，就变成了一张二维纹理。
     
     当一张纹理被绑定后，GL对于这个目标的操作都会影响到这个被绑定的纹理。也就是说，这个纹理目标成为了被绑定到它上面的纹理的别名，而纹理名称为0则会引用到它的默认纹理。
     */
    glBindTexture(GL_TEXTURE_2D, 0);
    
    /*
     glTexParmeteri()函数来确定如何把纹理象素映射成像素
     参数：
     GL_TEXTURE_MIN_FILTER:
     当使用纹理坐标映射到纹素数组时，正好得到对应纹素的中心位置的情况，很少出现。例如上面的(0.5,1.0)对应纹素(128,256)的情况是比较少的。如果纹理坐标映射到纹素位置(152.34,745.14)该怎么办呢 ?
     
     一种方式是对这个坐标进行取整，使用最佳逼近点来获取纹素，这种方式即点采样(point sampling)，也就是最近邻滤波( nearest neighbor filtering)。
     另外还存在其他滤波方法，例如线性滤波方法(linear filtering)，它使用纹素位置(152.34,745.14)附近的一组纹素的加权平均值来确定最终的纹素值。例如使用 ( (152,745), (153,745), (152,744) and (153,744) )这四个纹素值的加权平均值。权系数通过与目标点(152.34,745.14)的距离远近反映，距离(152.34,745.14)越近，权系数越大，即对最终的纹素值影响越大。
     
     
     GL_TEXTURE_WRAP_S :
     
        上面提到纹理坐标(0.5, 1.0)到纹素的映射，恰好为(128,256)。如果纹理坐标超出[0,0]到[1,1]的范围该怎么处理呢？ 这个就是wrap参数由来，它使用以下方式来处理：
     
     GL_REPEAT:坐标的整数部分被忽略，重复纹理，这是OpenGL纹理默认的处理方式.
     GL_MIRRORED_REPEAT: 纹理也会被重复，但是当纹理坐标的整数部分是奇数时会使用镜像重复。
     GL_CLAMP_TO_EDGE: 坐标会被截断到[0,1]之间。结果是坐标值大的被截断到纹理的边缘部分，形成了一个拉伸的边缘(stretched edge pattern)。
     GL_CLAMP_TO_BORDER: 不在[0,1]范围内的纹理坐标会使用用户指定的边缘颜色。
     */
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    float fw = width, fh = height;
    
    /*
     API void glTexImage2D(      // 指定一个二维的纹理图片
     GLenum target,
     GLint level,
     GLint internalFormat,
     GLsizei width,
     GLsizei height,
     GLint border,
     GLenum format,
     GLenum type,
     const GLvoid * data);
     
     1. target 参数 指定设置的纹理目标，必须是GL_TEXTURE_2D, GL_PROXY_TEXTURE_2D等参数。
     2. level指定纹理等级，0代表原始纹理，其余等级对应Mipmap纹理等级。（ Mipmap 主要是在同一个屏幕像素显示多个不同深度的纹素 从而形成近大远小效果）
     3. internalFormat 指定OpenGL存储纹理的格式，我们读取的图片格式包含RGB颜色，因此这里也是用RGB颜色。
     4. width和height参数指定存储的纹理大小，
     5. border 参数为历史遗留参数，只能设置为0.
     6. 最后三个参数指定原始图片数据的格式(format)和数据类型(type,为GL_UNSIGNED_BYTE, GL_BYTE等值)，以及指向（图像）数据的内存地址(data指针)。
     */
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, spritData);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    free(spritData);
    
    return 0;
}

/**
 *  c语言编译流程：预编译、编译、汇编、链接
 *  glsl的编译过程主要有glCompileShader、glAttachShader、glLinkProgram三步；
 *  @param vert 顶点着色器
 *  @param frag 片元着色器
 *
 *  @return 编译成功的shaders
 */
- (GLuint)loadShaders:(NSString *)vert frag:(NSString *)frag
{
    GLuint verShader, fragShader;
    
    /**   glCreateProgram创建一个空program并返回一个可以被引用的非零值（program ID）。 program对象是可以附加着色器对象的对象。 这提供了一种机制来指定将链接以创建program的着色器对象。 它还提供了一种检查将用于创建program的着色器的兼容性的方法（例如，检查顶点着色器和片元着色器之间的兼容性）。 当不再需要作为program对象的一部分时，着色器对象就可以被分离了。
     
     通过调用glCompileShader成功编译着色器对象，并且通过调用glAttachShader成功地将着色器对象附加到program 对象，并且通过调用glLinkProgram成功的链接program 对象之后，可以在program 对象中创建一个或多个可执行文件。
     
     当调用glUseProgram时，这些可执行文件成为当前状态的一部分。 可以通过调用glDeleteProgram删除程序对象。 当program 对象不再是任何上下文的当前呈现状态的一部分时，将删除与program 对象关联的内存。
     */
    
    GLuint program = glCreateProgram();
    
    //编译
    [self compileShader:&verShader type:GL_VERTEX_SHADER file:vert];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:frag];
    
    glAttachShader(program, verShader);
    glAttachShader(program, fragShader);
    
    // 释放不需要的shader
    glDeleteShader(verShader);
    glDeleteShader(fragShader);
    
    return  program;
}

- (void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    // 读取字符串
    NSString * content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    const GLchar * source = (GLchar *)[content UTF8String];
    
    *shader = glCreateShader(type);
    /**
     glShaderSource将着色器中的源代码设置为string指定的字符串数组中的源代码。先前存储在着色器对象中的任何源代码都将被完全替换。数组中的字符串数由count指定。 如果length为NULL，则认为每个字符串都以null结尾。如果length不是NULL，则它指向包含字符串的每个相应元素的字符串长度的数组。length数组中的每个元素可以包含相应字符串的长度（空字符不计为字符串长度的一部分）或小于0的值以表示该字符串为空终止。此时不扫描或解析源代码字符串; 它们只是复制到指定的着色器对象中。
     */
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
}

@end

#pragma clang diagnostic pop
