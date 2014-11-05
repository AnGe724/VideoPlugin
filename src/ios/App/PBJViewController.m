//
//  PBJViewController.m
//  Vision
//
//  Created by Patrick Piemonte on 7/23/13.
//  Copyright (c) 2013-present, Patrick Piemonte, http://patrickpiemonte.com
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "PBJViewController.h"
#import "PBJStrobeView.h"
#import "PBJFocusView.h"
#import "PBJViewPlayer.h"


#import "PBJVision.h"
#import "PBJVisionUtilities.h"

#import <AssetsLibrary/AssetsLibrary.h>
#import <GLKit/GLKit.h>

#import "TYMProgressBarView.h"

@interface ExtendedHitButton : UIButton

+ (instancetype)extendedHitButton;

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event;


@end

@implementation ExtendedHitButton




+ (instancetype)extendedHitButton
{
    return (ExtendedHitButton *)[ExtendedHitButton buttonWithType:UIButtonTypeCustom];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    CGRect relativeFrame = self.bounds;
    UIEdgeInsets hitTestEdgeInsets = UIEdgeInsetsMake(-35, -35, -35, -35);
    CGRect hitFrame = UIEdgeInsetsInsetRect(relativeFrame, hitTestEdgeInsets);
    return CGRectContainsPoint(hitFrame, point);
}

@end

@interface PBJViewController () <
UIGestureRecognizerDelegate,
PBJVisionDelegate,
UIAlertViewDelegate,
PBJViewPlayerDelegate
>
{
    PBJStrobeView *_strobeView;
    UIButton *_doneButton;
    UIButton *_backButton;
    
    UIButton *_flipButton;
    UIButton *_focusButton;
    UIButton *_frameRateButton;
    UIButton *_onionButton;
    UIView *_captureDock;
    
    UIView *_previewView;
    AVCaptureVideoPreviewLayer *_previewLayer;
    PBJFocusView *_focusView;
    GLKViewController *_effectsViewController;
    
    UILabel *_instructionLabel;
    UIView *_gestureView;
    UILongPressGestureRecognizer *_longPressGestureRecognizer;
    UITapGestureRecognizer *_focusTapGestureRecognizer;
    
    BOOL _recording;
    TYMProgressBarView *appearance;
    ALAssetsLibrary *_assetLibrary;
    __block NSDictionary *_currentVideo;
}

@end

@implementation PBJViewController

#pragma mark - UIViewController
@synthesize timer = _timer;
@synthesize progressBarView = _progressBarView;

@synthesize delegate = _delegate;

int i = 0;
NSString *videoPath;
- (BOOL)prefersStatusBarHidden
{
    return NO;
}

#pragma mark - init

- (void)dealloc
{
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    _longPressGestureRecognizer.delegate = nil;
    //[super dealloc];
}

- (void)setTimer:(NSTimer *)timer
{
    if ([_timer isValid]) {
        [_timer invalidate];
    }
    _timer = timer;
}


- (TYMProgressBarView *)progressBarView
{
    if (!_progressBarView) {
        _progressBarView = [[TYMProgressBarView alloc] initWithFrame:CGRectZero];
        _progressBarView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _progressBarView.barBorderWidth = 0.0f;
        _progressBarView.barInnerPadding = 0.0f;
    }
    return _progressBarView;
}

- (void)incrementProgress:(NSTimer *)timer
{
    //self.progressBarView.progress = (float)self.progressBarView.progress + (float)0.0026;
    
    self.progressBarView.progress = (float)self.progressBarView.progress + (float)0.00010;

    
    // _doneButton.enabled = YES;
    
    if (self.progressBarView.progress >= 0.38f) {
        _doneButton.enabled = YES;
    }
    if (self.progressBarView.progress == 1.0f) {
        [self _handleDoneButton:_doneButton];
    }
}

