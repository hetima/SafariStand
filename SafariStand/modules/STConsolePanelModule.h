//
//  STConsolePanelModule.h
//  SafariStand


#import <Foundation/Foundation.h>
#import "STCTabWithToolbarWinCtl.h"


@interface STConsolePanelModule : STCModule

-(void)addViewController:(NSViewController*)viewCtl withIdentifier:(NSString*)identifier title:(NSString*)title icon:(NSImage*)icon weight:(NSInteger)weight;
-(void)addPane:(NSView*)view withIdentifier:(NSString*)identifier title:(NSString*)title icon:(NSImage*)icon weight:(NSInteger)weight;

- (void)showConsolePanelAndSelectTab:(NSString*)identifier;

@end


@interface STConsolePanelCtl : STCTabWithToolbarWinCtl

@property (nonatomic,retain)id otherDefaults;

- (void)addPane:(NSView*)view withIdentifier:(NSString*)identifier title:(NSString*)title icon:(NSImage*)icon weight:(NSInteger)weight;

@end
