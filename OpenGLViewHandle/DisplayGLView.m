//
//  DisplayGLView.m
//  OpenGLShader
//
//  Created by Stephen zake on 2019/12/30.
//  Copyright © 2019 Stephen.Zeng. All rights reserved.
//

#import "DisplayGLView.h"
#import <GLKit/GLKit.h>

@interface DisplayGLView() {
    // 显示用的layer
    __unsafe_unretained CAEAGLLayer *_eaglLayer;
    // OpenGL context: 管理使用opengl es进行绘制的状态,命令及资源
    EAGLContext *_eaglContext;
    
    // renderbuffer指针
    GLuint _renderBuffer;
    // framebuffer指针
    GLuint _frameBuffer;
    
    // size修正 UI层适配
    CGSize _oldSize;
    
    GLuint _glProgram;
}

@end

@implementation DisplayGLView

// 重写layer类型
+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (instancetype)initWithVertexName: (NSString *)vName fragmentName: (NSString *)fName {
    self = [super init];
    if (self) {
        self.vertexShader = vName;
        self.fragmentShader = fName;
        [self setupGLContext];
        [self setupCAEAGLLayer];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGSize size = self.frame.size;
    if (CGSizeEqualToSize(_oldSize, CGSizeZero) || !CGSizeEqualToSize(_oldSize, size)) {
        [self readyGL];
        _oldSize = size;
    }
    // render
    [self render];
}

- (void)readyGL {
    [self destoryRenderAndFrameBuffer];
    [self setupRenderAndFrameBuffer];
    [self compileShadersVertex:self.vertexShader fragment:self.fragmentShader];
}

#pragma mark - setupCAEAGLContext

- (void)setupGLContext {
    // 初始化渲染上下文，管理所有绘制的状态，命令及资源信息。
    _eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3]; //opengl es 3.0
    //设置为当前上下文
    [EAGLContext setCurrentContext:_eaglContext];
}

#pragma mark - setupCAEAGLLayer

- (void)setupCAEAGLLayer {
    //setup layer, 必须要是CAEAGLLayer才行，才能在其上描绘OpenGL内容
    //如果在viewController中，使用[self.view.layer addSublayer:eaglLayer];
    //如果在view中，可以直接重写UIView的layerClass类方法即可return [CAEAGLLayer class]。
    _eaglLayer = (CAEAGLLayer *)self.layer;
    _eaglLayer.opaque = YES; //CALayer默认是透明的
    
    // 描绘属性：这里不维持渲染内容
    // kEAGLDrawablePropertyRetainedBacking:若为YES，则使用glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)计算得到的最终结果颜色的透明度会考虑目标颜色的透明度值。
    // 若为NO，则不考虑目标颜色的透明度值，将其当做1来处理。
    // 使用场景：目标颜色为非透明，源颜色有透明度，若设为YES，则使用glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)得到的结果颜色会有一定的透明度（与实际不符）。若未NO则不会（符合实际）。
    _eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithBool:YES],
                                     kEAGLDrawablePropertyRetainedBacking,
                                     kEAGLColorFormatRGBA8,
                                     kEAGLDrawablePropertyColorFormat, nil];
}

#pragma mark - handleBuffer

- (void)destoryRenderAndFrameBuffer {
    // 销毁渲染区和帧缓冲区
    if (_renderBuffer) {
        glDeleteRenderbuffers(1, &_renderBuffer);
        _renderBuffer = 0;
    }
    
    if (_frameBuffer) {
        glDeleteFramebuffers(1, &_frameBuffer);
        _frameBuffer = 0;
    }
}