-(UIColor*)colorWithHexString:(NSString*)hex
{
    NSString *cString = [[hex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    
    // String should be 6 or 8 characters
    if ([cString length] < 6) return [UIColor grayColor];
    
    // strip 0X if it appears
    if ([cString hasPrefix:@"0X"]) cString = [cString substringFromIndex:2];
    
    if ([cString length] != 6) return  [UIColor grayColor];
    
    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    NSString *rString = [cString substringWithRange:range];
    
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [UIColor colorWithRed:((float) r / 255.0f)
                           green:((float) g / 255.0f)
                            blue:((float) b / 255.0f)
                           alpha:1.0f];
}
int j=0;
#pragma mark - view lifecycle
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if(j==0){
        j=1;
    }else{
        [self viewDidLoad];
    }
    
    
    self.progressBarView.progress = 0.0f;
    
    // iOS 6 support
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    // [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    
    [self _resetCapture];
    [[PBJVision sharedInstance] startPreview];
    
    _serialQueue = dispatch_queue_create("getVideoPath", DISPATCH_QUEUE_SERIAL);

}
-(void)viewDidAppear:(BOOL)animated{
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    i = 0;
   
    //self.view.backgroundColor = [UIColor grayColor];
    [self.view setBackgroundColor: [self colorWithHexString:@"00CEE5"]];
    
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    _assetLibrary = [[ALAssetsLibrary alloc] init];
    
    CGFloat viewWidth = CGRectGetWidth(self.view.frame);
    
    // elapsed time and red dot
    _strobeView = [[PBJStrobeView alloc] initWithFrame:CGRectZero];
    CGRect strobeFrame = _strobeView.frame;
    strobeFrame.origin = CGPointMake(15.0f, 15.0f);
    _strobeView.frame = strobeFrame;
    [self.view addSubview:_strobeView];
    
    // done button
    _doneButton = [ExtendedHitButton extendedHitButton];
    _doneButton.frame = CGRectMake(viewWidth - 30.0f - 15.0f, 40.0f, 30.0f, 30.0f);
    UIImage *buttonImage = [UIImage imageNamed:@"video_sprites_Next"];
    [_doneButton setImage:buttonImage forState:UIControlStateNormal];
   // UIImage *buttonImage2 = [UIImage imageNamed:@"video_sprites_next-active"];
   // [_doneButton setImage:buttonImage2 forState:UIControlStateSelected];
    
    [_doneButton addTarget:self action:@selector(_handleDoneButton:) forControlEvents:UIControlEventTouchUpInside];
    _doneButton.enabled = NO;
    [self.view addSubview:_doneButton];
    
    _backButton = [ExtendedHitButton extendedHitButton];
    _backButton.frame = CGRectMake(15.0f, 40.0f, 30.0f, 30.0f);
    UIImage *buttonImage1 = [UIImage imageNamed:@"video_sprites_Close"];
    [_backButton setImage:buttonImage1 forState:UIControlStateNormal];
    [_backButton addTarget:self action:@selector(_handleBackButton:) forControlEvents:UIControlEventTouchUpInside];
    //_doneButton.enabled = NO;
    [self.view addSubview:_backButton];
    
    
    
    // preview and AV layer
    _previewView = [[UIView alloc] initWithFrame:CGRectZero];
    _previewView.backgroundColor = [UIColor cyanColor];
    CGRect previewFrame = CGRectMake(0, 90.0f, CGRectGetWidth(self.view.frame), CGRectGetWidth(self.view.frame));
    _previewView.frame = previewFrame;
    _previewLayer = [[PBJVision sharedInstance] previewLayer];
    _previewLayer.frame = _previewView.bounds;
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [_previewView.layer addSublayer:_previewLayer];
    
    // onion skin
    _effectsViewController = [[GLKViewController alloc] init];
    _effectsViewController.preferredFramesPerSecond = 60;
    
    GLKView *view = (GLKView *)_effectsViewController.view;
    CGRect viewFrame = _previewView.bounds;
    view.frame = viewFrame;
    view.context = [[PBJVision sharedInstance] context];
    view.contentScaleFactor = [[UIScreen mainScreen] scale];
    view.alpha = 0.5f;
    view.hidden = YES;
    [[PBJVision sharedInstance] setPresentationFrame:_previewView.frame];
    [_previewView addSubview:_effectsViewController.view];
    
    // focus view
    _focusView = [[PBJFocusView alloc] initWithFrame:CGRectZero];
    
    // instruction label
    _instructionLabel = [[UILabel alloc] initWithFrame:self.view.bounds];
    _instructionLabel.textAlignment = NSTextAlignmentCenter;
    _instructionLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15.0f];
    _instructionLabel.textColor = [UIColor blackColor];
    _instructionLabel.backgroundColor = [UIColor clearColor];
    _instructionLabel.text = NSLocalizedString(@"Touch and hold to record", @"Instruction message for capturing video.");
    [_instructionLabel sizeToFit];
    // CGPoint labelCenter = _previewView.center;
    //labelCenter.y += ((CGRectGetHeight(_previewView.frame) * 0.5f) + 35.0f);
    _instructionLabel.center = CGPointMake(160.0f, CGRectGetWidth(self.view.frame)-20);
    [_previewView addSubview:_instructionLabel];
    
    // touch to record
    _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_handleLongPressGestureRecognizer:)];
    _longPressGestureRecognizer.delegate = self;
    _longPressGestureRecognizer.minimumPressDuration = 0.05f;
    _longPressGestureRecognizer.allowableMovement = 10.0f;
    
    // tap to focus
    _focusTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_handleFocusTapGesterRecognizer:)];
    _focusTapGestureRecognizer.delegate = self;
    _focusTapGestureRecognizer.numberOfTapsRequired = 1;
    _focusTapGestureRecognizer.enabled = NO;
    [_previewView addGestureRecognizer:_focusTapGestureRecognizer];
    
    // gesture view to record
    _gestureView = [[UIView alloc] initWithFrame:CGRectZero];
    //CGRect gestureFrame = self.view.bounds;
    //gestureFrame.origin = CGPointMake(0, 60.0f);
    //gestureFrame.size.height -= (40.0f + 85.0f);
    CGRect gestureFrame = CGRectMake(0, 90.0f, CGRectGetWidth(self.view.frame), CGRectGetWidth(self.view.frame));
    _gestureView.frame = gestureFrame;
    [self.view addSubview:_gestureView];
    
    [_gestureView addGestureRecognizer:_longPressGestureRecognizer];
    
    
    // bottom dock
    _captureDock = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.bounds) - 100.0f, CGRectGetWidth(self.view.bounds), 100.0f)];
    _captureDock.backgroundColor =[self colorWithHexString:@"00CEE5"];
    
    // [self.view setBackgroundColor: [self colorWithHexString:@"3D3D3D"]];
    
    _captureDock.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    [self.view addSubview:_captureDock];
    
    CGFloat eachSectionWidth = viewWidth / 3;
    CGFloat eachSectionCenterWidth = (viewWidth / 3) / 2;
    CGFloat eachSectionHeight = CGRectGetHeight(self.view.bounds) - 90.0f - CGRectGetWidth(self.view.bounds);
    CGFloat eachSectionCenterHeight = (eachSectionHeight - 25.0f) / 2;
    CGFloat eachSectionCenterTop = 100.0f - eachSectionHeight + eachSectionCenterHeight;
    
    // flip button
    _flipButton = [ExtendedHitButton extendedHitButton];
    UIImage *flipImage = [UIImage imageNamed:@"video_sprites_revert"];
    [_flipButton setBackgroundImage:flipImage forState:UIControlStateNormal];
    //CGRect flipFrame = CGRectMake(35.0f, 8.0f, 25.0f, 25.0f);
    CGRect flipFrame = CGRectMake(eachSectionCenterWidth - 12.5f, eachSectionCenterTop, 25.0f, 25.0f);
    _flipButton.frame = flipFrame;
   [_flipButton setContentMode:UIViewContentModeScaleAspectFill];
    [_flipButton addTarget:self action:@selector(_handleFlipButton:) forControlEvents:UIControlEventTouchUpInside];
    [_captureDock addSubview:_flipButton];
    
    
    
    // focus mode button
    _focusButton = [ExtendedHitButton extendedHitButton];
    UIImage *focusImage = [UIImage imageNamed:@"video_sprites_Focus"];
    [_focusButton setBackgroundImage:focusImage forState:UIControlStateNormal];
    
    //CGRect focusFrame = _focusButton.frame;
    //focusFrame.origin = CGPointMake((CGRectGetWidth(self.view.bounds) * 0.5f) - (focusImage.size.width * 0.5f), 16.0f);
    //CGRect focusFrame = CGRectMake(260.0f, 8.0f, 25.0f, 25.0f);
    CGRect focusFrame = CGRectMake(viewWidth - eachSectionCenterWidth - 12.5f, eachSectionCenterTop, 25.0f, 25.0f);
    // focusFrame.size = focusImage.size;
    _focusButton.frame = focusFrame;
    [_focusButton setContentMode:UIViewContentModeScaleAspectFill];
    [_focusButton addTarget:self action:@selector(_handleFocusButton:) forControlEvents:UIControlEventTouchUpInside];
    [_captureDock addSubview:_focusButton];
    
    if ([[PBJVision sharedInstance] supportsVideoFrameRate:120]) {
        // set faster frame rate
    }
    
    // onion button
    _onionButton = [ExtendedHitButton extendedHitButton];
    UIImage *onionImage = [UIImage imageNamed:@"video_sprites_record inactive"];
    [_onionButton setBackgroundImage:onionImage forState:UIControlStateNormal];
    //CGRect onionFrame = CGRectMake(148.5f, 10.0f, 25.0f, 25.0f);
    CGRect onionFrame = CGRectMake(eachSectionWidth * 2 - eachSectionCenterWidth - 12.5f, eachSectionCenterTop, 25.0f, 25.0f);

    _onionButton.frame = onionFrame;
    [_onionButton setContentMode:UIViewContentModeScaleAspectFill];
    //_onionButton.imageView.frame = _onionButton.bounds;
    _onionButton.tag = 0;
    [_onionButton addTarget:self action:@selector(_handleOnionSkinningButton:) forControlEvents:UIControlEventTouchUpInside];
    [_captureDock addSubview:_onionButton];
    
    
    //[_onionButton addGestureRecognizer:_longPressGestureRecognizer];
    
    
    //progress view
    CGFloat width = (self.view.bounds.size.width - 120.0f);
    self.progressBarView.frame = CGRectMake(60.0f, 45.0f, width, 18.0f);
   // self.progressBarView.progress = self.progressBarView.progress + (float)0.01;
    [self.view addSubview:self.progressBarView];
    
    
    
    
    //self.timer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(incrementProgress:) userInfo:nil repeats:YES];
    
}




- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if ([_timer isValid]) {
        [_timer invalidate];
    }
    _timer = nil;
    NSArray *viewsToRemove = [self.view subviews];
    for (UIView *v in viewsToRemove) {
        [v removeFromSuperview];
    }
    
    _delegate = nil;
    
    [[PBJVision sharedInstance] stopPreview];
    [self _endCapture];
    [self _resetCapture];
    
    // iOS 6 support
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
}

#pragma mark - private start/stop helper methods

- (void)_startCapture
{
    
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.001 target:self selector:@selector(incrementProgress:) userInfo:nil repeats:YES];
    [_progressBarView setBarFillColor:[UIColor cyanColor]];
    
    /*if(i==1)
     {
     [_progressBarView setBarFillColor:[UIColor darkGrayColor]];
     i=0;
     
     }
     else{
     [_progressBarView setBarFillColor:[UIColor cyanColor]];
     i=1;
     }*/
    
    
    [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        _instructionLabel.alpha = 0;
        _instructionLabel.transform = CGAffineTransformMakeTranslation(0, 10.0f);
    } completion:^(BOOL finished) {
    }];
    [[PBJVision sharedInstance] startVideoCapture];
}

- (void)_pauseCapture
{
    
    if ([_timer isValid]) {
        [_timer invalidate];
    }
    _timer = nil;
    
    [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        _instructionLabel.alpha = 1;
        _instructionLabel.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
    }];
    
    [[PBJVision sharedInstance] pauseVideoCapture];
    _effectsViewController.view.hidden = !_onionButton.selected;
}

