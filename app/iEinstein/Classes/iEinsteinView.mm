#import "iEinsteinView.h"
#import "TIOSScreenManager.h"
#import "InsertDiskView.h"

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
	_insertDiskView = [[InsertDiskView alloc] initWithFrame:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? CGRectMake(788, 0.0, 240.0, 1024) : CGRectMake(340, 0.0, 240.0, 480)];
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
    mScreenManager = sm;
}

- (void)setEmulator:(TEmulator *)em
{
    mEmulator = em;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef theContext = UIGraphicsGetCurrentContext();

    if (mScreenManager == NULL) {
        // Just fill black

        CGFloat black[] = { 0.0, 0.0, 0.0, 1.0 };
        CGRect frame = [self frame];
        CGContextSetFillColor(theContext, black);
        CGContextFillRect(theContext, frame);
    }
    else {
        if (mScreenImage == NULL) {
            CGColorSpaceRef theColorSpace = CGColorSpaceCreateDeviceRGB();

            newtonScreenWidth = mScreenManager->GetScreenWidth();
            newtonScreenHeight = mScreenManager->GetScreenHeight();

            mScreenImage = CGImageCreate(
                    newtonScreenWidth, newtonScreenHeight,
                    8, 32, newtonScreenWidth * sizeof(KUInt32),
                    theColorSpace,
                    kAlphaNoneSkipFirstPlusHostByteOrder,
                    ((TIOSScreenManager *)mScreenManager)->GetDataProvider(),
                    NULL, false,
                    kCGRenderingIntentDefault);

            CGColorSpaceRelease(theColorSpace);

            CGRect screenBounds = [[UIScreen mainScreen] bounds];
            CGRect r = [self frame];

            if (screenBounds.size.width > newtonScreenWidth && screenBounds.size.height > newtonScreenHeight) {
                if (newtonScreenWidth == newtonScreenHeight) {
                    // Newton screen resolution is square (like 320x320)

                    int mod = (int)screenBounds.size.width % newtonScreenWidth;
                    r.size.width -= mod;
                    r.size.height = r.size.width;
                }
                else {
                    // Newton screen resolution is rectangular (like 320x480)

                    int wmod = (int)r.size.width % newtonScreenWidth;
                    int hmod = (int)r.size.height % newtonScreenHeight;

                    if (wmod > hmod) {
                        r.size.width -= wmod;

                        int scale = (int)r.size.width / newtonScreenWidth;
                        r.size.height = newtonScreenHeight * scale;
                    }
                    else {
                        r.size.height -= hmod;

                        int scale = (int)r.size.height / newtonScreenHeight;
                        r.size.width = newtonScreenWidth * scale;
                    }
                }

                // Center image on screen

                r.origin.x += (screenBounds.size.width - r.size.width) / 2;
                r.origin.y += (screenBounds.size.height - r.size.height) / 2;
            }

            screenImageRect = CGRectIntegral(r);
        }

        CGContextSetInterpolationQuality(theContext, kCGInterpolationNone);
        CGContextDrawImage(theContext, screenImageRect, mScreenImage);
    }
}

- (void)reset
{
    mEmulator = NULL;
    mScreenManager = NULL;
    CGImageRelease(mScreenImage);
    mScreenImage = NULL;
}

- (void)setNeedsDisplayInNewtonRect:(NSValue *)v
{
    CGRect inRect = [v CGRectValue];
    CGRect r = screenImageRect;

    float wratio = r.size.width / newtonScreenWidth;
    float hratio = r.size.height / newtonScreenHeight;

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

    if (t) {
        if (!mEmulator->GetPlatformManager()->IsPowerOn()) {
            mEmulator->GetPlatformManager()->SendPowerSwitchEvent();
        }

        CGPoint p = [t locationInView:self];
        CGRect r = screenImageRect;
        int x = (1.0 - ((p.y - r.origin.y) / r.size.height)) * newtonScreenHeight;
        int y = ((p.x - r.origin.x) / r.size.width) * newtonScreenWidth;
        mScreenManager->PenDown(x, y);
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *t = [touches anyObject];

    if (t) {
        CGPoint p = [t locationInView:self];
        CGRect r = screenImageRect;
        int x = (1.0 - ((p.y - r.origin.y) / r.size.height)) * newtonScreenHeight;
        int y = ((p.x - r.origin.x) / r.size.width) * newtonScreenWidth;
        mScreenManager->PenDown(x, y);
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    mScreenManager->PenUp();
}

@end
