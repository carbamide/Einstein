#import "iEinsteinViewController.h"

#include "Emulator/TEmulator.h"
#include "Emulator/Log/TStdOutLog.h"
#include "Emulator/ROM/TROMImage.h"
#include "Emulator/ROM/TFlatROMImageWithREX.h"
#include "Emulator/ROM/TAIFROMImageWithREXes.h"
#include "Emulator/Network/TNetworkManager.h"
#include "Emulator/Sound/TCoreAudioSoundManager.h"
#include "Emulator/Screen/TIOSScreenManager.h"
#include "Emulator/Platform/TPlatformManager.h"

@implementation iEinsteinViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	[[NSNotificationCenter defaultCenter] addObserverForName:@"install_file" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *aNotification) {
		NSString *diskPath = [aNotification userInfo][@"file"];
		
		_mPlatformManager->InstallPackage([diskPath UTF8String]);
	}];
	
	[[NSNotificationCenter defaultCenter] addObserverForName:@"menu" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *aNotification) {
		[self openEinsteinMenu:nil];
		
	}];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch ([actionSheet tag]) {
        case 4: {
            if (buttonIndex == 0) {
                NSString *docdir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
                NSString *theFlashPath = [docdir stringByAppendingPathComponent:@"flash"];
				
                remove([theFlashPath fileSystemRepresentation]);
				
                NSString *theLastInstallPath = [docdir stringByAppendingPathComponent:@".lastInstall"];
				
                remove([theLastInstallPath fileSystemRepresentation]);
				
                [self resetEmulator];
                [self startEmulator];
            }
            else if ([actionSheet tag] == 1) {
                [self startEmulator];
            }
            else {
				[self initEmulator] ? NSLog(@"Succesfully initialized") : NSLog(@"Failure initializing");
            }
            break;
		}
        case 2: {
            switch (buttonIndex) {
                case 0: {
			 		[[[UIApplication sharedApplication] delegate] applicationWillTerminate:[UIApplication sharedApplication]];
					
			 		exit(0);
					
					break;
				}
                case 1: {
					IASKAppSettingsViewController *viewController = [[IASKAppSettingsViewController alloc] init];
					
					UINavigationController *aNavController = [[UINavigationController alloc] initWithRootViewController:viewController];
					[viewController setShowDoneButton:YES];
					[viewController setDelegate:self];
					
					if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
						[viewController setModalPresentationStyle:UIModalPresentationFormSheet];
					}
					
					[self presentViewController:aNavController animated:YES completion:nil];
					
			  		break;
			 	}
				case 2: {
			  		break;
			 	}
            }
            break;
		}
        case 3: {
			[[[UIApplication sharedApplication] delegate] applicationWillTerminate:[UIApplication sharedApplication]];
			
            exit(0);
			
            break;
		}
		case 5: {
			switch (buttonIndex) {
                case 0: {
			 		[[[UIApplication sharedApplication] delegate] applicationWillTerminate:[UIApplication sharedApplication]];
					
			 		exit(0);
					
					break;
				}
				case 1:
					break;
			}
		}
    }
}

- (void)verifyDeleteFlashRAM:(int)withTag;
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Clear Flash Memory?\r\r"
                                  "Clearing the Flash will delete all packages that may "
                                  "have been installed and completely reset your Newton."
															 delegate:self
													cancelButtonTitle:@"Cancel"
											   destructiveButtonTitle:@"Clear the Flash!"
													otherButtonTitles:nil];
    [actionSheet setTag:withTag];
    actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[actionSheet showFromRect:CGRectMake(768 / 2, 1024, 0, 0) inView:[self view] animated:YES];
	}
	else {
		[actionSheet showInView:[self view]];
	}
}


