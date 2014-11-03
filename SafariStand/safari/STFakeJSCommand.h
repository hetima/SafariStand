//
//  STFakeJSCommand.h
//  SafariStand


@import Foundation;

typedef void (^STFakeJSCommandCompletionHandler)(id result);

@interface STFakeJSCommand : NSScriptCommand

@property (strong) STFakeJSCommandCompletionHandler completionHandler;

+ (void)doScript:(NSString*)scpt onTarget:(id)wkViewOrTabViewItem completionHandler:(STFakeJSCommandCompletionHandler) completionHandler;
@end
