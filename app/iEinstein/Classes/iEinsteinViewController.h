#import "IASKAppSettingsViewController.h"

#include <K/Defines/KDefinitions.h>
#import <UIKit/UIKit.h>

class TNetworkManager;
class TSoundManager;
class TScreenManager;
class TROMImage;
class TEmulator;
class TPlatformManager;
class TLog;

@interface iEinsteinViewController : UIViewController <IASKSettingsDelegate, UIActionSheetDelegate>

@property (nonatomic) TNetworkManager *mNetworkManager;
@property (nonatomic) TSoundManager *mSoundManager;
@property (nonatomic) TScreenManager *mScreenManager;
@property (nonatomic) TROMImage *mROMImage;
@property (nonatomic) TEmulator *mEmulator;
@property (nonatomic) TPlatformManager *mPlatformManager;
@property (nonatomic) TLog *mLog;
@property (nonatomic) int lastKnownScreenResolution;

- (BOOL)initEmulator;
- (void)startEmulator;
- (void)stopEmulator;
- (void)resetEmulator;
- (void)openEinsteinMenu:(NSValue *)v;
- (void)verifyDeleteFlashRAM:(int)withTag;
- (void)explainMissingROM;

- (int)allResourcesFound;

@end

extern void openEinsteinMenu(iEinsteinViewController *);