// 初始化Render Frame Buffer
- (void)setupRenderAndFrameBuffer {
    
    //先要renderbuffer，然后framebuffer，顺序不能互换。
    
    // OpenGlES共有三种：colorBuffer，depthBuffer，stencilBuffer。
    // 生成一个renderBuffer，id是_colorRenderBuffer
    glGenRenderbuffers(1, &_renderBuffer);
    // 设置为当前renderBuffer
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    //为color renderbuffer 分配存储空间
    [_eaglContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
    
    // FBO用于管理colorRenderBuffer，离屏渲染
    glGenFramebuffers(1, &_frameBuffer);
    //设置为当前framebuffer
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    // 将 _colorRenderBuffer 装配到 GL_COLOR_ATTACHMENT0 这个装配点上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
}

- (void)setClearColor {
    // 设置清屏颜色
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    // 用来指定要用清屏颜色来清除由mask指定的buffer，此处是color buffer
    glClear(GL_COLOR_BUFFER_BIT);
    // 设置显示大小
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
}


- (void)render {
    [self setClearColor];
    [self renderWithColor];
//    [self renderUsingIndexVBO];
//    [self renderUsingOther];
    
    // 将指定renderBuffer渲染在屏幕上
    // 绘制三角形，红色是由fragment shader决定
    // 从FBO中读取图像数据，离屏渲染。
    // 图像经过render之后，已经在FBO中了，即使不将其拿到RenderBuffer中，依然可以使用getResultImage取到图像数据。
    // 用[_eaglContext presentRenderbuffer:GL_RENDERBUFFER];，实际上就是将FBO中的图像拿到RenderBuffer中（即屏幕上）
    [_eaglContext presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)compileShadersVertex:(NSString *)vertexShaderName fragment: (NSString *)fragmentShaderName  {
    
    // 生成一个顶点着色器对象
    GLuint vertexShader = [self compileShader:vertexShaderName withType:GL_VERTEX_SHADER];
    
    // 生成一个片段着色器对象
    GLuint fragmentShader = [self compileShader:fragmentShaderName withType:GL_FRAGMENT_SHADER];
    
    /*
     调用了glCreateProgram glAttachShader  glLinkProgram 连接 vertex 和 fragment shader成一个完整的program。
     着色器程序对象(Shader Program Object)是多个着色器合并之后并最终链接完成的版本。
     如果要使用刚才编译的着色器我们必须把它们链接(Link)为一个着色器程序对象，
     然后在渲染对象的时候激活这个着色器程序。已激活着色器程序的着色器将在我们发送渲染调用的时候被使用。
     */
    _glProgram = glCreateProgram();  // 创建一个程序对象
    glAttachShader(_glProgram, vertexShader); // 链接顶点着色器
    glAttachShader(_glProgram, fragmentShader); // 链接片段着色器
    glLinkProgram(_glProgram); // 链接程序
    
    // 把着色器对象链接到程序对象以后，记得删除着色器对象，我们不再需要它们了
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
    
    // 调用 glGetProgramiv来检查是否有error，并输出信息。
    GLint linkSuccess;
    glGetProgramiv(_glProgram, GL_LINK_STATUS, &linkSuccess);
    
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"着色器程序:%@", messageString);
        exit(1);
    }
    
    // 调用 glUseProgram绑定程序对象 让OpenGL ES真正执行你的program进行渲染
    glUseProgram(_glProgram);
}

- (void)renderWithColor {
    
    // 把“顶点属性索引”绑定到“顶点属性名”
    GLuint position = glGetAttribLocation(_glProgram, "Position");
    GLuint color = glGetAttribLocation(_glProgram, "SourceColor");
    
    const GLfloat vertices[] = {
        0.5f, 0.5f, 0.0f, 1.0f, 0.0f, 0.0f, 1.0f,   // 右上角
        0.5f, -0.5f, 0.0f, 0.0f, 1.0f, 0.0f, 1.0f,  // 右下角
        -0.5f, -0.5f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, // 左下角
        -0.5f, 0.5f, 0.0f, 0.0f, 1.0f, 0.0f, 1.0f   // 左上角
    };
    
    const GLubyte indices[] = {
        0,1,3,   // 绘制第一个三角形
        1,2,3    // 绘制第二个三角形
    };
    
    // 创建一个渲染缓冲区对象
    GLuint vertexBuffer;
    
    // 使用glGenBuffers()生成新缓存对象并指定缓存对象标识符ID
    glGenBuffers(1, &vertexBuffer);
    
    // 绑定vertexBuffer到GL_ARRAY_BUFFER目标
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    
    // 为VBO申请空间，初始化并传递数据
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    GLuint indexBuffer;
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
    
    // 使用VBO时，最后一个参数0为要获取参数在GL_ARRAY_BUFFER中的偏移量
    // 使用glVertexAttribPointer函数告诉OpenGL该如何解析顶点数据
    // 顶点数据
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, (7* sizeof(float)), 0);
    glEnableVertexAttribArray(position);
    NSLog(@"%u",position);
    // 颜色数据
    glVertexAttribPointer(color, 4, GL_FLOAT, GL_FALSE, (7* sizeof(float)), (void*)(3* sizeof(float)));
    glEnableVertexAttribArray(color);
    NSLog(@"%u",color);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, 0);
