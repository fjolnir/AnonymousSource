// Anonymous Source
// Simple issue reporting tool (Inspired by http://www.marco.org/bugshot)

// Instructions for making sure you don't accidentally create App Store builds containing ASReporter:
//
// Do not add ASReporter.storyboard to your "Copy Resources" phase, instead create this "Run Script" phase:
//// if [ $CONFIGURATION != "Release" ]; then
////     ibtool "$SCRIPT_INPUT_FILE_0" --compile "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/`basename $SCRIPT_INPUT_FILE_0`c"
//// fi
// Where the first input path is set to $(SRCROOT)/path/to/ASReporter.storyboard
//
// Once you've done that, add __DISABLE_ANONSRC__=1 to your target's "Preprocessor Macros"
// under the Release configuration.
//
// Then just stick ASInitReporter(@"my@email.com"); in your applicationDidFinishLaunching

#ifndef __DISABLE_ANONSRC__ // Make sure to define this in your release configuration
#import <Foundation/Foundation.h>

#define ASInitReporter(email) do { \
    [ASReporter prepare]; \
    [ASReporter setEmail:(email)]; \
} while(0)

@interface ASReporter : NSObject
@property(nonatomic, copy) NSString *email;

+ (instancetype)sharedReporter;

+ (instancetype)new  __attribute__((unavailable("+new not available; use +sharedReporter")));
- (id)init           __attribute__((unavailable("-init not available; use +sharedReporter")));

+ (void)prepare;
+ (void)setEmail:(NSString *)aEmail;
- (void)prepare;

- (void)show;

@end

#else
#    define ASInitReporter(...)
#endif