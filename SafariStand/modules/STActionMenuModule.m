//
//  STActionMenuModule.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import "SafariStand.h"
#import "STActionMenuModule.h"
#import "STSToolbarModule.h"


@implementation STActionMenuModule

- (id)initWithStand:(id)core
{
    self = [super initWithStand:core];
    if (self) {
        //[self observePrefValue:];
        [core registerToolbarIdentifier:STActionMenuIdentifier module:self];
    }
    return self;
}

- (void)dealloc
{

}

- (void)prefValue:(NSString*)key changed:(id)value
{
    //if([key isEqualToString:])
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem* result=nil;
    if ([itemIdentifier isEqualToString:STActionMenuIdentifier]) {
        STActionButton* btn=[STActionButton actionButton];
        result=[[STCSafariStandCore mi:@"STSToolbarModule"]toolBarItem:STActionMenuIdentifier label:@"Stand:Action Menu" view:btn];
        
    }
    return result;
}


#pragma mark - path popup

-(NSMenu*)pathMenuForFileURL:(NSString*)urlString
{
    NSMenuItem* itm;
    NSMenu* menu=[[NSMenu alloc]initWithTitle:@"Path Navigation"];
    NSURL* url=[NSURL URLWithString:urlString];
    NSString* fullPath=[url path];
    NSString* pathToSelect=fullPath;
    if (![[NSFileManager defaultManager]fileExistsAtPath:fullPath]) {
        return nil;
    }
    while ([fullPath length]>1) {
        NSString* name=[fullPath lastPathComponent];
        itm=[menu addItemWithTitle:name action:@selector(actRevealFilePath:) keyEquivalent:@""];
        [itm setRepresentedObject:pathToSelect];
        [itm setTarget:self];
        NSImage* icon=[[NSWorkspace sharedWorkspace]iconForFile:fullPath];
        [icon setSize:NSMakeSize(16.0,16.0)];
        [itm setImage:icon];
        
        pathToSelect=fullPath;
        fullPath=[fullPath stringByDeletingLastPathComponent];
        if ([pathToSelect isEqualToString:fullPath]) {
            break;
        }
    }
    
    return menu;
}


- (void)actRevealFilePath:(NSMenuItem*)sender
{
    NSString* path=[sender representedObject];
    if([[NSFileManager defaultManager]fileExistsAtPath:path]){
        [[NSWorkspace sharedWorkspace]selectFile:path inFileViewerRootedAtPath:nil];
    }
}


-(NSMenu*)pathMenuForWebURL:(NSString*)urlString
{
    NSMenuItem* itm;
    NSMenu* menu=[[NSMenu alloc]initWithTitle:@"Path Navigation"];
    NSURL* url=[NSURL URLWithString:urlString];
    NSArray* paths=[url pathComponents];
    NSString* structuralString;
    
    NSString* host=[NSString stringWithFormat:@"%@://%@", [url scheme], [url host]];
    if ([urlString hasPrefix:[host stringByAppendingString:@":"]]) {
        host=[NSString stringWithFormat:@"%@:%@", host, [url port]];
    }

    structuralString=host;
    NSString* latItem=[paths lastObject];
    for (NSString* path in paths) {
        // first item is @"/"
        structuralString=[structuralString stringByAppendingString:path];
        if (path != latItem && ![path isEqualToString:@"/"]) {
            structuralString=[structuralString stringByAppendingString:@"/"];
        }

        itm=[menu addItemWithTitle:[NSString stringWithFormat:@"➡️ %@", structuralString] action:@selector(actGoToPath:) keyEquivalent:@""];
        [itm setRepresentedObject:structuralString];
        [itm setTarget:self];
        
        itm=[menu addItemWithTitle:[NSString stringWithFormat:@"📋 %@", structuralString] action:@selector(actCopyPath:) keyEquivalent:@""];
        [itm setRepresentedObject:structuralString];
        [itm setTarget:self];
        [itm setAlternate:YES];
        [itm setKeyEquivalentModifierMask:NSAlternateKeyMask];
        
        itm=[menu addItemWithTitle:[NSString stringWithFormat:@"🔍 %@", structuralString] action:@selector(STGoogleSiteSearchMenuItemAction:) keyEquivalent:@""];
        [itm setRepresentedObject:structuralString];
        [itm setAlternate:YES];
        [itm setKeyEquivalentModifierMask:NSShiftKeyMask];
    }
    
    if ([[url query]length]>0) {
        itm=[[NSMenuItem alloc]initWithTitle:[NSString stringWithFormat:@"📋 ?%@",[url query]] action:@selector(actCopyPath:) keyEquivalent:@""];
        [itm setRepresentedObject:[url query]];
        [itm setTarget:self];
        [menu addItem:itm];
    }
    
    if ([[url fragment]length]>0) {
        itm=[[NSMenuItem alloc]initWithTitle:[NSString stringWithFormat:@"📋 #%@",[url fragment]] action:@selector(actCopyPath:) keyEquivalent:@""];
        [itm setRepresentedObject:[url fragment]];
        [itm setTarget:self];
        [menu addItem:itm];
    }
    
    return menu;
}


