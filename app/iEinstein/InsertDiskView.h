#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class iEinsteinViewController;

@interface InsertDiskView : UIView <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) iEinsteinViewController *delegate;
@property (strong, nonatomic) NSArray *diskFiles;
@property (strong, nonatomic) UITableView *table;
@property (strong, nonatomic) UINavigationBar *navBar;

- (void)hide;
- (void)show;
- (void)findDiskFiles;

@end
