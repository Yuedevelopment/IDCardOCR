//
//  IDCardViewController.m
//  idcard
//
//  Created by hxg on 16-4-10.
//  Copyright (c) 2016年 林英伟. All rights reserved.
//
@import MobileCoreServices;
@import ImageIO;
#import "IDCardViewController.h"
#import "IdInfo.h"

@interface IDCardViewController ()

@end

@implementation IDCardViewController
@synthesize verify = _verify;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

static Boolean init_flag = false;
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
   
    if (!init_flag)
    {
        const char *thePath = [[[NSBundle mainBundle] resourcePath] UTF8String];
        int ret = EXCARDS_Init(thePath);
        if (ret != 0)
        {
            NSLog(@"Init Failed!ret=[%d]", ret);
        }
        
        init_flag = true;
    }
    
    self.toolbar = [UIToolbar new];
    _toolbar.barStyle = UIBarStyleDefault;
    
    // size up the toolbar and set its frame
    [_toolbar sizeToFit];
    CGFloat toolbarHeight = [_toolbar frame].size.height;
    CGRect frame = self.view.bounds;
    [_toolbar setFrame:CGRectMake(CGRectGetMinX(frame),
                                  CGRectGetMinY(frame) + CGRectGetHeight(frame) - toolbarHeight,
                                  CGRectGetWidth(frame),
                                  toolbarHeight)];
    
    [self.view addSubview:_toolbar];
    
    // Create spacing
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    UIBarButtonItem *close = [[UIBarButtonItem alloc]
                              initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                              target:self
                              action:@selector(closeAction)];
    
    UIBarButtonItem *start = [[UIBarButtonItem alloc]
                              initWithBarButtonSystemItem:UIBarButtonSystemItemReply
                              target:self
                              action:@selector(startAction)];
    
    NSMutableArray *items = [NSMutableArray arrayWithObjects: close, flex, start, flex, nil];
    [self.toolbar setItems:items animated:NO];
}

- (void)closeAction
{
    [self removeCapture];
    [self dismissViewControllerAnimated: YES completion:nil];
    if(init_flag){
        EXCARDS_Done();
        init_flag = false;
    }
}

- (void)startAction
{
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [nameLabel setText:@""];
        [genderLabel setText:@""];
        [nationLabel setText:@""];
        [addressLabel setText:@""];
        [codeLabel setText:@""];
        [issueLabel setText:@""];
        [validLabel setText:@""];
    });
    
    [[_capture captureSession] startRunning];
}

