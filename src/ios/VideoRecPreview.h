
#import <CoreLocation/CoreLocation.h>
#import <Cordova/CDVPlugin.h>

#import "PBJViewController.h"



//=====================================================
// DGGeofencing
//=====================================================

@interface VideoRecPreview : CDVPlugin <PBJViewControllerDelegate>

@property (strong, nonatomic) CDVInvokedUrlCommand* latestCommand;

#pragma mark Plugin Functions
- (void) startVideoRecordPreview:(CDVInvokedUrlCommand*)command;

@end
