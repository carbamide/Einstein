#import "iEinsteinAppDelegate.h"
#import "iEinsteinViewController.h"

#include "Emulator/JIT/TJITPerformance.h"

#import "SVProgressHUD.h"

@implementation iEinsteinAppDelegate

@synthesize viewController = viewController;

+ (void)initialize
{
    NSDictionary *defaults = @{ @"screen_resolution": @0,
                                @"clear_flash_ram": @NO };

    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [window addSubview:[viewController view]];
    [window makeKeyAndVisible];

    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    bool clearFlash = [(NSNumber *)[prefs objectForKey:@"clear_flash_ram"] boolValue];

    if (clearFlash) {
        [prefs setValue:@NO forKey:@"clear_flash_ram"];
        [prefs synchronize];
        [viewController stopEmulator];
        [viewController verifyDeleteFlashRAM:4];
    }

	[SVProgressHUD showWithStatus:@"Loading Emulator..." maskType:SVProgressHUDMaskTypeClear];

    [viewController initEmulator] ? NSLog(@"Succesfully initialized") : NSLog(@"Failure initializing");

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [viewController stopEmulator];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if (![viewController allResourcesFound]) {
        return;
    }

    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    bool clearFlash = [(NSNumber *)[prefs objectForKey:@"clear_flash_ram"] boolValue];

    if (clearFlash) {
        [prefs setValue:@NO forKey:@"clear_flash_ram"];
        [prefs synchronize];
        [viewController stopEmulator];
        [viewController verifyDeleteFlashRAM:1];
    }
    else {
        [viewController startEmulator];
    }
}

@end
