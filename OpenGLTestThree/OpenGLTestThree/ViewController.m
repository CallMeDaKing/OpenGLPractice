//
//  ViewController.m
//  OpenGLTestThree
//
//  Created by apple on 2019/4/18.
//  Copyright © 2019 apple. All rights reserved.
//

#import "ViewController.h"
#import "LearnView.h"

@interface ViewController ()
@property (nonatomic , strong) LearnView* myView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.myView = (LearnView *)self.view;
}

@end
