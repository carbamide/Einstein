//
//  DirectoryWatcher.h
//  Einstein
//
//  Created by Josh Barrow on 4/29/13.
//
//

#import <Foundation/Foundation.h>

@class DirectoryWatcher;

@protocol DirectoryWatcherDelegate <NSObject>
@required
- (void)directoryDidChange:(DirectoryWatcher *)folderWatcher;
@end

@interface DirectoryWatcher : NSObject
{
    id <DirectoryWatcherDelegate> __weak delegate;
    
    int dirFD;
    int kq;
	
    CFFileDescriptorRef dirKQRef;
}
@property (nonatomic, weak) id <DirectoryWatcherDelegate> delegate;

+ (DirectoryWatcher *)watchFolderWithPath:(NSString *)watchPath delegate:(id<DirectoryWatcherDelegate>)watchDelegate;
- (void)invalidate;
@end
