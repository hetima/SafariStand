//
//  STQuickSearch+QSToolbar.m
//  SafariStand

#import "SafariStand.h"
#import "STQuickSearch.h"
#import "STSToolbarModule.h"
#import "STQSToolbarBaseView.h"





@implementation STQuickSearch (QSToolbar)

- (NSToolbarItem *)quickSearchToolbarItemWillBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem* result=nil;
    NSView* view=[[STQSToolbarBaseView alloc]initWithQuickSearch:self];
    result=[[STCSafariStandCore mi:@"STSToolbarModule"]toolBarItem:STQSToolbarIdentifier label:@"Stand:Quick Search" view:view];
    [view release];
    return result;
}

-(void)quickSearchToolbarPopupWithEvent:(NSEvent*)event forView:(NSButton*)view
{
    NSAutoreleasePool*  arp=[[NSAutoreleasePool alloc]init];
    
    NSMenu* actMenu=nil;
    
    HTShowPopupMenuForButton(event, view, actMenu);
    
    
    [arp release];
}


@end
