#import "AppDelegate.h"
#import "iEinsteinViewController.h"

#include "Emulator/JIT/TJITPerformance.h"

#import "SVProgressHUD.h"

@implementation AppDelegate

+ (void)initialize
{
    NSDictionary *defaults = @{@"screen_resolution": @0,
                                @"clear_flash_ram": @NO};

    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [_window addSubview:[_viewController view]];
    [_window makeKeyAndVisible];

    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    bool clearFlash = [(NSNumber *)[prefs objectForKey:@"clear_flash_ram"] boolValue];

    if (clearFlash) {
        [prefs setValue:@NO forKey:@"clear_flash_ram"];
        [prefs synchronize];
        [_viewController stopEmulator];
        [_viewController verifyDeleteFlashRAM:4];
    }

	[SVProgressHUD showWithStatus:@"Loading Emulator..." maskType:SVProgressHUDMaskTypeClear];

    [_viewController initEmulator] ? NSLog(@"Succesfully initialized") : NSLog(@"Failure initializing");

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [_viewController stopEmulator];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if (![_viewController allResourcesFound]) {
        return;
    }

    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    bool clearFlash = [(NSNumber *)[prefs objectForKey:@"clear_flash_ram"] boolValue];

    if (clearFlash) {
        [prefs setValue:@NO forKey:@"clear_flash_ram"];
        [prefs synchronize];
        [_viewController stopEmulator];
        [_viewController verifyDeleteFlashRAM:1];
    }
    else {
        [_viewController startEmulator];
    }
}

@end