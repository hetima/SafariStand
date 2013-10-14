//
//  STFakeJSCommand.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import "SafariStand.h"
#import "STFakeJSCommand.h"

@implementation STFakeJSCommand


+(void)doScript:(NSString*)scpt onTarget:(id)wkViewOrTabViewItem completionHandler:(STFakeJSCommandCompletionHandler) completionHandler
{
    if ([wkViewOrTabViewItem respondsToSelector:@selector(handleDoJavaScriptCommand:)]) {

        NSScriptSuiteRegistry* suiteRegistry=[NSScriptSuiteRegistry sharedScriptSuiteRegistry];
        NSScriptCommandDescription* desc=[[suiteRegistry commandDescriptionsInSuite:@"Safari"]objectForKey:@"DoJavaScript"];
        STFakeJSCommand* cmd=[[STFakeJSCommand alloc]initWithCommandDescription:desc];
        [cmd setDirectParameter:scpt];
        //[cmd setArguments:@{@"Target":wkViewOrTabViewItem}]; //seems no need
        cmd.completionHandler=completionHandler;
        
        objc_msgSend(wkViewOrTabViewItem, @selector(handleDoJavaScriptCommand:), cmd);
     }
}


- (void)dealloc
{
    LOG(@"cmd d");
}

- (void)resumeExecutionWithResult:(id)result
{
    self.completionHandler(result);
}

@end
