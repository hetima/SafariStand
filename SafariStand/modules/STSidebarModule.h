//
//  STSidebarModule.h
//  SafariStand


@import AppKit;

#define STSidebarTBItemIdentifier @"com.hetima.SafariStand.toggleSidebar"

@interface STSidebarModule : STCModule

- (void)toggleSidebar:(id)sender;
- (void)toggleSidebarLR:(id)sender;

@end