//    glDrawArrays(GL_TRIANGLES, 0, 3);
}

- (void)renderUsingIndexVBO {
    
    const GLfloat vertices[] = {
        0.0f, 0.5f, 0.0f,   // 顶点
        0.5f, -0.5f, 0.0f,   // 右下角
        -0.5f, -0.5f, 0.0f   // 左下角
    };
    
    // 创建一个渲染缓冲区对象
    GLuint vertexBuffer;
    
    // 使用glGenBuffers()生成新缓存对象并指定缓存对象标识符ID
    glGenBuffers(1, &vertexBuffer);
    
    // 绑定vertexBuffer到GL_ARRAY_BUFFER目标
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    
    // 为VBO申请空间，初始化并传递数据
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    GLuint indexBuffer;
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    
    // 使用VBO时，最后一个参数0为要获取参数在GL_ARRAY_BUFFER中的偏移量
    // 使用glVertexAttribPointer函数告诉OpenGL该如何解析顶点数据
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, 0);
    glEnableVertexAttribArray(0);
    
    glDrawArrays(GL_TRIANGLES, 0, 3);
}

- (void)renderUsingOther {
    
    const GLfloat vertices[] = {
        0.5f, 0.5f, 0.0f,   // 右上角
        0.5f, -0.5f, 0.0f,  // 右下角
        -0.5f, -0.5f, 0.0f, // 左下角
        -0.5f, 0.5f, 0.0f   // 左上角
    };

    const GLubyte indices[] = {
        0,1,3,   // 绘制第一个三角形
        1,2,3    // 绘制第二个三角形
    };

    // 创建一个渲染缓冲区对象
    GLuint vertexBuffer;

    // 使用glGenBuffers()生成新缓存对象并指定缓存对象标识符ID
    glGenBuffers(1, &vertexBuffer);
    
    // 绑定vertexBuffer到GL_ARRAY_BUFFER目标
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);

    // 为VBO申请空间，初始化并传递数据
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

    GLuint indexBuffer;
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);

    // 使用VBO时，最后一个参数0为要获取参数在GL_ARRAY_BUFFER中的偏移量
    // 使用glVertexAttribPointer函数告诉OpenGL该如何解析顶点数据
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, 0);
    glEnableVertexAttribArray(0);
    
    // 颜色修改方法 针对uniform类型变量生效
    GLuint vertexColorLocation = glGetUniformLocation(_glProgram, "SourceColor");
    glUniform4f(vertexColorLocation, 1.0f, 1.0f, 1.0f, 1.0f);
    
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, 0);
}


- (GLuint)compileShader:(NSString *)shaderName withType:(GLenum)shaderType {
    
    // NSBundle中加载文件
    NSString *shaderPath = [[NSBundle mainBundle] pathForResource:shaderName ofType:@"glsl"];
    
    NSError* error;
    NSString* shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    
    // 如果为空就打印错误并退出
    if (!shaderString) {
        NSLog(@"Error loading shader: %@", error.localizedDescription);
        exit(1);
    }
    
    // 使用glCreateShader函数可以创建指定类型的着色器对象。shaderType是指定创建的着色器类型
    GLuint shader = glCreateShader(shaderType);
    
    // 这里把NSString转换成C-string
    const char* shaderStringUTF8 = [shaderString UTF8String];
    
    int shaderStringLength = (int)shaderString.length;
    
    // 使用glShaderSource将着色器源码加载到上面生成的着色器对象上
    glShaderSource(shader, 1, &shaderStringUTF8, &shaderStringLength);
    
    // 调用glCompileShader 在运行时编译shader
    glCompileShader(shader);
    
    // glGetShaderiv检查编译错误（然后退出）
    GLint compileSuccess;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"生成着色器对象:%@", messageString);
        exit(1);
    }
    
    // 返回一个着色器对象
    return shader;
}



@end
