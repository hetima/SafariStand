//
//  STPrefWindowModule.h
//  SafariStand


#import <Foundation/Foundation.h>
#import "STCTabWithToolbarWinCtl.h"



@class STCTabWithToolbarWinCtl;


@interface STPrefWindowModule : STCModule {
@private
    STCTabWithToolbarWinCtl* prefWinCtl;
    

}

-(void)addPane:(NSView*)view withIdentifier:(NSString*)identifier title:(NSString*)title icon:(NSImage*)icon;
@end


@interface STPrefWindowCtl : STCTabWithToolbarWinCtl{
    id otherDefaults;
    
}
@property (nonatomic,assign)IBOutlet NSTextField* oCurrentVarsionLabel;
@property (nonatomic,retain)NSString* currentVersionString;
@property (nonatomic,retain)NSString* latestVersionString;

- (IBAction)actShowDownloadFolderAdvanedSetting:(id)sender;
- (IBAction)actShowSquashCMAdvanedSetting:(id)sender;

@end