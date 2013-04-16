#ifndef EINSTEIN_VIEW_CONTROLLER_H
#define EINSTEIN_VIEW_CONTROLLER_H
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
{
    TNetworkManager *mNetworkManager;
    TSoundManager *mSoundManager;
    TScreenManager *mScreenManager;
    TROMImage *mROMImage;
    TEmulator *mEmulator;
    TPlatformManager *mPlatformManager;
    TLog *mLog;
    int lastKnownScreenResolution;
}

- (void)installNewPackages;

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

#endif // ifndef EINSTEIN_VIEW_CONTROLLER_H
