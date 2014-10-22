//
//  STConsolePanelModule.h
//  SafariStand


#import <Foundation/Foundation.h>
#import "STCTabWithToolbarWinCtl.h"


@interface STConsolePanelModule : STCModule

-(void)addViewController:(NSViewController*)viewCtl withIdentifier:(NSString*)identifier title:(NSString*)title icon:(NSImage*)icon;
-(void)addPane:(NSView*)view withIdentifier:(NSString*)identifier title:(NSString*)title icon:(NSImage*)icon;

@end


@interface STConsolePanelCtl : STCTabWithToolbarWinCtl
    

@property (nonatomic,retain)id otherDefaults;


@end
