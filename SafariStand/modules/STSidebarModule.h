//
//  STSidebarModule.h
//  SafariStand


#import <Foundation/Foundation.h>

#define STSidebarTBItemIdentifier @"com.hetima.SafariStand.toggleSidebar"

@interface STSidebarModule : STCModule

- (void)toggleSidebar:(id)sender;
- (void)toggleSidebarLR:(id)sender;

@end

