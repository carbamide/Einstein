#import "AppDelegate.h"
#import "iEinsteinViewController.h"
#import "SSZipArchive.h"

#include "Emulator/JIT/TJITPerformance.h"

#import "SVProgressHUD.h"
#import <XADMaster/XADPlatform.h>
#import <XADMaster/XADSimpleUnarchiver.h>

@implementation AppDelegate

+(void)initialize
{
    NSDictionary *defaults = @{@"screen_resolution": @0,
							   @"clear_flash_ram": @NO};
	
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if (url != nil && [url isFileURL]) {
		NSString *docdir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
		
		if ([[url lastPathComponent] rangeOfString:@"pkg"].location == NSNotFound) {
			NSLog(@"%@", [url filePathURL]);
			
			XADSimpleUnarchiver *unarchiver = [XADSimpleUnarchiver simpleUnarchiverForPath:[url path] error:NULL];
			[unarchiver setRemovesEnclosingDirectoryForSoloItems:YES];
			
			NSString *tmpdir = [NSString stringWithFormat:@".Temp"];
			NSString *tmpdest = [docdir stringByAppendingPathComponent:tmpdir];
			
			[unarchiver setDestination:tmpdest];
			[unarchiver setDelegate:self];
			[unarchiver setPropagatesRelevantMetadata:YES];
			[unarchiver setAlwaysRenamesFiles:YES];
			
			[unarchiver parse];
			
			[unarchiver unarchive];
		}
		else {
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

-(NSString *)describeXADError:(XADError)error
{
	switch(error)
	{
		case XADNoError:			return nil;
		case XADUnknownError:		return @"Unknown error";
		case XADInputError:			return @"Attempted to read more data than was available";
		case XADOutputError:		return @"Failed to write to file";
		case XADBadParametersError:	return @"Function called with illegal parameters";
		case XADOutOfMemoryError:	return @"Not enough memory available";
		case XADIllegalDataError:	return @"Data is corrupted";
		case XADNotSupportedError:	return @"File is not fully supported";
		case XADResourceError:		return @"Required resource missing";
		case XADDecrunchError:		return @"Error on decrunching";
		case XADFiletypeError:		return @"Unknown file type";
		case XADOpenFileError:		return @"Opening file failed";
		case XADSkipError:			return @"File, disk has been skipped";
		case XADBreakError:			return @"User cancelled extraction";
		case XADFileExistsError:	return @"File already exists";
		case XADPasswordError:		return @"Missing or wrong password";
		case XADMakeDirectoryError:	return @"Could not create directory";
		case XADChecksumError:		return @"Wrong checksum";
		case XADVerifyError:		return @"Verify failed (disk hook)";
		case XADGeometryError:		return @"Wrong drive geometry";
		case XADDataFormatError:	return @"Unknown data format";
		case XADEmptyError:			return @"Source contains no files";
		case XADFileSystemError:	return @"Unknown filesystem";
		case XADFileDirectoryError:	return @"Name of file exists as directory";
		case XADShortBufferError:	return @"Buffer was too short";
		case XADEncodingError:		return @"Text encoding was defective";
		case XADLinkError:			return @"Could not create symlink";
		default:					return [NSString stringWithFormat:@"Error %d",error];
	}
}@end