- (void)_resumeCapture
{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.001 target:self selector:@selector(incrementProgress:) userInfo:nil repeats:YES];
    
    [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        _instructionLabel.alpha = 0;
        _instructionLabel.transform = CGAffineTransformMakeTranslation(0, 10.0f);
    } completion:^(BOOL finished) {
    }];
    
    [[PBJVision sharedInstance] resumeVideoCapture];
    _effectsViewController.view.hidden = YES;
}

- (void)_endCapture
{
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [[PBJVision sharedInstance] endVideoCapture];
    _effectsViewController.view.hidden = YES;
}

- (void)_resetCapture
{
    [_strobeView stop];
    _longPressGestureRecognizer.enabled = YES;
    
    PBJVision *vision = [PBJVision sharedInstance];
    vision.delegate = self;
    
    if ([vision isCameraDeviceAvailable:PBJCameraDeviceBack]) {
        vision.cameraDevice = PBJCameraDeviceBack;
        _flipButton.hidden = NO;
    } else {
        vision.cameraDevice = PBJCameraDeviceFront;
        _flipButton.hidden = YES;
    }
    
    vision.cameraMode = PBJCameraModeVideo;
    vision.cameraOrientation = PBJCameraOrientationPortrait;
    vision.focusMode = PBJFocusModeContinuousAutoFocus;
    vision.outputFormat = PBJOutputFormatSquare;
    vision.videoRenderingEnabled = YES;
    vision.additionalCompressionProperties = @{AVVideoProfileLevelKey : AVVideoProfileLevelH264Baseline30}; // AVVideoProfileLevelKey requires specific captureSessionPreset
}

