#import "AppDelegate.h"
#import "iEinsteinViewController.h"
#import "SSZipArchive.h"
#import "SVProgressHUD.h"
#import "SSZipArchive.h"

#include "Emulator/JIT/TJITPerformance.h"

@implementation AppDelegate

+(void)initialize
{
	NSNumber *screenChoice = nil;
	
	if ([[UIScreen mainScreen] bounds].size.height == 568) {
		screenChoice = @1;
	}
	else if ([[UIScreen mainScreen] bounds].size.height == 480) {
		screenChoice = @0;
	}
	else if ([[UIScreen mainScreen] bounds].size.height == 1024) {
		screenChoice = @4;
	}
	
    NSDictionary *defaults = @{@"screen_resolution": screenChoice,
							   @"clear_flash_ram": @NO,
							   @"sleep_screen": @NO,
							   @"auto_install": @NO,
							   @"delete_after_install": @NO};
	
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if (url != nil && [url isFileURL]) {
		NSString *docdir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
		
		if ([[url lastPathComponent] rangeOfString:@"pkg" options:NSCaseInsensitiveSearch].location != NSNotFound) {
			NSError *error = nil;
			
			[[NSFileManager defaultManager] copyItemAtURL:url toURL:[NSURL fileURLWithPath:[docdir stringByAppendingPathComponent:[url lastPathComponent]]] error:&error];
			
			if (!error) {
				[self alertWithTitle:@"Success" message:[NSString stringWithFormat:@"The file, %@, has been transferred to the package list.", [url lastPathComponent]]];
			}
			else {
				[self alertWithTitle:@"Error" message:[NSString stringWithFormat:@"The file, %@, has not been transferred to the package list.", [url lastPathComponent]]];

			}
		}
		else if ([[url lastPathComponent] rangeOfString:@"zip" options:NSCaseInsensitiveSearch].location != NSNotFound) {
			if ([SSZipArchive unzipFileAtPath:[url path] toDestination:docdir]) {
				[self alertWithTitle:@"Success" message:[NSString stringWithFormat:@"The file, %@, has been unzipped and transferred to the package list.", [url lastPathComponent]]];
			}
			else {
				[self alertWithTitle:@"Error" message:[NSString stringWithFormat:@"The file, %@, has not been transferred to the package list.", [url lastPathComponent]]];
			}
		}
		return YES;
	}
	
	return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [_window addSubview:[_viewController view]];
    [_window makeKeyAndVisible];
	
	[[UIApplication sharedApplication] setIdleTimerDisabled:![[NSUserDefaults standardUserDefaults] boolForKey:@"sleep_screen"]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangePreferences:) name:NSUserDefaultsDidChangeNotification object:nil];
	
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

- (void)didChangePreferences:(NSNotification *)aNotification
{
	[[UIApplication sharedApplication] setIdleTimerDisabled:![[NSUserDefaults standardUserDefaults] boolForKey:@"sleep_screen"]];
}

-(void)alertWithTitle:(NSString *)title message:(NSString *)message
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
													  message:message
													 delegate:nil
											cancelButtonTitle:@"OK"
											otherButtonTitles:nil, nil];
	
	[alert show];
}

@end
