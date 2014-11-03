//
//  STClassifyDownloadAdvSheetCtl.h
//  SafariStand


@import AppKit;

@interface STClassifyDownloadAdvSheetCtl : NSWindowController

@property (nonatomic,assign) id arrayBinder;
@property (nonatomic,weak) IBOutlet NSTextField *basicExpField;

- (IBAction)actSheetDone:(id)sender;
- (IBAction)actDateFormatHelpBtn:(id)sender;

@end