#pragma mark - UIButton

- (void)_handleFlipButton:(UIButton *)button
{
    if ([button isSelected]) {
        UIImage *flipImage = [UIImage imageNamed:@"video_sprites_revert"];
        [button setBackgroundImage:flipImage forState:UIControlStateNormal];
        [button setSelected:NO];
    } else {
        UIImage *flipImage = [UIImage imageNamed:@"video_sprites_revert inactive"];
        [button setBackgroundImage:flipImage forState:UIControlStateNormal];
        [button setSelected:YES];
    }
    
    PBJVision *vision = [PBJVision sharedInstance];
    vision.cameraDevice = vision.cameraDevice == PBJCameraDeviceBack ? PBJCameraDeviceFront : PBJCameraDeviceBack;
}

- (void)_handleFocusButton:(UIButton *)button
{
    
    
    _focusButton.selected = !_focusButton.selected;
    
    if (_focusButton.selected) {
        _focusTapGestureRecognizer.enabled = YES;
        _gestureView.hidden = YES;
        
        UIImage *flipImage = [UIImage imageNamed:@"video_sprites_Focus inactive"];
        [button setBackgroundImage:flipImage forState:UIControlStateNormal];
        [button setSelected:YES];
        
    } else {
        
        UIImage *flipImage = [UIImage imageNamed:@"video_sprites_Focus"];
        [button setBackgroundImage:flipImage forState:UIControlStateNormal];
        [button setSelected:NO];

        if (_focusView && [_focusView superview]) {
            [_focusView stopAnimation];
        }
        _focusTapGestureRecognizer.enabled = NO;
        _gestureView.hidden = NO;
    }
    
    [UIView animateWithDuration:0.15f delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        _instructionLabel.alpha = 0;
    } completion:^(BOOL finished) {
        _instructionLabel.text = _focusButton.selected ? NSLocalizedString(@"Touch to focus", @"Touch to focus") :
        NSLocalizedString(@"Touch and hold to record", @"Touch and hold to record");
        [UIView animateWithDuration:0.15f delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            _instructionLabel.alpha = 1;
        } completion:^(BOOL finished1) {
        }];
    }];
    
    

}

