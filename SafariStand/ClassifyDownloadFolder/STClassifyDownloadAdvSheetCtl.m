//
//  STClassifyDownloadAdvSheetCtl.m
//  SafariStand


#import "SafariStand.h"
#import "STClassifyDownloadAdvSheetCtl.h"
#import "STSDownloadModule.h"
#import "STSafariConnect.h"

@implementation STClassifyDownloadAdvSheetCtl
@synthesize arrayBinder;
@synthesize basicExpField;

-(id)defaultObjecOfHTArrayController:(id)aryCtl
{
    return [NSMutableDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithBool:YES], @"use", @"ext",@"type",@"@/images",@"exp",@"jpg, jpeg, gif, png",@"pattern",
            [NSString HTUUIDStringWithFormat:@"%@"],@"uuid", nil];

}



- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo{
    [sheet orderOut:self];

    ((STSDownloadModule*)arrayBinder).basicExp=[basicExpField stringValue];
    [arrayBinder saveToStorage];
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc
{

    [super dealloc];
}

-(void)setAdvancedFilters:(NSMutableArray *)ary
{
    [arrayBinder setAdvancedFilters:ary];
}
-(NSMutableArray*)advancedFilters
{
    return [arrayBinder advancedFilters];
}





- (void)windowDidLoad
{
    [super windowDidLoad];
    [basicExpField setStringValue:((STSDownloadModule*)arrayBinder).basicExp];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)actSheetDone:(id)sender {
    [NSApp endSheet:[self window]];
}

- (IBAction)actDateFormatHelpBtn:(id)sender {
    NSURL* url=[NSURL URLWithString:@"http://hetima.com/safari/safaristandhelp/dateformat.html"];
    STSafariGoToURLWithPolicy(url, poNewTab);
}



@end
