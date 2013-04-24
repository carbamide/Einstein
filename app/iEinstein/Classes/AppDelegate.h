#import <UIKit/UIKit.h>

@class iEinsteinViewController;

@interface iEinsteinAppDelegate : NSObject <UIApplicationDelegate>
{
    IBOutlet UIWindow *window;
    IBOutlet iEinsteinViewController *viewController;
}

@property (strong, nonatomic) iEinsteinViewController *viewController;

@end