- (void)actGoToPath:(NSMenuItem*)sender
{
    NSString* urlStr=[sender representedObject];
    if([urlStr length]>0){
        NSURL* url=[NSURL URLWithString:urlStr];
        if(url) STSafariGoToURLWithPolicy(url, poNewTab);
    }
}


- (void)actCopyPath:(NSMenuItem*)sender
{
    NSString* urlStr=[sender representedObject];
    if([urlStr length]>0){
        NSPasteboard* pb=[NSPasteboard generalPasteboard];
        [pb clearContents];
        [pb setString:urlStr forType:NSPasteboardTypeString];
    }
}

#pragma mark -

-(NSMenu*)actionPopupMenuForURL:(NSString*)currentURLString webView:(NSView*)currentWebView
{
    NSMenu* actMenu=[[NSMenu alloc]initWithTitle:@"act"];
    
    //BOOL needSeparator=NO;
    
    //copy item"Copy Link URL"
    NSMenuItem* itm;
    [actMenu addItemWithTitle:LOCALIZE(@"Copy Link URL") action:@selector(STCopyWindowURL:) keyEquivalent:@""];
    [actMenu addItemWithTitle:LOCALIZE(@"Copy Page Title") action:@selector(STCopyWindowTitle:) keyEquivalent:@""];

    
    [actMenu addItemWithTitle:LOCALIZE(@"Copy Link and Title") action:@selector(STCopyWindowTitleAndURL:) keyEquivalent:@""];
    itm=[actMenu addItemWithTitle:LOCALIZE(@"Copy Link (space) Title") action:@selector(STCopyWindowTitleAndURLSpace:) keyEquivalent:@""];
    [itm setKeyEquivalentModifierMask:NSAlternateKeyMask];
    [itm setAlternate:YES];
    

    if([[NSUserDefaults standardUserDefaults]boolForKey:kpCopyLinkTagAddTargetBlank]){
        itm=[actMenu addItemWithTitle:LOCALIZE(@"Copy Link Tag (_blank)") 
                                      action:@selector(STCopyWindowURLTagBlank:) keyEquivalent:@""];
    }else{
        itm=[actMenu addItemWithTitle:LOCALIZE(@"Copy Link Tag") 
                                      action:@selector(STCopyWindowURLTag:) keyEquivalent:@""];
    }    
    if([[NSUserDefaults standardUserDefaults]boolForKey:kpCopyLinkTagAddTargetBlank]){
        itm=[actMenu addItemWithTitle:LOCALIZE(@"Copy Link Tag") 
                                      action:@selector(STCopyWindowURLTag:) keyEquivalent:@""];
    }else{
        itm=[actMenu addItemWithTitle:LOCALIZE(@"Copy Link Tag (_blank)") 
                                      action:@selector(STCopyWindowURLTagBlank:) keyEquivalent:@""];
    }
    [itm setKeyEquivalentModifierMask:NSAlternateKeyMask];
    [itm setAlternate:YES];

    
    [actMenu addItemWithTitle:LOCALIZE(@"Copy Link as Markdown") action:@selector(STCopyWindowTitleAndURLAsMarkdown:) keyEquivalent:@""];
    itm=[actMenu addItemWithTitle:LOCALIZE(@"Copy Link as Hatena") action:@selector(STCopyWindowTitleAndURLAsHatena:) keyEquivalent:@""];
    [itm setKeyEquivalentModifierMask:NSAlternateKeyMask];
    [itm setAlternate:YES];
    
    [actMenu addItem:[NSMenuItem separatorItem]];
    
    if(currentURLString && currentWebView){
        NSMenu* pathMenu=nil;
        if([currentURLString hasPrefix:@"http"]){
            pathMenu=[self pathMenuForWebURL:currentURLString];
        }else if ([currentURLString hasPrefix:@"file://"]){
            pathMenu=[self pathMenuForFileURL:currentURLString];
        }
        
        if (pathMenu) {
            itm=[actMenu addItemWithTitle:@"Path Navigation" action:nil keyEquivalent:@""];
            [itm setSubmenu:pathMenu];
            [actMenu addItem:[NSMenuItem separatorItem]];
        }
    }
    
    
    /*
    if (needSeparator) {
        [actMenu addItem:[NSMenuItem separatorItem]];
    }
    */
    
    
    NSMenuItem* lastItem=[actMenu itemAtIndex:[actMenu numberOfItems]-1];
    if ([lastItem isSeparatorItem]) {
        [actMenu removeItemAtIndex:[actMenu numberOfItems]-1];
    }

    return actMenu;
}

