#ifndef __DISABLE_ANONSRC__

#import <UIKit/UIKit.h>

@class ASAnnotationViewController;
@protocol ASAnnotationViewControllerDelegate <NSObject>
- (void)annotationControllerDidFinish:(ASAnnotationViewController *)aController;
- (void)annotationControllerDidCancel:(ASAnnotationViewController *)aController;
@end

@interface ASAnnotationViewController : UIViewController
@property(weak) id<ASAnnotationViewControllerDelegate> delegate;

@property(nonatomic)       UIImage *screenshot;
@property(readonly)        UIImage *annotatedScreenshot;

@property(weak) IBOutlet UIImageView *screenshotView;
@property(weak) IBOutlet UISegmentedControl *toolSelector;

- (IBAction)selectTool:(UISegmentedControl *)aSender;
- (IBAction)cancel:(id)aSender;
- (IBAction)finish:(id)aSender;
@end

@interface ASNavigationController : UINavigationController
@end

#endif