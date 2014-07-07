#ifndef __DISABLE_ANONSRC__

#import "ASAnnotationViewController.h"
#import <FConvenience/FConvenience.h>

@interface ASAnnotationLayer : CAShapeLayer {
    @protected
    CGPoint _startPoint, _endPoint;
}
@property CGPoint startPoint, endPoint;

+ (instancetype)annotationWithStartPoint:(CGPoint)aPoint;
- (void)updateFrameWithEndPoint:(CGPoint)aPoint;
@end

@interface ASArrowAnnotation : ASAnnotationLayer
@end

@interface ASBoxAnnotation : ASAnnotationLayer
@end

@interface ASAnnotationViewController () {
    Class _annotationLayerClass;
    ASAnnotationLayer *_annotation, *_selectedAnnotation;
}
@end

@implementation ASAnnotationViewController
@dynamic annotatedScreenshot;

- (id)init
{
    return [self initWithNibName:NSStringFromClass([self class]) bundle:Bundle];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    _screenshotView.image = _screenshot;

    [_toolSelector setTitleTextAttributes:@{ UITextAttributeFont: [UIFont fontWithName:@"Apple Color Emoji"
                                                                                  size:17] }
                                 forState:UIControlStateNormal];
    
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self
                                                                            action:@selector(_handleTap:)]];
    
    [self.view addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                            action:@selector(_updateAnnotation:)]];
    [self selectTool:_toolSelector];
}

