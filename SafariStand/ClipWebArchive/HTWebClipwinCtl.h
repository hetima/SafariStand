//
//  HTWebClipwinCtl.h
//  SafariStand

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

//#define kClipContentHeaderID @"stand-clip-header"

@class HTFilePresetPopUpButton;

@interface HTWebClipWin : NSWindow

@end

@interface HTWebClipwinCtl : NSWindowController <NSToolbarDelegate>

@property (weak) IBOutlet WebView *oWebView;
@property (weak) IBOutlet NSTextField* oFileNameFld;
@property (assign) IBOutlet NSTextView* oMemoTextView;
@property (weak) IBOutlet HTFilePresetPopUpButton *oDirPopUp;
@property (strong) IBOutlet NSPopover *oMemoPopover;

+ (void)showUntitledWindow;
+ (void)showWindowForCurrentWKView;
+ (void)showWindowForWebArchive:(WebArchive*)arc webFrame:(WebFrame*)webFrame info:(NSDictionary*)info;

- (id)initWithWebArchive:(WebArchive*)arc webFrame:(WebFrame*)webFrame info:(NSDictionary*)info;


- (NSString *)filePath;
- (void)setFilePath:(NSString *)value;




- (IBAction)actSave:(id)sender;
- (IBAction)actToggleEditable:(id)sender;
- (IBAction)actInsertContentHeader:(id)sender;
- (IBAction)actInsertMemo:(id)sender;
- (IBAction)actClearMemo:(id)sender;

- (IBAction)actEditMemo:(id)sender;


- (BOOL)insertContentHeaderToggle:(BOOL)toggle;
- (void)insertMemo:(NSString*)memo;

@end
