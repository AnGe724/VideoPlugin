
#import "VideoRecPreview.h"
#import "PBJViewController.h"

@implementation VideoRecPreview

#pragma mark Plugin Functions

- (void) startVideoRecordPreview:(CDVInvokedUrlCommand *)command {
    
    self.latestCommand = command;
    
    PBJViewController *pbjViewController = [[PBJViewController alloc] init];
    pbjViewController.delegate = self;
    [super.viewController presentViewController:pbjViewController animated:YES completion:nil];
}

#pragma mark PBJViewController Delegate

- (void) getVideoPath:(NSString *)path
{
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:path];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:_latestCommand.callbackId];
}

@end