- (void)explainMissingROM
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Newton ROM not found.\r\r"
                                  "Einstein Emulator requires an MP2x00 US ROM image. "
                                  "The ROM file must be named 717006.rom and copied to "
                                  "this device using the iTunes File Sharing feature.\r\r"
                                  "For more information please read the instructions at "
                                  "http://code.google.com/p/einstein/wiki/iOS"
															 delegate:self
													cancelButtonTitle:@"Quit Einstein"
											   destructiveButtonTitle:nil
													otherButtonTitles:nil];
	
    [actionSheet setTag:3];
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[actionSheet showFromRect:CGRectMake(768 / 2, 1024, 0, 0) inView:[self view] animated:YES];
	}
	else {
		[actionSheet showInView:[self view]];
	}}

- (void)openEinsteinMenu:(NSValue *)v
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Einstein Menu"
															 delegate:self
													cancelButtonTitle:@"Cancel"
											   destructiveButtonTitle:@"Quit Emulator"
													otherButtonTitles:@"Settings", nil];
	
	[actionSheet setDelegate:self];
	
    [actionSheet setTag:2];
	[actionSheet setActionSheetStyle:UIActionSheetStyleDefault];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[actionSheet showFromRect:CGRectMake(768 / 2, 1024, 0, 0) inView:[self view] animated:YES];
	}
	else {
		[actionSheet showInView:[self view]];
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    if (_mEmulator) {
        delete _mEmulator;
        _mEmulator = NULL;
    }
	
    if (_mScreenManager) {
        delete _mScreenManager;
        _mScreenManager = NULL;
    }
	
    if (_mNetworkManager) {
        delete _mNetworkManager;
        _mNetworkManager = NULL;
    }
	
    if (_mSoundManager) {
        delete _mSoundManager;
        _mSoundManager = NULL;
    }
	
    if (_mROMImage) {
        delete _mROMImage;
        _mROMImage = NULL;
    }
	
    if (_mLog) {
        delete _mLog;
        _mLog = NULL;
    }
}

- (BOOL)initEmulator
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
	
    printf("Initializing the emulator\n");
	
    _mNetworkManager = NULL;
    _mSoundManager = NULL;
    _mScreenManager = NULL;
    _mROMImage = NULL;
    _mEmulator = NULL;
    _mPlatformManager = NULL;
    _mLog = NULL;
	
    // Create a log if possible
    //#ifdef _DEBUG
    //_mLog = new TStdOutLog();
    //#endif
	
    NSString *docdir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *einsteinRExPath = nil;
    NSBundle *thisBundle = [NSBundle mainBundle];
	
    if (!(einsteinRExPath = [thisBundle pathForResource:@"Einstein" ofType:@"rex"]) ) {
        _mLog->LogLine("Couldn't load Einstein REX");
        return FALSE;
    }
	
    NSString *theROMPath = [docdir stringByAppendingPathComponent:@"717006.rom"];
    NSString *theDebugROMPath = [docdir stringByAppendingPathComponent:@"717006.aif"];
    NSString *theDebugHighROMPath = [docdir stringByAppendingPathComponent:@"717006.rex"];
    NSString *theImagePath = [docdir stringByAppendingPathComponent:@"717006.img"];
	
    NSFileManager *theFileManager = [NSFileManager defaultManager];
	
    if ([theFileManager fileExistsAtPath:theROMPath]) {
        _mROMImage = new TFlatROMImageWithREX([theROMPath fileSystemRepresentation], [einsteinRExPath fileSystemRepresentation], "717006", false, [theImagePath fileSystemRepresentation]);
    }
    else if ([theFileManager fileExistsAtPath:theDebugROMPath] && [theFileManager fileExistsAtPath:theDebugHighROMPath]) {
        _mROMImage = new TAIFROMImageWithREXes([theDebugROMPath fileSystemRepresentation], [theDebugHighROMPath fileSystemRepresentation], [einsteinRExPath fileSystemRepresentation], "717006");
    }
    else {
        fprintf(stderr, "ROM file required here:\n %s\nor here:\n %s\n %s\n\n", [theROMPath fileSystemRepresentation], [theDebugROMPath fileSystemRepresentation], [theDebugHighROMPath fileSystemRepresentation]);
		
        [self explainMissingROM];
		
        _mROMImage = 0L;
		
        return FALSE;
    }
	
    _mNetworkManager = new TNullNetwork(_mLog);
	
    _mSoundManager = new TCoreAudioSoundManager(_mLog);
	
    static int widthLUT[]  = { 320, 320, 640, 640, 384,  786 };
    static int heightLUT[] = { 480, 568, 960, 1136, 512, 1024 };
	
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	
    int index = [(NSNumber *)[prefs objectForKey:@"screen_resolution"] intValue];
    int newtonScreenWidth = widthLUT[index];
    int newtonScreenHeight = heightLUT[index];
	
    iEinsteinView *einsteinView = (iEinsteinView *)[self view];
		
    Boolean isLandscape = (newtonScreenWidth > newtonScreenHeight);
	
    _mScreenManager = new TIOSScreenManager(einsteinView, self, _mLog, newtonScreenWidth, newtonScreenHeight, true, isLandscape);
	
    [einsteinView setScreenManager:_mScreenManager];
	
    NSString *theFlashPath = [docdir stringByAppendingPathComponent:@"flash"];
		
    _mEmulator = new TEmulator(_mLog, _mROMImage, [theFlashPath fileSystemRepresentation], _mSoundManager, _mScreenManager, _mNetworkManager, 0x40 << 16);
	
    _mPlatformManager = _mEmulator->GetPlatformManager();
    _mPlatformManager->SetDocDir([docdir fileSystemRepresentation]);
	
    [einsteinView setEmulator:_mEmulator];
	
    ((TIOSScreenManager *)_mScreenManager)->SetPlatformManager(_mPlatformManager);
	
    return TRUE;
}

