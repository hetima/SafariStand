//
//  STClassifyDownloadAdvSheetCtl.h
//  SafariStand


#import <Cocoa/Cocoa.h>

@interface STClassifyDownloadAdvSheetCtl : NSWindowController{
    id arrayBinder;
    NSTextField *basicExpField;
}
@property(nonatomic,assign)id arrayBinder;
@property (assign) IBOutlet NSTextField *basicExpField;

- (IBAction)actSheetDone:(id)sender;
- (IBAction)actDateFormatHelpBtn:(id)sender;

@end
