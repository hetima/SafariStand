//
//  STPrefWindowModule.h
//  SafariStand


@import AppKit;
#import "STCTabWithToolbarWinCtl.h"



@class STCTabWithToolbarWinCtl;


@interface STPrefWindowModule : STCModule

- (void)addPane:(NSView*)view withIdentifier:(NSString*)identifier title:(NSString*)title icon:(NSImage*)icon;
- (IBAction)actShowPrefWindow:(id)sender;

@end


@interface STPrefWindowCtl : STCTabWithToolbarWinCtl{
    
}
@property(nonatomic, strong) id otherDefaults;

@property(nonatomic, assign) IBOutlet NSTextField* oCurrentVarsionLabel;
@property(nonatomic, strong) NSString* currentVersionString;
@property(nonatomic, strong) NSString* latestVersionString;

- (IBAction)actShowDownloadFolderAdvanedSetting:(id)sender;
- (IBAction)actShowSquashCMAdvanedSetting:(id)sender;

@end