- (void)startEmulator
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	
    [prefs synchronize];
    int currentScreenResolution = [(NSNumber *)[prefs objectForKey:@"screen_resolution"] intValue];
	
    if (currentScreenResolution != _lastKnownScreenResolution) {
        _mLog->LogLine("Newton screen resolution changed by Settings.");
		
        _lastKnownScreenResolution = currentScreenResolution;
		
        [self resetEmulator];
    }
	
    _mLog->LogLine("Detaching emulator thread");
	
    [NSThread detachNewThreadSelector:@selector(emulatorThread) toTarget:self withObject:nil];
}

- (void)emulatorThread
{
    @autoreleasepool {
        _mEmulator->Run();
    }
}

- (int)allResourcesFound
{
    return (_mEmulator != 0L)
	& (_mNetworkManager != 0L)
	& (_mSoundManager != 0L)
	& (_mScreenManager != 0L)
	& (_mROMImage != 0L);
}

- (void)resetEmulator
{
    _mLog->LogLine("Resetting emulator");
	
    [(iEinsteinView *)[self view] reset];
	
    delete _mEmulator;
    _mEmulator = NULL;
	
    delete _mNetworkManager;
    _mNetworkManager = NULL;
	
    delete _mSoundManager;
    _mSoundManager = NULL;
	
    delete _mScreenManager;
    _mScreenManager = NULL;
	
    delete _mROMImage;
    _mROMImage = NULL;
	
    _mPlatformManager = NULL;
	
    delete _mLog;
    _mLog = NULL;
	
    [self initEmulator] ? NSLog(@"Succesfully initialized") : NSLog(@"Failure initializing");
}

- (void)stopEmulator
{
    _mLog->LogLine("Stopping emulator thread");
	
    _mEmulator->Stop();
}

- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController*)sender
{
    [sender dismissViewControllerAnimated:YES completion:nil];
	
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Restart for changes to take effect."
															 delegate:self
													cancelButtonTitle:@"Cancel"
											   destructiveButtonTitle:@"Quit"
													otherButtonTitles:nil, nil];
	
	[actionSheet setDelegate:self];
    [actionSheet setTag:5];
	[actionSheet setActionSheetStyle:UIActionSheetStyleDefault];
	
    [actionSheet showInView:[self view]];
}

@end
