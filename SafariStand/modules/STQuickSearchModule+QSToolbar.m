//
//  STQuickSearchModule+QSToolbar.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import "SafariStand.h"
#import "STQuickSearchModule.h"
#import "STSToolbarModule.h"
#import "STQSToolbarBaseView.h"


@implementation STQuickSearchModule (QSToolbar)

- (NSToolbarItem *)quickSearchToolbarItemWillBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem* result=nil;
    NSView* view=[[STQSToolbarBaseView alloc]initWithQuickSearch:self];
    result=[[STCSafariStandCore mi:@"STSToolbarModule"]toolBarItem:STQSToolbarIdentifier label:@"Stand:Quick Search" view:view];
    return result;
}


- (void)quickSearchToolbarPopupWithEvent:(NSEvent*)event forView:(NSButton*)view
{
    @autoreleasepool {
        NSMenu* actMenu=nil;
        HTShowPopupMenuForButton(event, view, actMenu);
    }
}


@end
