//
//  NSApplication+SafariStand.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import "SafariStand.h"
#import "NSApplication+SafariStand.h"
#import "STSafariConnect.h"
#import "STSearchItLaterWinCtl.h"
#import "STStandSearchWinCtl.h"

#import "HTWebClipwinCtl.h"
#import "STQuickSearchModule.h"
#import "STSidebarModule.h"


@implementation NSApplication (NSApplication_SafariStand)
#ifdef DEBUG


-(void)STTestDumpView:(NSView*)v indent:(NSString*)indent
{
    NSString* nextIndent=[NSString stringWithFormat:@"+%@", indent];
    LOG(@"%@%@", indent, [v className]);
    for (NSView* sv in [v subviews]) {
        [self STTestDumpView:sv indent:nextIndent];
    }
}


-(void)STTest:(id)sender
{
    NSView* v= STSafariCurrentWKView();
    [self STTestDumpView:[[[v window]contentView]superview] indent:@""];

}
#endif

-(void)showSearchItLaterWindow:(id)sender
{
    [STSearchItLaterWinCtl showSearchItLaterWindow];
}

-(void)showStandSearchWindow:(id)sender
{
    [STStandSearchWinCtl showStandSearcWindow];
}



#pragma mark -

-(void)STCopyWindowTitle:(id)sender
{
    NSString*   title=STSafariCurrentTitle();
    if(title){
        NSPasteboard*   pb=[NSPasteboard generalPasteboard];
        [pb clearContents];
        [pb setString:title forType:NSStringPboardType];
    }
}

-(void)STCopyWindowURL:(id)sender
{
    NSString*   urlStr=STSafariCurrentURLString();
    if(urlStr){
        NSPasteboard*   pb=[NSPasteboard generalPasteboard];
        [pb clearContents];
        [pb setString:urlStr forType:NSStringPboardType];
    }
}

-(void)STCopyWindowURLTag:(id)sender
{
    NSString*   title=STSafariCurrentTitle();
    NSString*   urlStr=STSafariCurrentURLString();
    if(title && urlStr && [urlStr length]>0){
        NSString* format=LOCALIZE(@"LINKTAG");
        NSString*   outStr=[NSString stringWithFormat:format,urlStr,title];
        if(outStr){
            NSPasteboard*   pb=[NSPasteboard generalPasteboard];
            [pb clearContents];
            [pb setString:outStr forType:NSStringPboardType];
        }
    }
}

-(void)STCopyWindowURLTagBlank:(id)sender
{
    NSString*   title=STSafariCurrentTitle();
    NSString*   urlStr=STSafariCurrentURLString();
    if(title && urlStr && [urlStr length]>0){
        NSString* format=LOCALIZE(@"LINKTAGBLANK");
        NSString*   outStr=[NSString stringWithFormat:format,urlStr,title];
        if(outStr){
            NSPasteboard*   pb=[NSPasteboard generalPasteboard];
            [pb clearContents];
            [pb setString:outStr forType:NSStringPboardType];
        }
    }
}

-(void)STCopyWindowTitleAndURL:(id)sender separator:(NSString*)sep
{
    NSString*   title=STSafariCurrentTitle();
    NSString*   urlStr=STSafariCurrentURLString();
    if(title && urlStr && [urlStr length]>0){
        NSString*   formatStr=@"%@%@%@";
        NSString*   outStr=[NSString stringWithFormat:formatStr,title,sep,urlStr];
        if(outStr){
            NSPasteboard*   pb=[NSPasteboard generalPasteboard];
            [pb clearContents];
            [pb setString:outStr forType:NSStringPboardType];
        }
    }
}

-(void)STCopyWindowTitleAndURL:(id)sender
{
    [self STCopyWindowTitleAndURL:sender separator:@"\n"];
}

-(void)STCopyWindowTitleAndURLSpace:(id)sender
{
    [self STCopyWindowTitleAndURL:sender separator:@" "];
}

-(void)STCopyWindowTitleAndURLAsMarkdown:(id)sender
{
    NSString*   title=STSafariCurrentTitle();
    NSString*   urlStr=STSafariCurrentURLString();
    if(title && urlStr && [urlStr length]>0){
        NSString*   formatStr=@"[%@](%@)"; //label,url
        NSString*   outStr=[NSString stringWithFormat:formatStr,title,urlStr];
        if(outStr){
            NSPasteboard*   pb=[NSPasteboard generalPasteboard];
            [pb clearContents];
            [pb setString:outStr forType:NSStringPboardType];
        }
    }
}

-(void)STCopyWindowTitleAndURLAsHatena:(id)sender
{
    NSString*   title=STSafariCurrentTitle();
    NSString*   urlStr=STSafariCurrentURLString();
    if(title && urlStr && [urlStr length]>0){
        NSString*   formatStr=@"[%@:title=%@]"; //hatena - url,title
        NSString*   outStr=[NSString stringWithFormat:formatStr, urlStr, title];
        if(outStr){
            NSPasteboard*   pb=[NSPasteboard generalPasteboard];
            [pb clearContents];
            [pb setString:outStr forType:NSStringPboardType];
        }
    }
}


-(void)STGoogleSiteSearchMenuItemAction:(id)sender
{
    NSURL* aURL=[sender representedObject];
    NSString* aStr=[aURL absoluteString];
    
    NSRange range=[aStr rangeOfString:@"://"];
    NSInteger idx=range.location+range.length;
    if(idx>=0){
        aStr=[aStr substringFromIndex:idx];
    }
    if([aStr hasSuffix:@"/"]){
        aStr=[aStr substringToIndex:[aStr length]-1];
    }
    NSString* searchStr=[NSString stringWithFormat:@"site:%@", aStr];
    
    [[STQuickSearchModule si]sendGoogleQuerySeedWithoutAddHistoryWithSearchString:searchStr
                            policy:[STQuickSearchModule tabPolicy]];

}


-(void)STGoForwardIngoringModifierFlags:(id)sender
{
    //NSEvent* e=[NSApp currentEvent];
    //[e modifierFlags]
}


-(void)STClipWebArchiveWithCurrentWKView:(id)sender
{
    [HTWebClipwinCtl showWindowForCurrentWKView];
}

-(void)STToggleSidebar:(id)sender
{
    [(STSidebarModule*)[STCSafariStandCore mi:@"STSidebarModule"]toggleSidebar:nil];
}

-(void)STToggleSidebarLR:(id)sender
{
    [(STSidebarModule*)[STCSafariStandCore mi:@"STSidebarModule"]toggleSidebarLR:nil];
}


@end
