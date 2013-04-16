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
		
		mPlatformManager->InstallPackage([diskPath UTF8String]);
		
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
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:@"Clear Flash Memory?\r\r"
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
		[actionSheet showInView:self.view];
	}
}


- (void)explainMissingROM
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:@"Newton ROM not found.\r\r"
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
		[actionSheet showInView:self.view];
	}}

- (void)openEinsteinMenu:(NSValue *)v
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:@"Einstein Menu"
								  delegate:self
								  cancelButtonTitle:@"Cancel"
								  destructiveButtonTitle:@"Quit Emulator"
								  otherButtonTitles:@"Settings", nil];
	
	[actionSheet setDelegate:self];
	
    [actionSheet setTag:2];
    actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[actionSheet showFromRect:CGRectMake(768 / 2, 1024, 0, 0) inView:[self view] animated:YES];
	}
	else {
		[actionSheet showInView:self.view];
	}}

/*
 * // Override to allow orientations other than the default portrait orientation.
 * - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 *  // Return YES for supported orientations
 *  return (interfaceOrientation == UIInterfaceOrientationPortrait);
 * }
 */


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload
{
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)installNewPackages
{
    if (mPlatformManager) {
        //mPlatformManager->InstallNewPackages();
    }
}

- (void)dealloc
{
    if (mEmulator) {
        delete mEmulator;
        mEmulator = NULL;
    }
	
    if (mScreenManager) {
        delete mScreenManager;
        mScreenManager = NULL;
    }
	
    if (mNetworkManager) {
        delete mNetworkManager;
        mNetworkManager = NULL;
    }
	
    if (mSoundManager) {
        delete mSoundManager;
        mSoundManager = NULL;
    }
	
    if (mROMImage) {
        delete mROMImage;
        mROMImage = NULL;
    }
	
    if (mLog) {
        delete mLog;
        mLog = NULL;
    }
}

- (BOOL)initEmulator
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
	
    printf("Initializing the emulator\n");
	
    mNetworkManager = NULL;
    mSoundManager = NULL;
    mScreenManager = NULL;
    mROMImage = NULL;
    mEmulator = NULL;
    mPlatformManager = NULL;
    mLog = NULL;
	
    // Create a log if possible
    //#ifdef _DEBUG
    mLog = new TStdOutLog();
    //#endif
	
    NSString *docdir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
	
    // Create the ROM.
	
    NSString *einsteinRExPath = nil;
    NSBundle *thisBundle = [NSBundle mainBundle];
	
    if (!(einsteinRExPath = [thisBundle pathForResource:@"Einstein" ofType:@"rex"]) ) {
        //[self abortWithMessage: @"Couldn't load Einstein REX"];
        mLog->LogLine("Couldn't load Einstein REX");
        return FALSE;
    }
	
    NSString *theROMPath = [docdir stringByAppendingPathComponent:@"717006.rom"];
    NSString *theDebugROMPath = [docdir stringByAppendingPathComponent:@"717006.aif"];
    NSString *theDebugHighROMPath = [docdir stringByAppendingPathComponent:@"717006.rex"];
    NSString *theImagePath = [docdir stringByAppendingPathComponent:@"717006.img"];
	
    NSFileManager *theFileManager = [NSFileManager defaultManager];
	
    if ([theFileManager fileExistsAtPath:theROMPath]) {
        mROMImage = new TFlatROMImageWithREX(
											 [theROMPath fileSystemRepresentation],
											 [einsteinRExPath fileSystemRepresentation],
											 "717006", false,
											 [theImagePath fileSystemRepresentation]);
    }
    else if ([theFileManager fileExistsAtPath:theDebugROMPath]
             && [theFileManager fileExistsAtPath:theDebugHighROMPath]) {
        mROMImage = new TAIFROMImageWithREXes(
											  [theDebugROMPath fileSystemRepresentation],
											  [theDebugHighROMPath fileSystemRepresentation],
											  [einsteinRExPath fileSystemRepresentation],
											  "717006");
    }
    else {
        fprintf(stderr, "ROM file required here:\n %s\nor here:\n %s\n %s\n\n",
                [theROMPath fileSystemRepresentation],
                [theDebugROMPath fileSystemRepresentation],
                [theDebugHighROMPath fileSystemRepresentation]);
        //[self abortWithMessage: @"ROM file not found"];
        [self explainMissingROM];
        mROMImage = 0L;
        return FALSE;
    }
	
    // Create the network manager.
	
    mNetworkManager = new TNullNetwork(mLog);
	
    // Create the sound manager.
	
    mSoundManager = new TCoreAudioSoundManager(mLog);
	
    // iPad is 1024x768. This size, and some appropriate scaling factors, should be selectable from
    // the 'Settings' panel.
	
    static int widthLUT[]  = { 320, 640, 384,  786 };
    static int heightLUT[] = { 480, 960, 512, 1024 };
	
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    int index = [(NSNumber *)[prefs objectForKey:@"screen_resolution"] intValue];
    int newtonScreenWidth = widthLUT[index];
    int newtonScreenHeight = heightLUT[index];
	
    iEinsteinView *einsteinView = (iEinsteinView *)[self view];
    Boolean isLandscape = (newtonScreenWidth > newtonScreenHeight);
	
    mScreenManager = new TIOSScreenManager(
										   einsteinView,
										   self,
										   mLog,
										   newtonScreenWidth, newtonScreenHeight,
										   true,
										   isLandscape);
	
    [einsteinView setScreenManager:mScreenManager];
	
    // Create the emulator.
	
    NSString *theFlashPath = [docdir stringByAppendingPathComponent:@"flash"];
    printf("Flash file is %s\n", [theFlashPath fileSystemRepresentation]);
	
    mEmulator = new TEmulator(
							  mLog, mROMImage, [theFlashPath fileSystemRepresentation],
							  mSoundManager, mScreenManager, mNetworkManager, 0x40 << 16);
	
    mPlatformManager = mEmulator->GetPlatformManager();
    mPlatformManager->SetDocDir([docdir fileSystemRepresentation]);
	
    [einsteinView setEmulator:mEmulator];
	
    ((TIOSScreenManager *)mScreenManager)->SetPlatformManager(mPlatformManager);
	
    return TRUE;
}