- (void)_handleFrameRateChangeButton:(UIButton *)button
{
    
}

- (void)_handleOnionSkinningButton:(UIButton *)button
{
    _onionButton.selected = !_onionButton.selected;
    
    //_onionButton.selected = YES;
    
    /* if (_recording)
     _effectsViewController.view.hidden = !_onionButton.selected;*/
    if (button.tag ==0){
        
        [button setImage:[UIImage imageNamed:@"video_sprites_Record active"] forState:UIControlStateNormal];
        [self _startCapture];
        button.tag = 1;
        
    }
    else if (button.tag == 1)
    {
        [button setImage:[UIImage imageNamed:@"video_sprites_record inactive"] forState:UIControlStateNormal];
        [self _pauseCapture];
        button.tag = 0;
    }
    else{
        [self _resumeCapture];
        
    }
  
}

- (void)_handleDoneButton:(UIButton *)button
{
    // resets long press
    _longPressGestureRecognizer.enabled = NO;
    _longPressGestureRecognizer.enabled = YES;
    
    [self _endCapture];
    
}
- (void)_handleBackButton:(UIButton *)button
{
    //Added the code to call the Callback function when clicked the backbutton on preview screen.
    dispatch_sync(_serialQueue, ^{
        if ([_delegate respondsToSelector:@selector(getVideoPath:)])
            [_delegate getVideoPath:@""];
    });

    // resets long press
    _longPressGestureRecognizer.enabled = NO;
    _longPressGestureRecognizer.enabled = YES;
    [[PBJVision sharedInstance] stopPreview];
    [self _endCapture];
    [self dismissViewControllerAnimated:NO completion:nil];
}


#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self _resetCapture];
}

#pragma mark - UIGestureRecognizer

- (void)_handleLongPressGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        {
            if (!_recording){
                [self _startCapture];
                
            }
            else
                [self _resumeCapture];
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        {
            [self _pauseCapture];
            break;
        }
        default:
            break;
    }
}


- (void)_handleFocusTapGesterRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint tapPoint = [gestureRecognizer locationInView:_previewView];
    
    // auto focus is occuring, display focus view
    CGPoint point = tapPoint;
    
    CGRect focusFrame = _focusView.frame;
#if defined(__LP64__) && __LP64__
    focusFrame.origin.x = rint(point.x - (focusFrame.size.width * 0.5));
    focusFrame.origin.y = rint(point.y - (focusFrame.size.height * 0.5));
#else
    focusFrame.origin.x = rintf(point.x - (focusFrame.size.width * 0.5f));
    focusFrame.origin.y = rintf(point.y - (focusFrame.size.height * 0.5f));
#endif
    [_focusView setFrame:focusFrame];
    
    [_previewView addSubview:_focusView];
    [_focusView startAnimation];
    
    CGPoint adjustPoint = [PBJVisionUtilities convertToPointOfInterestFromViewCoordinates:tapPoint inFrame:_previewView.frame];
    [[PBJVision sharedInstance] focusExposeAndAdjustWhiteBalanceAtAdjustedPoint:adjustPoint];
}

#pragma mark - PBJVisionDelegate

// session

- (void)visionSessionWillStart:(PBJVision *)vision
{
}

- (void)visionSessionDidStart:(PBJVision *)vision
{
    if (![_previewView superview]) {
        [self.view addSubview:_previewView];
        [self.view bringSubviewToFront:_gestureView];
    }
}

- (void)visionSessionDidStop:(PBJVision *)vision
{
    [_previewView removeFromSuperview];
}

// preview

- (void)visionSessionDidStartPreview:(PBJVision *)vision
{
    NSLog(@"Camera preview did start");
    
}

- (void)visionSessionDidStopPreview:(PBJVision *)vision
{
    NSLog(@"Camera preview did stop");
}

// device

- (void)visionCameraDeviceWillChange:(PBJVision *)vision
{
    NSLog(@"Camera device will change");
}

