//
//  ViewController.m
//  OpenGLTextures
//
//  Created by Stephen zake on 2019/12/31.
//  Copyright © 2019 Stephen.Zeng. All rights reserved.
//

#import "ViewController.h"
#import "DisplayGLView.h"

@interface ViewController ()

@property (strong, nonatomic) DisplayGLView *glView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.glView = [[DisplayGLView alloc] initWithVertexName:@"TextureVertex" fragmentName:@"TextureFragment"];
    
    self.glView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    
    [self.view addSubview:self.glView];
}

- (CGImageRef)fetchImage {
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"texture" ofType:@"png"];
    UIImage* image = [UIImage imageWithData:[NSData dataWithContentsOfFile:imagePath]];
    return [image CGImage];
}

- (GLubyte *)createTextureDataWith: (CGImageRef) imageRef imageWidth:(int)width imageHeight:(int)height {
    GLubyte* textureData = (GLubyte *)malloc(width * height * 4); // if 4 components per pixel (RGBA)

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(textureData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);

    CGColorSpaceRelease(colorSpace);

    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    return textureData;
}


@end