-(void)actionPopupWithEvent:(NSEvent*)event forView:(NSButton*)view
{
    @autoreleasepool {
        NSString*  currentURLString=STSafariCurrentURLString();
        NSView*    currentWebView=STSafariCurrentWKView();

        NSMenu* actMenu=[self actionPopupMenuForURL:currentURLString webView:currentWebView];
        
        HTShowPopupMenuForButton(event, view, actMenu);
        
    }
}


@end


@implementation STActionButton

+(id)actionButton
{
    static NSImage* STActionButtonIcon=nil;
    if (!STActionButtonIcon) {
        NSString* imgPath=[[NSBundle bundleWithIdentifier:kSafariStandBundleID]pathForImageResource:@"STTBActionMenu"];
        STActionButtonIcon=[[NSImage alloc]initWithContentsOfFile:imgPath];
        [STActionButtonIcon setTemplate:YES];
    }

	STActionButton*	btn=[[STActionButton alloc]initWithFrame:NSMakeRect(0,0, 28, 25)];
    
	[btn setAutoresizingMask:NSViewNotSizable];
    [btn setImagePosition:NSImageOnly];
    [btn setBezelStyle:NSTexturedRoundedBezelStyle];
    [btn setBordered:YES];
	[btn setImage:STActionButtonIcon];
	
	[btn setEnabled:YES];
    
	return btn;

}

- (void)mouseDown:(NSEvent *)theEvent
{
	NSPoint     popupPoint;
	NSEvent*    popupEvent;
	popupPoint = [self convertPoint:NSMakePoint(0, [self frame].size.height + 1) 
                             toView:nil];
    
	popupEvent = [NSEvent mouseEventWithType:[theEvent type] 
                                    location:popupPoint 
                               modifierFlags:[theEvent modifierFlags] 
                                   timestamp:[theEvent timestamp] 
                                windowNumber:[theEvent windowNumber] 
                                     context:[theEvent context] 
                                 eventNumber:[theEvent eventNumber] 
                                  clickCount:[theEvent clickCount] 
                                    pressure:[theEvent pressure]];
    STActionMenuModule* m=[STCSafariStandCore mi:@"STActionMenuModule"];
	[m actionPopupWithEvent:popupEvent forView:self];
	return;
    
}


@end