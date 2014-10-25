//
//  STConsolePanelModule.h
//  SafariStand


#import <Foundation/Foundation.h>
#import "STCTabWithToolbarWinCtl.h"


@interface STConsolePanelModule : STCModule

@property (nonatomic, strong)NSMutableDictionary* panels;


// register panel item. do not call outside of modulesDidFinishLoading:
- (void)addPanelWithIdentifier:(NSString*)identifier title:(NSString*)title icon:(NSImage*)icon weight:(NSInteger)weight loadHandler:(id(^)())loadHandler;

- (void)showConsolePanelAndSelectTab:(NSString*)identifier;

@end


@interface STConsolePanelCtl : STCTabWithToolbarWinCtl
@property (nonatomic, assign)STConsolePanelModule* consolePanelModule;

- (void)commonConsolePanelCtlInitWithModule:(STConsolePanelModule*)consolePanelModule;
- (void)selectTab:(NSString*)identifier;
- (void)highlighteToolbarItemIdentifier:(NSString *)itemIdentifier;

@end


@interface STConsolePanelWindow : NSWindow

@end

@interface STConsolePanelToolbar : NSToolbar

@end
