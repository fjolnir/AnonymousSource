#ifndef __DISABLE_ANONSRC__

#import "ASReporter.h"
#import "ASAnnotationViewController.h"
#import <FConvenience/FConvenience.h>
#import <MessageUI/MessageUI.h>
#import <asl.h>

@interface UIViewController ()
- (void)                   attentionClassDumpUser:(id)a
                                    yesItsUsAgain:(id)b
althoughSwizzlingAndOverridingPrivateMethodsIsFun:(id)c
          itWasntMuchFunWhenYourAppStoppedWorking:(id)d
 pleaseRefrainFromDoingSoInTheFutureOkayThanksBye:(id)e;
@end

@interface UIViewController (ASReporter)
- (UIViewController *)as_visibleViewController;
@end

@interface ASReporter () <ASAnnotationViewControllerDelegate, MFMailComposeViewControllerDelegate> {
    NSMutableArray *_logMessages;
    ASAnnotationViewController * _annotationController;
}
@end

@implementation ASReporter

+ (instancetype)sharedReporter
{
    return Memoize([super new]);
}

+ (void)prepare
{
    [[self sharedReporter] prepare];
}

+ (void)setEmail:(NSString * const)aEmail
{
    [[self sharedReporter] setEmail:aEmail];
}

- (instancetype)init
{
    if((self = [super init]))
        _logMessages = [NSMutableArray new];
    return self;
}
- (UIWindow *)window
{
    return UIApp.keyWindow
        ?: [UIApp.windows lastObject];
}

- (void)prepare
{
    dispatch_async(dispatch_get_main_queue(), ^{
        for(int i = 0; i < 4; ++i) {
            UISwipeGestureRecognizer * const recognizer = [[UISwipeGestureRecognizer alloc]
                                                         initWithTarget:self
                                                                 action:@selector(show)];
            recognizer.numberOfTouchesRequired = 2;
            recognizer.direction = i==0 ? UISwipeGestureRecognizerDirectionLeft
                                 : i==1 ? UISwipeGestureRecognizerDirectionRight
                                 : i==2 ? UISwipeGestureRecognizerDirectionDown
                                 :        UISwipeGestureRecognizerDirectionUp;
            [[self window] addGestureRecognizer:recognizer];
        }
    });
}

- (void)show
{
    if(_annotationController)
        return;

    if(![MFMailComposeViewController canSendMail]) {
        [[[UIAlertView alloc] initWithTitle:@"Cannot Send Report"
                                    message:@"Your device is not set up to send emails."
                                        delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
        return;
    }
    UIStoryboard * const storyboard = [UIStoryboard storyboardWithName:@"ASReporter"
                                                                bundle:[NSBundle bundleForClass:[self class]]];
    UINavigationController * const container = [storyboard instantiateInitialViewController];
    _annotationController = [container.viewControllers firstObject];
    _annotationController.delegate    = self;
    _annotationController.screenshot  = FScreenshot(0);
    [[[[self window] rootViewController] as_visibleViewController] presentViewController:container
                                                                                animated:YES
                                                                              completion:nil];
    
    Async(^{
        [self refreshLogMessages];
    });
}

- (void)annotationControllerDidFinish:(ASAnnotationViewController * const)aController
{
    MFMailComposeViewController * const composer = [MFMailComposeViewController new];
    composer.mailComposeDelegate = self;
    [composer setToRecipients:@[_email ?: @""]];
    [composer setSubject:@"Bug: "];

    
    [composer setMessageBody:NSFormat(@"\n\n\n––– Log:\n\n%@",
                                      [[_logMessages valueForKey:@(ASL_KEY_MSG)] componentsJoinedByString:@"\n\n"])
                      isHTML:NO];
    [composer addAttachmentData:UIImagePNGRepresentation(aController.annotatedScreenshot)
                       mimeType:@"image/png"
                       fileName:@"Screenshot.png"];
    [aController.navigationController presentViewController:composer animated:YES completion:nil];
}
- (void)annotationControllerDidCancel:(ASAnnotationViewController * const)aController
{
    [_annotationController.presentingViewController dismissViewControllerAnimated:YES
                                                                       completion:^{ _annotationController = nil; }];
}

- (void)mailComposeController:(MFMailComposeViewController *)aController
          didFinishWithResult:(MFMailComposeResult)aResult
                        error:(NSError *)aError
{
    switch (aResult) {
        default: break;
        case MFMailComposeResultSaved:
        case MFMailComposeResultCancelled:
            [aController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
            break;
        case MFMailComposeResultSent:
            [aController.presentingViewController dismissViewControllerAnimated:YES completion:^{
                [self annotationControllerDidCancel:_annotationController];
            }];
    }
}


- (void)refreshLogMessages
{
    aslmsg const query = asl_new(ASL_TYPE_QUERY);
    asl_set_query(query, ASL_KEY_PID,
                  [[@(getpid()) stringValue] UTF8String],
                  ASL_QUERY_OP_EQUAL);
    if([_logMessages count] > 0)
        asl_set_query(query, ASL_KEY_MSG_ID,
                      [[_logMessages lastObject][@(ASL_KEY_MSG_ID)] UTF8String],
                      ASL_QUERY_OP_GREATER);
    
    
    aslmsg msg;
    aslresponse const response = asl_search(NULL, query);
    while((msg = aslresponse_next(response))) {
        [_logMessages addObject:@{ @(ASL_KEY_MSG_ID): @(asl_get(msg, ASL_KEY_MSG_ID)),
                                   @(ASL_KEY_MSG):    @(asl_get(msg, ASL_KEY_MSG)),
                                   @(ASL_KEY_TIME):   @(asl_get(msg, ASL_KEY_TIME)) }];
    }
    
    aslresponse_free(response);
    asl_free(query);
}

- (void)_neverCalled
{
    // Make sure the app gets rejected if the developer forgets to remove anonsrc
    [[[self window] rootViewController] attentionClassDumpUser:nil
                                                 yesItsUsAgain:nil
             althoughSwizzlingAndOverridingPrivateMethodsIsFun:nil
                       itWasntMuchFunWhenYourAppStoppedWorking:nil
              pleaseRefrainFromDoingSoInTheFutureOkayThanksBye:nil];
}

@end


@implementation UIViewController (ASReporter)
- (UIViewController *)as_visibleViewController
{
    return [self.presentedViewController as_visibleViewController]
        ?: self.presentedViewController
        ?: self;
}
@end

#endif