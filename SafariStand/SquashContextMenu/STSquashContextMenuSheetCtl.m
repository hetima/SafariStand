//
//  STSquashContextMenuSheetCtl.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import "SafariStand.h"
#import "STSquashContextMenuSheetCtl.h"



@implementation STSquashContextMenuSheetCtl


- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (!self) return nil;
    
    
    return self;
}


- (void)dealloc
{

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
    NSString* plistName=@"SquashContextMenuItems";

    NSString* defFile=[[NSBundle bundleWithIdentifier:kSafariStandBundleID]pathForResource:plistName ofType:@"plist"];

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
    
    self.menuItemDefs=defs;
}

@end
