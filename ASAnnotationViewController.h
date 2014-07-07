#ifndef __DISABLE_ANONSRC__

#import <UIKit/UIKit.h>

@class ASAnnotationViewController;
@protocol ASAnnotationViewControllerDelegate <NSObject>
- (void)annotationControllerDidFinish:(ASAnnotationViewController *)aController;
- (void)annotationControllerDidCancel:(ASAnnotationViewController *)aController;
@end

@interface ASAnnotationViewController : UIViewController
@property(nonatomic, weak) id<ASAnnotationViewControllerDelegate> delegate;

@property(nonatomic)           UIImage *screenshot;
@property(nonatomic, readonly) UIImage *annotatedScreenshot;

@property(nonatomic, weak) IBOutlet UIImageView *screenshotView;
@property(nonatomic, weak) IBOutlet UISegmentedControl *toolSelector;

- (IBAction)selectTool:(UISegmentedControl *)aSender;
- (IBAction)cancel:(id)aSender;
- (IBAction)finish:(id)aSender;
@end

@interface ASNavigationController : UINavigationController
@end

#endif
