//
//  STActionMenuModule.h
//  SafariStand

@import AppKit;

#define STActionMenuIdentifier @"com.hetima.SafariStand.actionMenu"

@interface STActionMenuModule : STCModule

@property (nonatomic,retain)NSImage* toolbarIcon;

@end


@interface STActionButton : NSButton

+ (id)actionButton;

@end