- (void)startEmulator
{
    // See if screen resolution has changed since last time
	
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	
    [prefs synchronize];
    int currentScreenResolution = [(NSNumber *)[prefs objectForKey:@"screen_resolution"] intValue];
	
    if (currentScreenResolution != lastKnownScreenResolution) {
        // Reboot emulator
		
        mLog->LogLine("Newton screen resolution changed by Settings.");
        lastKnownScreenResolution = currentScreenResolution;
        [self resetEmulator];
    }
	
    // Start the thread.
	
    mLog->LogLine("Detaching emulator thread");
    [NSThread detachNewThreadSelector:@selector(emulatorThread) toTarget:self withObject:nil];
}

- (void)emulatorThread
{
    @autoreleasepool {
        mEmulator->Run();
    }
}

- (int)allResourcesFound
{
    return (mEmulator != 0L)
	& (mNetworkManager != 0L)
	& (mSoundManager != 0L)
	& (mScreenManager != 0L)
	& (mROMImage != 0L);
}

- (void)resetEmulator
{
    mLog->LogLine("Resetting emulator");
	
    [(iEinsteinView *)[self view] reset];
	
    delete mEmulator;
    mEmulator = NULL;
	
    delete mNetworkManager;
    mNetworkManager = NULL;
	
    delete mSoundManager;
    mSoundManager = NULL;
	
    delete mScreenManager;
    mScreenManager = NULL;
	
    delete mROMImage;
    mROMImage = NULL;
	
    // Emulator deletes platform manager in its destructor
    mPlatformManager = NULL;
	
    delete mLog;
    mLog = NULL;
	
    [self initEmulator] ? NSLog(@"Succesfully initialized") : NSLog(@"Failure initializing");
}

- (void)stopEmulator
{
    mLog->LogLine("Stopping emulator thread");
	
    mEmulator->Stop();
}

- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController*)sender
{
    [sender dismissViewControllerAnimated:YES completion:nil];
	
	UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:@"Restart for changes to take effect." delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Quit" otherButtonTitles:nil, nil];
	
	[actionSheet setDelegate:self];
	
    [actionSheet setTag:5];
    actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
    [actionSheet showInView:self.view];
}

@end
