//
//  STCTabWithToolbarWinCtl.h
//  SafariStand


#import <Cocoa/Cocoa.h>


@interface STCTabWithToolbarWinCtl : NSWindowController {
@private
    IBOutlet NSToolbar *oToolbar;
    IBOutlet NSTabView *oTabView;
    
    NSMutableArray* _identifiers;
}
@property (readonly)NSToolbar* oToolbar;
@property (readonly)NSTabView* oTabView;

-(void)addIdentifier:(NSString*)identifier;

- (IBAction)actToolbarClick:(id)sender;
-(void)addPane:(NSView*)view withIdentifier:(NSString*)identifier title:(NSString*)title icon:(NSImage*)icon;

@end
