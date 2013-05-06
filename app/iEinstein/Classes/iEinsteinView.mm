#import "iEinsteinView.h"
#import "TIOSScreenManager.h"
#import "ChoosePackageView.h"
#import "SVProgressHUD.h"

#include "TInterruptManager.h"
#include "TPlatformManager.h"
#include "TEmulator.h"
#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>

@interface UITouch (Private)
-(float)_pathMajorRadius;
@end

@interface iEinsteinView ()
@property (nonatomic) CGColorSpaceRef theColorSpace;
@end
@implementation iEinsteinView


- (void)awakeFromNib
{
	_theColorSpace = CGColorSpaceCreateDeviceRGB();
	
	_choosePackageView = [[ChoosePackageView alloc] initWithFrame:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? CGRectMake(788, 0.0, 240.0, 1024) : CGRectMake(340, 0.0, 240.0, [[UIScreen mainScreen] bounds].size.height)];
	
	[self setMultipleTouchEnabled:YES];
	
	AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
	
	[_choosePackageView setDelegate:(iEinsteinViewController *)[appDelegate viewController]];
	
	[self addSubview:_choosePackageView];
	
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
	[_choosePackageView show];
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
//	[EAGLContext setCurrentContext:self.context];
	
    CGContextRef theContext = UIGraphicsGetCurrentContext();
	
    if (_mScreenManager == NULL) {
		glClearColor(0.0, 0.0, 0.0, 1.0);
		glClear(GL_COLOR_BUFFER_BIT);
    }
    else {
        if (_mScreenImage == NULL) {
			if (!_newtonScreenWidth) {
				_newtonScreenWidth = _mScreenManager->GetScreenWidth();
				_newtonScreenHeight = _mScreenManager->GetScreenHeight();
			}
			
			
            _mScreenImage = CGImageCreate(
										  _newtonScreenWidth,
										  _newtonScreenHeight,
										  8,
										  32,
										  _newtonScreenWidth * sizeof(KUInt32),
										  _theColorSpace,
										  kCGImageAlphaNone,
										  ((TIOSScreenManager *)_mScreenManager)->GetDataProvider(),
										  NULL,
										  false,
										  kCGRenderingIntentDefault);
			
            CGRect screenBounds = [[UIScreen mainScreen] bounds];
            CGRect r = [self frame];
			
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
			
			r.origin.x += (screenBounds.size.width - r.size.width) / 2;
			r.origin.y += (screenBounds.size.height - r.size.height) / 2;
			
            _screenImageRect = CGRectIntegral(r);
        }
		
		CGContextSetInterpolationQuality(theContext, kCGInterpolationNone);
		CGContextDrawImage(theContext, _screenImageRect, _mScreenImage);
	}
}

- (GLKMatrix4)modelMatrix
{
    GLKMatrix4 modelMatrix = GLKMatrix4Identity;
    modelMatrix = GLKMatrix4Translate(modelMatrix, self.frame.origin.x, self.frame.origin.y, 0);
	
    modelMatrix = GLKMatrix4Scale(modelMatrix, 1, 1, 1.0f);
	
    return modelMatrix;
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
	if ([SVProgressHUD isVisible]) {
		[SVProgressHUD dismiss];
	}
	
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
	if ([[touches anyObject] _pathMajorRadius] > 10) {
		return;
	}
	
	if ([[event touchesForView:self] count] == 1) {
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
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	if ([[touches anyObject] _pathMajorRadius] > 10) {
		return;
	}
	
	if ([[event touchesForView:self] count] == 1) {
		UITouch *t = [touches anyObject];
		
		CGPoint p = [t locationInView:self];
		CGRect r = _screenImageRect;
		
		int x = (1.0 - ((p.y - r.origin.y) / r.size.height)) * _newtonScreenHeight;
		int y = ((p.x - r.origin.x) / r.size.width) * _newtonScreenWidth;
		
		_mScreenManager->PenDown(x, y);
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	_mScreenManager->PenUp();
}

@end
