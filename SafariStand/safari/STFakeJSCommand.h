//
//  STFakeJSCommand.h
//  SafariStand


#import <Foundation/Foundation.h>

typedef void (^STFakeJSCommandCompletionHandler)(id result);

@interface STFakeJSCommand : NSScriptCommand

@property (strong) STFakeJSCommandCompletionHandler completionHandler;

+ (void)doScript:(NSString*)scpt onTarget:(id)wkViewOrTabViewItem completionHandler:(STFakeJSCommandCompletionHandler) completionHandler;
@end
