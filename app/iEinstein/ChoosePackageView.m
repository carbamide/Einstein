#import "ChoosePackageView.h"
#import <QuartzCore/QuartzCore.h>

@interface ChoosePackageView ()
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (strong, nonatomic) UITableViewCell *tempCell;
@property (strong, nonatomic) DirectoryWatcher *docWatcher;
@property (strong, nonatomic) NSArray *previousDocDirListing;

@end

@implementation ChoosePackageView

- (id)initWithFrame:(CGRect)rect
{
    if ((self = [super initWithFrame:rect]) != nil) {
		[self getDocDirListing];
		
        _diskFiles = @[];
        
        CGRect tableRect = CGRectMake(0.0, 32, rect.size.width, rect.size.height - 32);
        
        _table = [[UITableView alloc] initWithFrame:tableRect style:UITableViewStylePlain];
        [_table setDelegate:self];
        [_table setDataSource:self];
        
        [self addSubview:_table];
        
        _navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0.0, 0.0, rect.size.width, 32)];
        
        UINavigationItem *navItem = [[UINavigationItem alloc] initWithTitle:nil];
        
        UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(hide)];
        
        [navItem setRightBarButtonItem:button animated:NO];
        
        [_navBar pushNavigationItem:navItem animated:NO];
        
        [self addSubview:_navBar];
        
		[[self layer] setShadowColor:[[UIColor blackColor] CGColor]];
		[[self layer] setShadowOffset:CGSizeMake(0, 0)];
		[[self layer] setShadowRadius:15];
		[[self layer] setShadowOpacity:0.8];
        
        UIBezierPath *navBarMaskPath = [UIBezierPath bezierPathWithRoundedRect:[_navBar bounds] byRoundingCorners:(UIRectCornerTopLeft | UIRectCornerTopRight) cornerRadii:CGSizeMake(8.0, 8.0)];
        UIBezierPath *tableMaskPath = [UIBezierPath bezierPathWithRoundedRect:[_table bounds] byRoundingCorners:(UIRectCornerBottomLeft | UIRectCornerBottomRight) cornerRadii:CGSizeMake(8.0, 8.0)];
		
        CAShapeLayer *navBarMaskLayer = [[CAShapeLayer alloc] init];
        CAShapeLayer *tableMaskLayer = [[CAShapeLayer alloc] init];
		
        [navBarMaskLayer setFrame:[_navBar bounds]];
        [navBarMaskLayer setPath:[navBarMaskPath CGPath]];
        [tableMaskLayer setFrame:[_table bounds]];
        [tableMaskLayer setPath:[tableMaskPath CGPath]];
        
        [[_navBar layer] setMask:navBarMaskLayer];
        [[_table layer] setMask:tableMaskLayer];
        
        [self setBackgroundColor:[UIColor clearColor]];
        [self setOpaque:NO];
		
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didInsertDisk:) name:@"diskInserted" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEjectDisk:) name:@"diskEjected" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didCreateDisk:) name:@"diskCreated" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:_table selector:@selector(reloadData) name:@"diskIconUpdate" object:nil];
		
		_refreshControl = [[UIRefreshControl alloc] init];
		
		[_refreshControl addTarget:self action:@selector(updateTable) forControlEvents:UIControlEventValueChanged];
		
		[[self table] addSubview:_refreshControl];
		
		NSString *docdir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];

		[self setDocWatcher:[DirectoryWatcher watchFolderWithPath:docdir delegate:self]];
						
		[self directoryDidChange:[self docWatcher]];
    }
    
    return self;
}

-(void)updateTable
{
	[self findDiskFiles];
	
	[[self table] reloadData];
	
	[_refreshControl endRefreshing];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:_table];
}

- (void)hide
{
    [UIView animateWithDuration:0.3
                     animations:^{
                         [self setFrame:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? CGRectMake(788, 0.0, 240.0, 1024) : CGRectMake(340, 0.0, 240.0, 480)];
                     }
     
                     completion:nil];
}

- (void)show
{
    NSIndexPath *selectedRow = [_table indexPathForSelectedRow];
    
    if (selectedRow) [_table deselectRowAtIndexPath:selectedRow animated:NO];
    
    [UIView animateWithDuration:0.3
                     animations:^{
						 [self setFrame:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? CGRectMake(788 - 260.0, 0.0, 240.0, 1024) : CGRectMake(340 - 260, 0.0, 240.0, 480)];
                     }
     
                     completion:^(BOOL finished) {
                         [self findDiskFiles];
                         [_table reloadData];
                     }];
}

- (void)didCreateDisk:(NSNotification *)aNotification
{
    BOOL success = [[aNotification object] boolValue];
    
    if (success) {
        [self findDiskFiles];
        
        [_table reloadData];
	}
}

- (void)didEjectDisk:(NSNotification *)aNotification
{
    [_table reloadData];
}

- (void)didInsertDisk:(NSNotification *)aNotification
{
    [_table reloadData];
}

