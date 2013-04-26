#import "AppDelegate.h"
#import "iEinsteinViewController.h"
#import "SSZipArchive.h"

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

-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if (url != nil && [url isFileURL]) {
		NSString *docdir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
		
		if ([[url pathExtension] isEqualToString:@"zip"] || [[url pathExtension] isEqualToString:@"ZIP"]) {
			[SSZipArchive unzipFileAtPath:[url absoluteString] toDestination:[docdir stringByAppendingPathComponent:[url lastPathComponent]]];
		}
		
		NSError *error = nil;
		
		[[NSFileManager defaultManager] copyItemAtURL:url toURL:[NSURL fileURLWithPath:[docdir stringByAppendingPathComponent:[url lastPathComponent]]] error:&error];
		
		if (!error) {
			UIAlertView *success = [[UIAlertView alloc] initWithTitle:@"Success"
															  message:[NSString stringWithFormat:@"The file, %@, has been transferred to the package list.", [url lastPathComponent]]
															 delegate:nil
													cancelButtonTitle:@"OK"
													otherButtonTitles:nil, nil];
			
			[success show];
		}
		else {
			UIAlertView *success = [[UIAlertView alloc] initWithTitle:@"Error"
															  message:[NSString stringWithFormat:@"The file, %@, has not been transferred to the package list.", [url lastPathComponent]]
															 delegate:nil
													cancelButtonTitle:@"OK"
													otherButtonTitles:nil, nil];
			
			[success show];
		}
	}
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [_window addSubview:[_viewController view]];
    [_window makeKeyAndVisible];
	
	NSString *docdir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"717006.rom" ofType:nil];
	NSString *filePath2 = [docdir stringByAppendingPathComponent:@"717006.rom"];
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:filePath2]) {
		[[NSFileManager defaultManager] copyItemAtPath:filePath toPath:filePath2 error:nil];
	}
	
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
