//
//  HTWebClipwinCtl.h
//  SafariStand

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

//#define kClipContentHeaderID @"stand-clip-header"

@class HTFilePresetPopUpButton;

@interface HTWebClipWin : NSWindow
{

}
@end

@interface HTWebClipwinCtl : NSWindowController <NSToolbarDelegate>{
	IBOutlet WebView	*oWebView;
    IBOutlet HTFilePresetPopUpButton *oDirPopUp;
    IBOutlet NSTextField* oFileNameFld;
    WebArchive* _webArchive;
    NSString* _defaultTitle;
    NSString* _urlStr;
    IBOutlet NSTextView* oMemoTextView;
    
    IBOutlet NSView* oMainView;
    IBOutlet NSView* oBottomDiscloseView;
    IBOutlet NSButton* oDisclosureButton;
    NSString* _filePath;
    
    id _hiliter;

}
+ (void)showUntitledWindow;
+ (void)showWindowForCurrentWKView;
+ (void)showWindowForWebArchive:(WebArchive*)arc webFrame:(WebFrame*)webFrame info:(NSDictionary*)info;

- (id)initWithWebArchive:(WebArchive*)arc webFrame:(WebFrame*)webFrame info:(NSDictionary*)info;


- (NSString *)filePath;
- (void)setFilePath:(NSString *)value;




-(IBAction)actSave:(id)sender;
-(IBAction)actToggleEditable:(id)sender;
-(IBAction)actInsertContentHeader:(id)sender;
-(IBAction)actInsertMemo:(id)sender;
-(IBAction)actClearMemo:(id)sender;

-(IBAction)actToggleBottomDiscloseViewDisplay:(id)sender;


- (BOOL)insertContentHeaderToggle:(BOOL)toggle;
- (void)insertMemo:(NSString*)memo;

@end
