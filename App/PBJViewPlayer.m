//
//  PBJViewController.m
//  Player
//
//  Created by Patrick Piemonte on 11/12/13.
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

#import "PBJViewPlayer.h"
#import "PBJVideoPlayerController.h"
#import "PBJViewController.h"


@interface PBJViewPlayer () <
    PBJVideoPlayerControllerDelegate>
{
    PBJVideoPlayerController *_videoPlayerController;
   // UIImageView *_playButton;
}

@end

@implementation PBJViewPlayer
@synthesize vPath;

#pragma mark - UIViewController status bar

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - view lifecycle
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setBackgroundColor: [self colorWithHexString:@"0BE7D5"]];
   
    UILabel *myLabel = [[UILabel alloc]initWithFrame:CGRectMake(73, 35, 200, 40)];
    [myLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Bold" size:18.0]];
    //myLabel.font = [UIFont boldSystemFontOfSize:15.0];
    [myLabel setBackgroundColor:[UIColor clearColor]];
    myLabel.textColor = [UIColor whiteColor];
    [myLabel setText:@"Review your glance"];
    [[self view] addSubview:myLabel];
    
    

    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    _videoPlayerController = [[PBJVideoPlayerController alloc] init];
    _videoPlayerController.delegate = self;
    _videoPlayerController.view.frame = CGRectMake(0, 90.0f, CGRectGetWidth(self.view.frame), CGRectGetWidth(self.view.frame));    //self.view.bounds;
    
   // [self addChildViewController:_videoPlayerController];
    [self.view addSubview:_videoPlayerController.view];
    //[_videoPlayerController didMoveToParentViewController:self];

    /*_playButton = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"play_button"]];
    _playButton.center = self.view.center;
    [self.view addSubview:_playButton];
    [self.view bringSubviewToFront:_playButton];*/
    
    CGFloat viewWidth = CGRectGetWidth(self.view.frame);
    UIButton *doneButton = [[UIButton alloc]init];
    doneButton.frame = CGRectMake(viewWidth - 30.0f - 15.0f, 40.0f, 30.0f, 30.0f);
    UIImage *buttonImage = [UIImage imageNamed:@"video_sprites_Next"];
    [doneButton setImage:buttonImage forState:UIControlStateNormal];
   
    
    [doneButton addTarget:self action:@selector(_handleDoneButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:doneButton];
    
    
    UIButton *backButton = [[UIButton alloc]init];
    backButton.frame = CGRectMake(15.0f, 40.0f, 30.0f, 30.0f);
    UIImage *buttonImage1 = [UIImage imageNamed:@"video_sprites_Close"];
    [backButton setImage:buttonImage1 forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(_handleBackButton:) forControlEvents:UIControlEventTouchUpInside];
    //_doneButton.enabled = NO;
    [self.view addSubview:backButton];
    
    _videoPlayerController.videoPath = vPath;    
}

- (void)_handleBackButton:(UIButton *)button
{
     [_videoPlayerController pause];
     
    _videoPlayerController = nil;
    _videoPlayerController.view = nil;
    _videoPlayerController.delegate = nil;
    [_videoPlayerController.view removeFromSuperview];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    
}

- (void)_handleDoneButton:(UIButton *)button
{
}


#pragma mark - PBJVideoPlayerControllerDelegate

- (void)videoPlayerReady:(PBJVideoPlayerController *)videoPlayer
{
    //NSLog(@"Max duration of the video: %f", videoPlayer.maxDuration);
}

- (void)videoPlayerPlaybackStateDidChange:(PBJVideoPlayerController *)videoPlayer
{
}

- (void)videoPlayerPlaybackWillStartFromBeginning:(PBJVideoPlayerController *)videoPlayer
{
}

- (void)viewWillDisappear:(BOOL)animated
{
    [_videoPlayerController pause];
    
    _videoPlayerController = nil;
    _videoPlayerController.view = nil;
    _videoPlayerController.delegate = nil;
    [_videoPlayerController.view removeFromSuperview];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewWillDisappear:animated];
}

- (void)videoPlayerPlaybackDidEnd:(PBJVideoPlayerController *)videoPlayer
{
    /*_playButton.hidden = NO;

    [UIView animateWithDuration:0.1f animations:^{
        _playButton.alpha = 1.0f;
    } completion:^(BOOL finished) {
    }];*/
}

@end
