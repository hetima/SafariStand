//
//  STClassifyDownloadAdvSheetCtl.h
//  SafariStand


#import <Cocoa/Cocoa.h>

@interface STClassifyDownloadAdvSheetCtl : NSWindowController

@property (nonatomic,assign) id arrayBinder;
@property (nonatomic,weak) IBOutlet NSTextField *basicExpField;

- (IBAction)actSheetDone:(id)sender;
- (IBAction)actDateFormatHelpBtn:(id)sender;

@end
