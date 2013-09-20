//
//  SquashContextMenuSheetCtl.m
//  SafariStand


#import "SafariStand.h"
#import "SquashContextMenuSheetCtl.h"



@implementation SquashContextMenuSheetCtl

@synthesize menuItemDefs=_menuItemDefs;

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




- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
    
    //save pref
    NSMutableArray* disabledItems=[NSMutableArray array];
    for (NSMutableDictionary* dic in self.menuItemDefs) {
        NSNumber* tag=[dic objectForKey:@"tag"];
        if (tag) {
            BOOL disabled=[[dic objectForKey:@"disabled"]boolValue];
            if (disabled) {
                [disabledItems addObject:tag];
            }
        }
    }
    [[NSUserDefaults standardUserDefaults]setObject:disabledItems forKey:kpSquashContextMenuItemTags];
    [[NSUserDefaults standardUserDefaults]synchronize];
}




- (IBAction)actSheetDone:(id)sender
{
    [NSApp endSheet:[self window]];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    //load pref
    NSString* defFile=[[NSBundle bundleWithIdentifier:kSafariStandBundleID]pathForResource:@"SquashContextMenuItems" ofType:@"plist"];

    NSArray* disabledItems=[[NSUserDefaults standardUserDefaults]arrayForKey:kpSquashContextMenuItemTags];
    
    NSArray* ary=[[NSArray alloc]initWithContentsOfFile:defFile];
    NSMutableArray* defs=[[STCSafariStandCore si]makeMutableArrayCopy:ary];
    for (NSMutableDictionary* dic in defs) {
        NSNumber* tag=[dic objectForKey:@"tag"];
        if ([disabledItems containsObject:tag]) {
            [dic setObject:[NSNumber numberWithBool:YES] forKey:@"disabled"];
        }else {
            [dic setObject:[NSNumber numberWithBool:NO] forKey:@"disabled"];
        }
    }
    
    [ary release];
    self.menuItemDefs=defs;
}

@end
