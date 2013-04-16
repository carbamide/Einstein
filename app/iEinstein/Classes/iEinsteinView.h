#import <UIKit/UIKit.h>
#include <K/Defines/KDefinitions.h>
#import "InsertDiskView.h"

class TScreenManager;
class TEmulator;

@interface iEinsteinView : UIView
{
    TScreenManager *mScreenManager;
    TEmulator *mEmulator;
    CGImageRef mScreenImage;
    CGRect screenImageRect;
    KUInt32 newtonScreenHeight;
    KUInt32 newtonScreenWidth;
}

@property (strong, nonatomic) InsertDiskView *insertDiskView;

- (void)reset;
- (void)setScreenManager:(TScreenManager *)sm;
- (void)setNeedsDisplayInNewtonRect:(NSValue *)v;

- (void)setEmulator:(TEmulator *)em;

@end