- (void)visionCameraDeviceDidChange:(PBJVision *)vision
{
    NSLog(@"Camera device did change");
}

// mode

- (void)visionCameraModeWillChange:(PBJVision *)vision
{
    NSLog(@"Camera mode will change");
}

- (void)visionCameraModeDidChange:(PBJVision *)vision
{
    NSLog(@"Camera mode did change");
}

// format

- (void)visionOutputFormatWillChange:(PBJVision *)vision
{
    NSLog(@"Output format will change");
}

- (void)visionOutputFormatDidChange:(PBJVision *)vision
{
    NSLog(@"Output format did change");
}

- (void)vision:(PBJVision *)vision didChangeCleanAperture:(CGRect)cleanAperture
{
}

// focus / exposure

- (void)visionWillStartFocus:(PBJVision *)vision
{
}

- (void)visionDidStopFocus:(PBJVision *)vision
{
    if (_focusView && [_focusView superview]) {
        [_focusView stopAnimation];
    }
}

- (void)visionWillChangeExposure:(PBJVision *)vision
{
}

- (void)visionDidChangeExposure:(PBJVision *)vision
{
    if (_focusView && [_focusView superview]) {
        [_focusView stopAnimation];
    }
}

// flash

- (void)visionDidChangeFlashMode:(PBJVision *)vision
{
    NSLog(@"Flash mode did change");
}

// photo

- (void)visionWillCapturePhoto:(PBJVision *)vision
{
}

- (void)visionDidCapturePhoto:(PBJVision *)vision
{
}

- (void)vision:(PBJVision *)vision capturedPhoto:(NSDictionary *)photoDict error:(NSError *)error
{
    // photo captured, PBJVisionPhotoJPEGKey
}

// video capture

- (void)visionDidStartVideoCapture:(PBJVision *)vision
{
    [_strobeView start];
    _recording = YES;
}

- (void)visionDidPauseVideoCapture:(PBJVision *)vision
{
    [_strobeView stop];
}

- (void)visionDidResumeVideoCapture:(PBJVision *)vision
{
    [_strobeView start];
}

- (void)vision:(PBJVision *)vision capturedVideo:(NSDictionary *)videoDict error:(NSError *)error
{
    _recording = NO;
    
    if (error && [error.domain isEqual:PBJVisionErrorDomain] && error.code == PBJVisionErrorCancelled) {
        NSLog(@"recording session cancelled");
        return;
    } else if (error) {
        NSLog(@"encounted an error in video capture (%@)", error);
        return;
    }
    
    _currentVideo = videoDict;

    videoPath = [_currentVideo  objectForKey:PBJVisionVideoPathKey];
    dispatch_sync(_serialQueue, ^{
        if ([_delegate respondsToSelector:@selector(getVideoPath:)])
            [_delegate getVideoPath:videoPath];
    });

    PBJViewPlayer *controller = [[PBJViewPlayer alloc] init];
    controller.vPath = videoPath;
    controller.delegate = self;
    [self presentViewController:controller animated:YES completion:nil];
    
    /*[_assetLibrary writeVideoAtPathToSavedPhotosAlbum:[NSURL URLWithString:videoPath] completionBlock:^(NSURL *assetURL, NSError *error1) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Video Saved!" message: @"Saved to the camera roll."
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"OK", nil];
        [alert show];
    }];*/
}

#pragma mark - PJViewPlayerDelegate
- (void)didReviewDone:(PBJViewPlayer *)player
{
    [self dismissViewControllerAnimated:NO completion:^(){
        [self _handleBackButton:nil];
    }];
    
    
    
}

// progress

- (void)visionDidCaptureAudioSample:(PBJVision *)vision
{
    //    NSLog(@"captured audio (%f) seconds", vision.capturedAudioSeconds);
}

- (void)visionDidCaptureVideoSample:(PBJVision *)vision
{
    //    NSLog(@"captured video (%f) seconds", vision.capturedVideoSeconds);
}

@end