- (void)findDiskFiles
{
    _diskFiles = [self availableDiskImages];
}

- (NSArray *)availableDiskImages
{
	NSMutableArray *tempArray = [[NSMutableArray alloc] init];
	
	NSString *documentsDirectoryPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
	
	NSArray *documentsDirectoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectoryPath error:NULL];
	
    for (NSString *curFileName in [documentsDirectoryContents objectEnumerator]) {
        NSString *filePath = [documentsDirectoryPath stringByAppendingPathComponent:curFileName];
        
        if (!([curFileName isEqualToString:@"Inbox"])) {
			if ([[curFileName lastPathComponent] rangeOfString:@"pkg" options:NSCaseInsensitiveSearch].location != NSNotFound) {
				[tempArray addObject:filePath];
			}
			
			if ([[curFileName lastPathComponent] rangeOfString:@"zip" options:NSCaseInsensitiveSearch].location != NSNotFound) {
				[tempArray addObject:filePath];
			}
			
			BOOL isDirectory = NO;
			
			[[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];
			
			if (isDirectory) {
				[tempArray addObject:filePath];
			}
        }
	}
	
	return tempArray;
}

- (UIImage *)iconForDiskImageAtPath:(NSString *)path
{
    
    NSDictionary *fileAttrs = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:NULL];
    NSNumber *fileSize = [fileAttrs valueForKey:NSFileSize];
    
    UIImage *iconImage = nil;
    
    if ([fileSize longLongValue] < 1440 * 1024 + 100) {
        iconImage = [UIImage imageNamed:@"DiskListFloppy.png"];
    }
    else {
        iconImage = [UIImage imageNamed:@"DiskListHD.png"];
    }
    
    return iconImage;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_diskFiles count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"diskCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    NSString *diskPath = _diskFiles[[indexPath row]];
    
    [[cell imageView] setImage:[self iconForDiskImageAtPath:diskPath]];
    [[cell textLabel] setText:[diskPath lastPathComponent]];
	
	if ([[[diskPath lastPathComponent] pathExtension] isEqualToString:@".rom"] | [[[diskPath lastPathComponent] pathExtension] isEqualToString:@".ROM"] | [[[diskPath lastPathComponent] pathExtension] isEqualToString:@".img"] | [[[diskPath lastPathComponent] pathExtension] isEqualToString:@".IMG"] ) {
		[[cell textLabel] setTextColor:[UIColor redColor]];
	}
	
	BOOL isDirectory = FALSE;
	
	[[NSFileManager defaultManager] fileExistsAtPath:diskPath isDirectory:&isDirectory];
		
	if (isDirectory) {
		[[cell imageView] setImage:[UIImage imageNamed:@"folder"]];
	}
	
	if ([[diskPath lastPathComponent] rangeOfString:@"pkg" options:NSCaseInsensitiveSearch].location != NSNotFound) {
		[[cell imageView] setImage:[UIImage imageNamed:@"PackageIcon"]];
	}
	else if ([[diskPath lastPathComponent] rangeOfString:@"zip" options:NSCaseInsensitiveSearch].location != NSNotFound) {
		[[cell imageView] setImage:[UIImage imageNamed:@"PackageIcon - Zip"]];
	}
	
	[[cell textLabel] setTextColor:[UIColor blackColor]];
    
	UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(emailPackage:)];
	
	[cell addGestureRecognizer:longPressGesture];
	
    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *diskPath = _diskFiles[[indexPath row]];
    
	if ([[[diskPath lastPathComponent] pathExtension] isEqualToString:@".rom"] | [[[diskPath lastPathComponent] pathExtension] isEqualToString:@".ROM"] | [[[diskPath lastPathComponent] pathExtension] isEqualToString:@".img"] | [[[diskPath lastPathComponent] pathExtension] isEqualToString:@".IMG"] ) {
		return UITableViewCellEditingStyleNone;
	}
	
    if ([[NSFileManager defaultManager] isDeletableFileAtPath:diskPath]) {
        return UITableViewCellEditingStyleDelete;
    }
    
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *diskPath = _diskFiles[[indexPath row]];
        
        if ([[NSFileManager defaultManager] removeItemAtPath:diskPath error:NULL]) {
            [self findDiskFiles];
            
            [_table deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *diskPath = _diskFiles[[indexPath row]];
	
	UITableViewCell *tempCell = [tableView cellForRowAtIndexPath:indexPath];
	
	[tempCell setSelected:NO animated:YES];
	
    @try {
		if ([[[diskPath lastPathComponent] pathExtension] isEqualToString:@"rom"] | [[[diskPath lastPathComponent] pathExtension] isEqualToString:@"ROM"]) {
			UIAlertView *nothing = [[UIAlertView alloc] initWithTitle:@"Nothing!" message:@"This isn't implemented yet" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
			
			[nothing show];
		}
		
		if ([[[diskPath lastPathComponent] pathExtension] isEqualToString:@"pkg"] | [[[diskPath lastPathComponent] pathExtension] isEqualToString:@"PKG"]) {
			[[NSNotificationCenter defaultCenter] postNotificationName:@"install_file" object:nil userInfo:@{@"file": diskPath}];
		}
		
		BOOL isDirectory = FALSE;
		
		[[NSFileManager defaultManager] fileExistsAtPath:diskPath isDirectory:&isDirectory];
		
		if (isDirectory) {
			NSLog(@"This is a directory.");
		}
		
        [self hide];
    }
    @catch (NSException *e) {
        NSLog(@"An exception has occured in ChoosePackageView while selecting the row");
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    @try {
        return indexPath;
    }
    @catch (NSException *e) {
        NSLog(@"An exception has occured in ChoosePackageView when a row was about to enter the selected state");
    }
}

-(void)emailPackage:(UILongPressGestureRecognizer *)gesture
{
	if ([gesture state] == UIGestureRecognizerStateBegan) {
		UIActionSheet *emailSheet = [[UIActionSheet alloc] initWithTitle:@"Package Actions"
																delegate:self
													   cancelButtonTitle:@"Cancel"
												  destructiveButtonTitle:nil
													   otherButtonTitles:@"Email Package...", nil];
		
		[self setTempCell:(UITableViewCell *)[gesture view]];
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			[emailSheet showFromRect:[[gesture view] frame] inView:[self table] animated:YES];
		}
		else {
			[emailSheet showInView:self];
		}
	}
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
	
	if ([title isEqualToString:@"Email Package..."]) {
		NSLog(@"Email...");
		
		MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
		
		[controller setMailComposeDelegate:self];
		[controller setSubject:@"Newton Package"];
		[controller setModalPresentationStyle:UIModalPresentationFormSheet];

		NSIndexPath *indexPath = [[self table] indexPathForCell:[self tempCell]];
		
		NSString *diskPath = _diskFiles[[indexPath row]];
		
		NSData *data = [NSData dataWithContentsOfFile:diskPath];
		
		if (data) {
			[controller addAttachmentData:data mimeType:@"application/pkg" fileName:[diskPath lastPathComponent]];
		}
		
		[(UIViewController *)_delegate presentViewController:controller animated:YES completion:nil];
		
	}
	else {
		return;
	}
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error;
{
	if (result == MFMailComposeResultSent) {
		NSLog(@"It's away!");
	}
	
	[controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)directoryDidChange:(DirectoryWatcher *)folderWatcher
{    
	NSMutableArray *newListing = [[NSMutableArray alloc] init];
	
	NSString *documentsDirectoryPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
	
	NSArray *documentsDirectoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectoryPath error:NULL];
	
    for (NSString *curFileName in [documentsDirectoryContents objectEnumerator]) {
        NSString *filePath = [documentsDirectoryPath stringByAppendingPathComponent:curFileName];
        
        if (!([curFileName isEqualToString:@"Inbox"])) {
			if ([[curFileName lastPathComponent] rangeOfString:@"pkg" options:NSCaseInsensitiveSearch].location != NSNotFound) {
				[newListing addObject:filePath];
			}
			
			if ([[curFileName lastPathComponent] rangeOfString:@"zip" options:NSCaseInsensitiveSearch].location != NSNotFound) {
				[newListing addObject:filePath];
			}
			
			BOOL isDirectory = NO;
			
			[[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];
			
			if (isDirectory) {
				[newListing addObject:filePath];
			}
        }
	}
    
	[newListing removeObjectsInArray:[self previousDocDirListing]];
	
	for (NSString *tempString in newListing) {
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"auto_install"]) {
			[[NSNotificationCenter defaultCenter] postNotificationName:@"install_file" object:nil userInfo:@{@"file": tempString}];
		}
		NSLog(@"%@", tempString);
	}
	
    [self getDocDirListing];
}

-(void)getDocDirListing
{
	NSMutableArray *tempArray = [[NSMutableArray alloc] init];
	
	NSString *documentsDirectoryPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
	
	NSArray *documentsDirectoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectoryPath error:NULL];
	
    for (NSString *curFileName in [documentsDirectoryContents objectEnumerator]) {
        NSString *filePath = [documentsDirectoryPath stringByAppendingPathComponent:curFileName];
        
        if (!([curFileName isEqualToString:@"Inbox"])) {
			if ([[curFileName lastPathComponent] rangeOfString:@"pkg" options:NSCaseInsensitiveSearch].location != NSNotFound) {
				[tempArray addObject:filePath];
			}
			
			if ([[curFileName lastPathComponent] rangeOfString:@"zip" options:NSCaseInsensitiveSearch].location != NSNotFound) {
				[tempArray addObject:filePath];
			}
			
			BOOL isDirectory = NO;
			
			[[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];
			
			if (isDirectory) {
				[tempArray addObject:filePath];
			}
        }
	}
	
	[self setPreviousDocDirListing:tempArray];
}

@end
