//
//  ViewController.m
//  OpenGLShader
//
//  Created by Stephen zake on 2019/12/30.
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
    self.glView = [[DisplayGLView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [self.view addSubview:self.glView];
    
}


@end
