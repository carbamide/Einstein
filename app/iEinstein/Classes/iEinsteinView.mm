#import "iEinsteinView.h"
#import "TIOSScreenManager.h"
#import "InsertDiskView.h"
#import "SVProgressHUD.h"

#include "TInterruptManager.h"
#include "TPlatformManager.h"
#include "TEmulator.h"

@implementation iEinsteinView

#if !(defined kCGBitmapByteOrder32Host) && TARGET_RT_BIG_ENDIAN
#define kAlphaNoneSkipFirstPlusHostByteOrder (kCGImageAlphaNoneSkipFirst)
#else
#define kAlphaNoneSkipFirstPlusHostByteOrder (kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Host)
#endif

- (void)awakeFromNib
{
	_insertDiskView = [[InsertDiskView alloc] initWithFrame:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? CGRectMake(788, 0.0, 240.0, 1024) : CGRectMake(340, 0.0, 240.0, [[UIScreen mainScreen] bounds].size.height)];
	
	[_insertDiskView setDelegate:(iEinsteinViewController *)[self superview]];
	
	[self addSubview:_insertDiskView];
	
	UISwipeGestureRecognizer *leftGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(installPackage)];
	
	[leftGesture setNumberOfTouchesRequired:2];
	[leftGesture setDirection:UISwipeGestureRecognizerDirectionLeft];
	
	[self addGestureRecognizer:leftGesture];
	
	UISwipeGestureRecognizer *upGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(menu)];
	
	[upGesture setNumberOfTouchesRequired:2];
	[upGesture setDirection:UISwipeGestureRecognizerDirectionUp];
	
	[self addGestureRecognizer:upGesture];
}

-(void)menu
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"menu" object:nil];
}

-(void)installPackage
{
	[_insertDiskView show];
}

- (void)setScreenManager:(TScreenManager *)sm
{
    _mScreenManager = sm;
}

- (void)setEmulator:(TEmulator *)em
{
    _mEmulator = em;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef theContext = UIGraphicsGetCurrentContext();
	
    if (_mScreenManager == NULL) {
        CGFloat black[] = { 0.0, 0.0, 0.0, 1.0 };
		
        CGRect frame = [self frame];
		
        CGContextSetFillColor(theContext, black);
        CGContextFillRect(theContext, frame);
    }
    else {
        if (_mScreenImage == NULL) {
            CGColorSpaceRef theColorSpace = CGColorSpaceCreateDeviceRGB();
			
            _newtonScreenWidth = _mScreenManager->GetScreenWidth();
            _newtonScreenHeight = _mScreenManager->GetScreenHeight();
			
            _mScreenImage = CGImageCreate(
										  _newtonScreenWidth, _newtonScreenHeight,
										  8, 32, _newtonScreenWidth * sizeof(KUInt32),
										  theColorSpace,
										  kAlphaNoneSkipFirstPlusHostByteOrder,
										  ((TIOSScreenManager *)_mScreenManager)->GetDataProvider(),
										  NULL, false,
										  kCGRenderingIntentDefault);
			
            CGColorSpaceRelease(theColorSpace);
			
            CGRect screenBounds = [[UIScreen mainScreen] bounds];
            CGRect r = [self frame];
			
            if (screenBounds.size.width > _newtonScreenWidth && screenBounds.size.height > _newtonScreenHeight) {
                if (_newtonScreenWidth == _newtonScreenHeight) {
                    // Newton screen resolution is square (like 320x320)
					
                    int mod = (int)screenBounds.size.width % _newtonScreenWidth;
                    r.size.width -= mod;
                    r.size.height = r.size.width;
                }
                else {
                    // Newton screen resolution is rectangular (like 320x480)
					
                    int wmod = (int)r.size.width % _newtonScreenWidth;
                    int hmod = (int)r.size.height % _newtonScreenHeight;
					
                    if (wmod > hmod) {
                        r.size.width -= wmod;
						
                        int scale = (int)r.size.width / _newtonScreenWidth;
                        r.size.height = _newtonScreenHeight * scale;
                    }
                    else {
                        r.size.height -= hmod;
						
                        int scale = (int)r.size.height / _newtonScreenHeight;
                        r.size.width = _newtonScreenWidth * scale;
                    }
                }
				
                // Center image on screen
				
                r.origin.x += (screenBounds.size.width - r.size.width) / 2;
                r.origin.y += (screenBounds.size.height - r.size.height) / 2;
            }
			
            _screenImageRect = CGRectIntegral(r);
        }
		
        CGContextSetInterpolationQuality(theContext, kCGInterpolationNone);
        CGContextDrawImage(theContext, _screenImageRect, _mScreenImage);
    }
}

- (void)reset
{
    _mEmulator = NULL;
    _mScreenManager = NULL;
    CGImageRelease(_mScreenImage);
    _mScreenImage = NULL;
}

- (void)setNeedsDisplayInNewtonRect:(NSValue *)v
{
	[SVProgressHUD dismiss];
	
    CGRect inRect = [v CGRectValue];
    CGRect r = _screenImageRect;
	
    float wratio = r.size.width / _newtonScreenWidth;
    float hratio = r.size.height / _newtonScreenHeight;
	
    int left = (inRect.origin.x * wratio) + r.origin.x;
    int top = (inRect.origin.y * hratio) + r.origin.y;
    int right = left + (inRect.size.width * wratio);
    int bottom = top + (inRect.size.height * hratio);
	
    CGRect outRect = CGRectMake(left, top, right - left + 1, bottom - top + 1);
	
    [self setNeedsDisplayInRect:outRect];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *t = [touches anyObject];
	
	if (!_mEmulator->GetPlatformManager()->IsPowerOn()) {
		_mEmulator->GetPlatformManager()->SendPowerSwitchEvent();
	}
	
	CGPoint p = [t locationInView:self];
	CGRect r = _screenImageRect;
	
	int x = (1.0 - ((p.y - r.origin.y) / r.size.height)) * _newtonScreenHeight;
	int y = ((p.x - r.origin.x) / r.size.width) * _newtonScreenWidth;
	
	_mScreenManager->PenDown(x, y);
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *t = [touches anyObject];
	
	CGPoint p = [t locationInView:self];
	CGRect r = _screenImageRect;
	
	int x = (1.0 - ((p.y - r.origin.y) / r.size.height)) * _newtonScreenHeight;
	int y = ((p.x - r.origin.x) / r.size.width) * _newtonScreenWidth;
	
	_mScreenManager->PenDown(x, y);
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    _mScreenManager->PenUp();
}

@end
