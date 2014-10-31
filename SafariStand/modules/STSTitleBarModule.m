//
//  STSTitleBarModule.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import "SafariStand.h"
#import "STSTitleBarModule.h"

#import "STSafariConnect.h"

@implementation STSTitleBarModule
{
    BOOL _showingPathPopUpMenu;
}

- (id)initWithStand:(id)core
{
    self = [super initWithStand:core];
    if (self) {

        _showingPathPopUpMenu=NO;
/*
        KZRMETHOD_SWIZZLING_
        (
         "TitleBarButton", "showPathPopUpMenu",
         void, call, sel)
         ^(id slf){
             _showingPathPopUpMenu=YES;
             call(slf, sel);
             _showingPathPopUpMenu=NO;
         }_WITHBLOCK;
        
        KZRMETHOD_SWIZZLING_
        (
         "NSCarbonMenuImpl",
         "popUpMenu:atLocation:width:forView:withSelectedItem:withFont:withFlags:withOptions:",
         void, call, sel)
         ^(id slf, NSMenu* menu, NSPoint pt, double width, NSView* view, long long selection, id font,
                  unsigned long long arg7, id arg8)
        {
             if(_showingPathPopUpMenu && [[NSUserDefaults standardUserDefaults]boolForKey:kpImprovePathPopupMenu]){
                 //[[STCSafariStandCore mi:@"STSTitleBarModule"]alterPathPopUpMenu:menu];
                 [self alterPathPopUpMenu:menu];
             }
             call(slf, sel, menu, pt, width, view, selection, font, arg7, arg8);
         }_WITHBLOCK;
*/
    }
    return self;
}


- (void)prefValue:(NSString*)key changed:(id)value
{
    //if([key isEqualToString:])
}

- (void)alterPathPopUpMenu:(NSMenu*)menu
{
    /*
     _popUpItemAction:
     NSURL doNothing:
     NSURL goToMenuItemURL:
     
     */
    NSMenuItem* m;

    NSInteger i, cnt=[menu numberOfItems];
    for (i=cnt-1; i>=0; i--) {
        NSMenuItem* itm=[menu itemAtIndex:i];
        if([[itm representedObject]isKindOfClass:[NSURL class]] && [[itm title]hasPrefix:@"http"]){
            NSRange range=[[itm title]rangeOfString:@"://"];
            NSInteger idx=range.location+range.length;
            NSString* title;
            if(idx>=0){
                title=[[itm title]substringFromIndex:idx];
            }else{
                title=[itm title];
            }
            title=[NSString stringWithFormat:LOCALIZE(@"Google Site Search:%@"),title];
            NSMenuItem* altItem=[[NSMenuItem alloc]initWithTitle:title action:@selector(STGoogleSiteSearchMenuItemAction:) keyEquivalent:@""];
            [menu insertItem:altItem atIndex:i+1];
            [altItem setImage:[itm image]];
            [altItem setRepresentedObject:[itm representedObject]];
            [altItem setAlternate:YES];
            [altItem setKeyEquivalentModifierMask:NSAlternateKeyMask];
        }
    }
    /*for (NSMenuItem* itm in [menu itemArray]) {

     id obj=[itm representedObject];
     if(obj)LOG(@"%@, %@, %@",[itm title], [obj className], NSStringFromSelector([itm action]));
        else LOG(@"xx:%@, %@",[itm title], NSStringFromSelector([itm action]));
    }*/
    
    i=1;
    if([[NSUserDefaults standardUserDefaults]boolForKey:kpCopyLinkTagAddTargetBlank]){
        m=[[NSMenuItem alloc]initWithTitle:LOCALIZE(@"Copy Link Tag (_blank)")
                                    action:@selector(STCopyWindowURLTagBlank:) keyEquivalent:@""];
    }else{
        m=[[NSMenuItem alloc]initWithTitle:LOCALIZE(@"Copy Link Tag")
                                    action:@selector(STCopyWindowURLTag:) keyEquivalent:@""];
    }
    [menu insertItem:m atIndex:i++];
    
    if([[NSUserDefaults standardUserDefaults]boolForKey:kpCopyLinkTagAddTargetBlank]){
        m=[[NSMenuItem alloc]initWithTitle:LOCALIZE(@"Copy Link Tag")
                                    action:@selector(STCopyWindowURLTag:) keyEquivalent:@""];
    }else{
        m=[[NSMenuItem alloc]initWithTitle:LOCALIZE(@"Copy Link Tag (_blank)")
                                    action:@selector(STCopyWindowURLTagBlank:) keyEquivalent:@""];
    }
    [menu insertItem:m atIndex:i++];
    [m setAlternate:YES];
    [m setKeyEquivalentModifierMask:NSAlternateKeyMask];

    
    
    m=[[NSMenuItem alloc]initWithTitle:LOCALIZE(@"Copy Link and Title") action:@selector(STCopyWindowTitleAndURL:) keyEquivalent:@""];
    [menu insertItem:m atIndex:i++];

    m=[[NSMenuItem alloc]initWithTitle:LOCALIZE(@"Copy Link (space) Title") action:@selector(STCopyWindowTitleAndURLSpace:) keyEquivalent:@""];
    [menu insertItem:m atIndex:i++];
    [m setAlternate:YES];
    [m setKeyEquivalentModifierMask:NSAlternateKeyMask];
    
    
    m=[[NSMenuItem alloc]initWithTitle:LOCALIZE(@"Copy Page Title") action:@selector(STCopyWindowTitle:) keyEquivalent:@""];
    [menu insertItem:m atIndex:i++];
    //[m setAlternate:YES];
    //[m setKeyEquivalentModifierMask:NSAlternateKeyMask];

    m=[[NSMenuItem alloc]initWithTitle:LOCALIZE(@"Copy Link as Markdown") action:@selector(STCopyWindowTitleAndURLAsMarkdown:) keyEquivalent:@""];
    [menu insertItem:m atIndex:i++];

    m=[[NSMenuItem alloc]initWithTitle:LOCALIZE(@"Copy Link as Hatena") action:@selector(STCopyWindowTitleAndURLAsHatena:) keyEquivalent:@""];
    [menu insertItem:m atIndex:i++];
    [m setAlternate:YES];
    [m setKeyEquivalentModifierMask:NSAlternateKeyMask];

    if(![[menu itemAtIndex:i]isSeparatorItem]){
        [menu insertItem:[NSMenuItem separatorItem] atIndex:i++];
    }
    
}


@end