- (void)viewWillAppear:(BOOL const)aAnimated
{
    [super viewWillAppear:aAnimated];
    
    if(self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
        _screenshotView.transform = CGAffineTransformMakeRotation(M_PI);
    else if(self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft)
        _screenshotView.transform = CGAffineTransformMakeRotation(M_PI_2);
    else if(self.interfaceOrientation == UIInterfaceOrientationLandscapeRight)
        _screenshotView.transform = CGAffineTransformMakeRotation(-M_PI_2);
}

- (void)setScreenshot:(UIImage * const)aScreenshot
{
    _screenshot           = aScreenshot;
    _screenshotView.image = aScreenshot;
}

- (UIImage *)annotatedScreenshot
{
    UIGraphicsBeginImageContext(self.view.bounds.size);
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage * const annotatedScreenshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return annotatedScreenshot;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (IBAction)selectTool:(UISegmentedControl * const)aSender
{
    _annotationLayerClass = _toolSelector.selectedSegmentIndex == 0
                          ? [ASArrowAnnotation class]
                          : [ASBoxAnnotation class];
}

- (void)_handleTap:(UITapGestureRecognizer * const)aTapRecognizer
{
    CGPoint const loc = [aTapRecognizer locationInView:self.view];
    NSIndexSet * const annotationIndexes = [self.view.layer.sublayers
                                            indexesOfObjectsPassingTest:^BOOL(id layer, NSUInteger _, BOOL *__) {
        return [layer isKindOfClass:[ASAnnotationLayer class]];
    }];
    NSArray * const annotations = [self.view.layer.sublayers objectsAtIndexes:annotationIndexes];
    
    for(ASAnnotationLayer *annotation in [annotations reverseObjectEnumerator]) {
        CGPoint           const pos       = annotation.position;
        CGAffineTransform const transform = CGAffineTransformMakeTranslation(-pos.x, -pos.y);
        if(CGPathContainsPoint(annotation.path, &transform, loc, false)) {
            UIMenuController * const menuController = [UIMenuController sharedMenuController];
            if(!menuController.menuVisible) {
                [self.view becomeFirstResponder];
                [menuController setTargetRect:annotation.frame inView:self.view];
                menuController.menuItems = @[[[UIMenuItem alloc] initWithTitle:@"Delete"
                                                                        action:@selector(deleteSelectedAnnotation:)]];
                
                [NotificationCenter addObserver:self selector:@selector(_menuControllerWillHide)
                                           name:UIMenuControllerWillHideMenuNotification
                                         object:menuController];
                
                [menuController setMenuVisible:YES animated:YES];
            }
            _selectedAnnotation = annotation;
            return;
        }
    }
    // Else
    [self toggleNavigationBar:nil];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)deleteSelectedAnnotation:(id const)aSender
{
    [_selectedAnnotation removeFromSuperlayer];
}

- (void)_menuControllerWillHide
{
    _selectedAnnotation = nil;
}

- (void)_updateAnnotation:(UIPanGestureRecognizer * const)aPanRecognizer
{
    CGPoint const loc = [aPanRecognizer locationInView:self.view];
    switch(aPanRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            CGPoint const trans = [aPanRecognizer translationInView:self.view];
            CGPoint const startLoc = CGPointApplyAffineTransform(loc, CGAffineTransformMakeTranslation(-trans.x, -trans.y));
            _annotation = [_annotationLayerClass annotationWithStartPoint:startLoc];
            [self.view.layer addSublayer:_annotation];
        } break;
        case UIGestureRecognizerStateChanged:
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            [_annotation updateFrameWithEndPoint:loc];
            [CATransaction commit];
            break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            [_annotation removeFromSuperlayer];
            break;
        case UIGestureRecognizerStateRecognized:
            _annotation = nil;
            break;
        default:
            break;
    }
}

- (void)toggleNavigationBar:(id const)aSender
{
    [self.navigationController setNavigationBarHidden:!self.navigationController.navigationBarHidden
                                             animated:YES];
}

- (IBAction)cancel:(id const)aSender
{
    [_delegate annotationControllerDidCancel:self];
}

- (IBAction)finish:(id const)aSender
{
    [_delegate annotationControllerDidFinish:self];
}

@end


#pragma mark - Annotations

@implementation ASAnnotationLayer

+ (instancetype)annotationWithStartPoint:(CGPoint const)aStartPoint
{
    ASAnnotationLayer * const annotation = [self new];
    annotation.anchorPoint = (CGPoint) { 0, 0 };
    annotation.fillColor   = nil;
    annotation.strokeColor = RGB(0.00,0.48, 1).CGColor;
    annotation.lineWidth   = 3;
    
    annotation.shadowColor   = GRAY(0).CGColor;
    annotation.shadowOpacity = 0.4;
    annotation.shadowOffset  = (CGSize) { 1, 2 };
    annotation.shadowRadius  = 2;
    
    annotation->_startPoint = aStartPoint;
    annotation->_endPoint   = aStartPoint;
    [annotation updatePath];
    return annotation;
}

- (void)updatePath {}

- (void)updateFrameWithEndPoint:(CGPoint const)aEndPoint
{
    _endPoint = aEndPoint;
    CGPoint const origin = { MIN(_startPoint.x, _endPoint.x), MIN(_startPoint.y, _endPoint.y) };
    CGSize  const size   = { MAX(_startPoint.x, _endPoint.x) - origin.x, MAX(_startPoint.y, _endPoint.y) - origin.y };
    self.frame = (CGRect) { origin, size };
    [self updatePath];
}

@end

@implementation ASArrowAnnotation
+ (instancetype)annotationWithStartPoint:(CGPoint const)aStartPoint
{
    ASArrowAnnotation * const annotation = [super annotationWithStartPoint:aStartPoint];
    annotation.fillColor = annotation.strokeColor;
    annotation.lineWidth = 0;
    return annotation;
}

- (void)updatePath
{
    CGPoint const startPoint = [self convertPoint:_startPoint fromLayer:self.superlayer];
    CGPoint const endPoint   = [self convertPoint:_endPoint   fromLayer:self.superlayer];
    CGFloat const length     = hypotf(endPoint.x - startPoint.x, endPoint.y - startPoint.y);

    CGFloat const headLength = MAX(length/3.0f, 10.0f);
    CGFloat const headWidth  = headLength * 0.9f;
    
    CGFloat const tailLength = length - headLength;
    CGFloat const tailWidth  = MAX(4.0f, tailLength/10.0f);
    
    CGPoint const points[7] = {
        CGPointMake(0, tailWidth / 2),
        CGPointMake(tailLength, tailWidth / 2),
        CGPointMake(tailLength, headWidth / 2),
        CGPointMake(length, 0),
        CGPointMake(tailLength, -headWidth / 2),
        CGPointMake(tailLength, -tailWidth / 2),
        CGPointMake(0, -tailWidth / 2)
    };
    
    CGFloat const cosine = (endPoint.x - startPoint.x) / length;
    CGFloat const sine   = (endPoint.y - startPoint.y) / length;
    CGAffineTransform const transform = (CGAffineTransform){ cosine, sine, -sine, cosine, startPoint.x, startPoint.y };
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddLines(path, &transform, points, sizeof(points) / sizeof(*points));
    CGPathCloseSubpath(path);
    
    self.path = path;
    CFRelease(path);
}
@end

@implementation ASBoxAnnotation
- (void)updatePath
{
    CGRect const bounds = self.bounds;
    float  const radius = MIN((bounds.size.width * bounds.size.height) / 500.0f, 10);
    self.path = [[UIBezierPath bezierPathWithRoundedRect:bounds
                                       byRoundingCorners:UIRectCornerAllCorners
                                             cornerRadii:(CGSize) { radius, radius }] CGPath];
}
@end

#pragma mark -

@implementation ASNavigationController

- (BOOL)shouldAutorotate
{
    return self.visibleViewController.shouldAutorotate;
}
- (NSUInteger)supportedInterfaceOrientations
{
    return self.visibleViewController.supportedInterfaceOrientations;
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation const)aOrien
{
    NSUInteger const mask = [self supportedInterfaceOrientations];
    if(   (aOrien == UIInterfaceOrientationPortrait           && mask & UIInterfaceOrientationMaskPortrait)
       || (aOrien == UIInterfaceOrientationPortraitUpsideDown && mask & UIInterfaceOrientationMaskPortraitUpsideDown)
       || (aOrien == UIInterfaceOrientationLandscapeLeft      && mask & UIInterfaceOrientationMaskLandscapeLeft)
       || (aOrien == UIInterfaceOrientationLandscapeRight     && mask & UIInterfaceOrientationMaskLandscapeRight)
       )
        return [self shouldAutorotate];
    else
        return NO;
}

@end

#endif