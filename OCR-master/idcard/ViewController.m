//
//  ViewController.m
//  idcard
//
//  Created by hxg on 16-4-10.
//  Copyright (c) 2016年 林英伟. All rights reserved.
//

#import "ViewController.h"
#import "IDCardViewController.h"
#import "UserDefaults.h"

@interface ViewController ()

@end

@implementation ViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:@"身份证识别" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    button.frame = CGRectMake(0,80, self.view.frame.size.width, 80);
    [self.view addSubview:button];
    [button addTarget:self action:@selector(btnRecognitPressed) forControlEvents:UIControlEventTouchUpInside];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [UserDefaults setUsingVerify:false];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//判断是ipad还是iphone
-(bool)isDevice:(NSString*)devName
{
    NSString* deviceType = [UIDevice currentDevice].model;
    NSLog(@"deviceType = %@", deviceType);
    
    NSRange range = [deviceType rangeOfString:devName];
    return range.location != NSNotFound;
}

-(void) btnRecognitPressed
{
    IDCardViewController *controller = [[IDCardViewController alloc] initWithNibName:nil bundle:nil];
    controller.verify = false;
    [self presentViewController:controller animated:YES completion:nil];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}
@end
