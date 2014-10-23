//
//  STClassifyDownloadAdvSheetCtl.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import "SafariStand.h"
#import "STClassifyDownloadAdvSheetCtl.h"
#import "STSDownloadModule.h"
#import "STSafariConnect.h"

@implementation STClassifyDownloadAdvSheetCtl


-(id)defaultObjecOfHTArrayController:(id)aryCtl
{
    return [NSMutableDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithBool:YES], @"use", @"ext",@"type",@"@/images",@"exp",@"jpg, jpeg, gif, png",@"pattern",
            [NSString stand_UUIDStringWithFormat:@"%@"],@"uuid", nil];

}


- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];

    ((STSDownloadModule*)self.arrayBinder).basicExp=[self.basicExpField stringValue];
    [self.arrayBinder saveToStorage];
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

}

-(void)setAdvancedFilters:(NSMutableArray *)ary
{
    [self.arrayBinder setAdvancedFilters:ary];
}

-(NSMutableArray*)advancedFilters
{
    return [self.arrayBinder advancedFilters];
}


- (void)windowDidLoad
{
    [super windowDidLoad];
    [self.basicExpField setStringValue:((STSDownloadModule*)self.arrayBinder).basicExp];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)actSheetDone:(id)sender
{
    [NSApp endSheet:[self window]];
}

- (IBAction)actDateFormatHelpBtn:(id)sender
{
    NSURL* url=[NSURL URLWithString:@"http://hetima.com/safari/safaristandhelp/dateformat.html"];
    STSafariGoToURLWithPolicy(url, poNewTab);
}



@end
