//
//  DisplayGLView.h
//  OpenGLShader
//
//  Created by Stephen zake on 2019/12/30.
//  Copyright © 2019 Stephen.Zeng. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DisplayGLView : UIView

@property (strong, nonatomic) NSString *vertexShader;
@property (strong, nonatomic) NSString *fragmentShader;

- (instancetype)initWithVertexName: (NSString *)vName fragmentName: (NSString *)fName;

@end

NS_ASSUME_NONNULL_END