-(void) viewDidUnload
{
    if (_buffer != NULL)
    {
        free(_buffer);
        _buffer = NULL;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [self initCapture];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Capture

- (void)initCapture
{
    // init capture manager
    _capture = [[Capture alloc] init];
    
    _capture.delegate = self;
    _capture.verify = self.verify;
    
    // set video streaming quality
    // AVCaptureSessionPresetHigh   1280x720
    // AVCaptureSessionPresetPhoto  852x640
    // AVCaptureSessionPresetMedium 480x360
    _capture.captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    
    //kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
    //kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
    //kCVPixelFormatType_32BGRA
    [_capture setOutPutSetting:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]];
    
    // AVCaptureDevicePositionBack
    // AVCaptureDevicePositionFront
    [_capture addVideoInput:AVCaptureDevicePositionBack];
    
    [_capture addVideoOutput];
    [_capture addVideoPreviewLayer];
    
    CGRect layerRect = self.view.bounds;
    [[_capture previewLayer] setOpaque: 0];
    [[_capture previewLayer] setBounds:layerRect];
    [[_capture previewLayer] setPosition:CGPointMake( CGRectGetMidX(layerRect), CGRectGetMidY(layerRect))];
    
    [_capture setvideoScale];
    
    // create a view, on which we attach the AV Preview layer
    CGRect frame = self.view.bounds;
    CGFloat toolbarHeight = [_toolbar frame].size.height;
    frame.size.height = frame.size.height - toolbarHeight;
    _cameraView = [[UIView alloc] initWithFrame:frame];
    [[_cameraView layer] addSublayer:[_capture previewLayer]];
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
    [singleTap setNumberOfTapsRequired:1];
    [_cameraView addGestureRecognizer:singleTap];
    
    [self initFocusView];
    
    NSString *str = @"姓名";
    str = @"";
    UIFont *font = [UIFont systemFontOfSize:13];
    CGSize size = [str sizeWithFont:font
                  constrainedToSize:CGSizeMake(CGRectGetWidth(frame), MAXFLOAT)
                      lineBreakMode:NSLineBreakByWordWrapping];
    
    nameLabel = [[UILabel alloc]initWithFrame:CGRectMake(3, (3+size.height)*1, size.width, size.height)];
    nameLabel.text = str;
    nameLabel.backgroundColor = [UIColor clearColor];
    nameLabel.textColor =[UIColor greenColor];
    nameLabel.font = [UIFont systemFontOfSize:13];
    [_cameraView addSubview:nameLabel];
    
    
    //str = @"性别";
    size = [str sizeWithFont:font
           constrainedToSize:CGSizeMake(CGRectGetWidth(frame), MAXFLOAT)
               lineBreakMode:NSLineBreakByWordWrapping];
    genderLabel = [[UILabel alloc]initWithFrame:CGRectMake(3, (3+size.height)*2, size.width, size.height)];
    genderLabel.text = str;
    genderLabel.backgroundColor = [UIColor clearColor];
    genderLabel.textColor =[UIColor greenColor];
    genderLabel.font = [UIFont systemFontOfSize:13];
    [_cameraView addSubview:genderLabel];
    
    
    //str = @"民族";
    size = [str sizeWithFont:font
           constrainedToSize:CGSizeMake(CGRectGetWidth(frame), MAXFLOAT)
               lineBreakMode:NSLineBreakByWordWrapping];
    nationLabel = [[UILabel alloc]initWithFrame:CGRectMake(3, (3+size.height)*3, size.width, size.height)];
    nationLabel.text = str;
    nationLabel.backgroundColor = [UIColor clearColor];
    nationLabel.textColor =[UIColor greenColor];
    nationLabel.font = [UIFont systemFontOfSize:13];
    [_cameraView addSubview:nationLabel];
    
    
    //str = @"地址";
    size = [str sizeWithFont:font
           constrainedToSize:CGSizeMake(CGRectGetWidth(frame), MAXFLOAT)
               lineBreakMode:NSLineBreakByWordWrapping];
    addressLabel = [[UILabel alloc]initWithFrame:CGRectMake(3, (3+size.height)*4, size.width, size.height)];
    addressLabel.text = str;
    addressLabel.backgroundColor = [UIColor clearColor];
    addressLabel.textColor =[UIColor greenColor];
    addressLabel.font = [UIFont systemFontOfSize:13];
    [_cameraView addSubview:addressLabel];
    
    
    
    //str = @"身份证号";
    size = [str sizeWithFont:font
           constrainedToSize:CGSizeMake(CGRectGetWidth(frame), MAXFLOAT)
               lineBreakMode:NSLineBreakByWordWrapping];
    codeLabel = [[UILabel alloc]initWithFrame:CGRectMake(3, (3+size.height)*5, size.width, size.height)];
    codeLabel.text = str;
    codeLabel.backgroundColor = [UIColor clearColor];
    codeLabel.textColor =[UIColor greenColor];
    codeLabel.font = [UIFont systemFontOfSize:13];
    [_cameraView addSubview:codeLabel];
    
    
    
    //str = @"签发机关";
    size = [str sizeWithFont:font
           constrainedToSize:CGSizeMake(CGRectGetWidth(frame), MAXFLOAT)
               lineBreakMode:NSLineBreakByWordWrapping];
    issueLabel = [[UILabel alloc]initWithFrame:CGRectMake(3, (3+size.height)*6, size.width, size.height)];
    issueLabel.text = str;
    issueLabel.backgroundColor = [UIColor clearColor];
    issueLabel.textColor =[UIColor greenColor];
    issueLabel.font = [UIFont systemFontOfSize:13];
    [_cameraView addSubview:issueLabel];
    
    
    //str = @"有效期";
    size = [str sizeWithFont:font
           constrainedToSize:CGSizeMake(CGRectGetWidth(frame), MAXFLOAT)
               lineBreakMode:NSLineBreakByWordWrapping];
    validLabel = [[UILabel alloc]initWithFrame:CGRectMake(3, (3+size.height)*7, size.width, size.height)];
    validLabel.text = str;
    validLabel.backgroundColor = [UIColor clearColor];
    validLabel.textColor =[UIColor greenColor];
    validLabel.font = [UIFont systemFontOfSize:13];
    [_cameraView addSubview:validLabel];
    
    
    // add the view we just created as a subview to the View Controller's view
    [self.view addSubview: _cameraView];
    [self.view sendSubviewToBack:_cameraView];
    
    // start !
    [self performSelectorInBackground:@selector(startCapture) withObject:nil];
}

-(void)initFocusView
{
    _focusView = [[UIView alloc] init];
    _focusView.frame = CGRectMake(0, 0, 80, 80);
    _focusView.backgroundColor = [UIColor clearColor];
    _focusView.layer.borderColor = [UIColor whiteColor].CGColor;
    _focusView.layer.borderWidth = 1;
    _focusView.layer.masksToBounds = YES;
    _focusView.layer.cornerRadius = _focusView.frame.size.width/2;
    
    UIView *smallView = [[UIView alloc] init];
    smallView.frame = CGRectMake(_focusView.frame.size.width/2 - 64/2, _focusView.frame.size.height/2 - 64/2, 64, 64);
    smallView.backgroundColor = [UIColor clearColor];
    smallView.layer.borderColor = [UIColor whiteColor].CGColor;
    smallView.layer.borderWidth = 2;
    smallView.layer.masksToBounds = YES;
    smallView.layer.cornerRadius = smallView.frame.size.width/2;
    smallView.alpha = 0.7f;
    [_focusView addSubview:smallView];
}


- (void)removeCapture
{
    [_capture.captureSession stopRunning];
    [_cameraView removeFromSuperview];
    _capture     = nil;
    _cameraView  = nil;
}

- (void)startCapture
{
    //@autoreleasepool
    {
        [[_capture captureSession] startRunning];
    }
}

//单机
- (void)singleTap:(UIGestureRecognizer*)gestureRecognizer
{
    
    CGPoint point = [gestureRecognizer locationInView:_cameraView.superview];
    
    NSLog(@"point = %f,%f",point.x,point.y);
    
    CGPoint focuspoint = CGPointMake(point.x/_cameraView.frame.size.width, point.y/_cameraView.frame.size.height);
    [_capture focusInPoint:focuspoint];
    
    [self showFocusView:point];
}

-(void)showFocusView:(CGPoint )point
{
    [_focusView.layer removeAllAnimations];
    [_focusView removeFromSuperview];
    _focusView.center = point;
    _focusView.transform = CGAffineTransformMakeScale(0.8, 0.8);
    _focusView.alpha = 1;
    [_cameraView addSubview:_focusView];
    
    [UIView animateWithDuration:0.52f
                          delay:0.0
         usingSpringWithDamping:0.4f
          initialSpringVelocity:0.f
                        options:UIViewAnimationOptionBeginFromCurrentState |
     UIViewAnimationOptionCurveEaseInOut |
     UIViewAnimationOptionOverrideInheritedDuration
                     animations:^{
                         
                         _focusView.transform = CGAffineTransformMakeScale(1, 1);
                         
                     } completion:^(BOOL finished) {
                         
                         if(finished) {
                             [UIView animateWithDuration:0.52f
                                                   delay:0.0
                                  usingSpringWithDamping:0.4f
                                   initialSpringVelocity:0.f
                                                 options:UIViewAnimationOptionBeginFromCurrentState |
                              UIViewAnimationOptionCurveEaseInOut |
                              UIViewAnimationOptionOverrideInheritedDuration
                                              animations:^{
                                                  _focusView.alpha = 0;
                                              } completion:^(BOOL finished) {
                                                  
                                                  if(finished) {
                                                      [_focusView removeFromSuperview];
                                                  }
                                              }];
                         }
                     }];
}


#pragma mark - Capture Delegates
- (void)idCardRecognited:(IdInfo*)idInfo
{
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        if (idInfo.name != nil)
        {
            [nameLabel setText:[NSString stringWithFormat:@"姓名:%@", idInfo.name]];
            CGSize size = [nameLabel.text sizeWithFont:nameLabel.font
                                     constrainedToSize:CGSizeMake(CGRectGetWidth(self.view.bounds), MAXFLOAT)
                                         lineBreakMode:NSLineBreakByWordWrapping];
            [nameLabel setFrame:CGRectMake(3, (3+size.height)*1, size.width, size.height)];
        }
        
        if (idInfo.gender != nil)
        {
            [genderLabel setText:[NSString stringWithFormat:@"性别:%@", idInfo.gender]];
            CGSize size = [genderLabel.text sizeWithFont:nameLabel.font
                                       constrainedToSize:CGSizeMake(CGRectGetWidth(self.view.bounds), MAXFLOAT)
                                           lineBreakMode:NSLineBreakByWordWrapping];
            [genderLabel setFrame:CGRectMake(3, (3+size.height)*2, size.width, size.height)];
        }
        
        if (idInfo.nation != nil)
        {
            [nationLabel setText:[NSString stringWithFormat:@"民族:%@", idInfo.nation]];
            CGSize  size = [nationLabel.text sizeWithFont:nameLabel.font
                                        constrainedToSize:CGSizeMake(CGRectGetWidth(self.view.bounds), MAXFLOAT)
                                            lineBreakMode:NSLineBreakByWordWrapping];
            [nationLabel setFrame:CGRectMake(3, (3+size.height)*3, size.width, size.height)];
        }
        
        if (idInfo.address != nil)
        {
            [addressLabel setText:[NSString stringWithFormat:@"地址:%@", idInfo.address]];
            CGSize size = [addressLabel.text sizeWithFont:nameLabel.font
                                        constrainedToSize:CGSizeMake(CGRectGetWidth(self.view.bounds), MAXFLOAT)
                                            lineBreakMode:NSLineBreakByWordWrapping];
            [addressLabel setFrame:CGRectMake(3, (3+size.height)*4, size.width, size.height)];
        }
        
        if (idInfo.code != nil)
        {
            [codeLabel setText:[NSString stringWithFormat:@"身份证号:%@", idInfo.code]];
            CGSize size = [codeLabel.text sizeWithFont:nameLabel.font
                                     constrainedToSize:CGSizeMake(CGRectGetWidth(self.view.bounds), MAXFLOAT)
                                         lineBreakMode:NSLineBreakByWordWrapping];
            [codeLabel setFrame:CGRectMake(3, (3+size.height)*5, size.width, size.height)];
        }
        
        if (idInfo.issue != nil)
        {
            [issueLabel setText:[NSString stringWithFormat:@"签发机关:%@", idInfo.issue]];
            CGSize size = [issueLabel.text sizeWithFont:issueLabel.font
                                      constrainedToSize:CGSizeMake(CGRectGetWidth(self.view.bounds), MAXFLOAT)
                                          lineBreakMode:NSLineBreakByWordWrapping];
            [issueLabel setFrame:CGRectMake(3, (3+size.height)*6, size.width, size.height)];
        }
        
        if (idInfo.valid != nil)
        {
            [validLabel setText:[NSString stringWithFormat:@"有效期:%@", idInfo.valid]];
            CGSize size = [validLabel.text sizeWithFont:validLabel.font
                                      constrainedToSize:CGSizeMake(CGRectGetWidth(self.view.bounds), MAXFLOAT)
                                          lineBreakMode:NSLineBreakByWordWrapping];
            [validLabel setFrame:CGRectMake(3, (3+size.height)*7, size.width, size.height)];
        }
    });
    
    //NSLog(@"%@", [idInfo toString]);
    [_capture.captureSession stopRunning];
    
    /*****
     [self removeCapture];
     [self dismissViewControllerAnimated: YES completion:nil];
     
     if([self.delegate respondsToSelector:@selector(idCardRecognited:)])
     {
     [self.delegate idCardRecognited:idInfo];
     }
     *****/
}


@end
