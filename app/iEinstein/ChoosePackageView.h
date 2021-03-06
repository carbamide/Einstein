#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "DirectoryWatcher.h"


@class iEinsteinViewController;

@interface ChoosePackageView : UIView <UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate, MFMailComposeViewControllerDelegate, DirectoryWatcherDelegate>

@property (weak, nonatomic) iEinsteinViewController *delegate;
@property (strong, nonatomic) NSArray *diskFiles;
@property (strong, nonatomic) UITableView *table;
@property (strong, nonatomic) UINavigationBar *navBar;

- (void)hide;
- (void)show;
- (void)findDiskFiles;

@end
