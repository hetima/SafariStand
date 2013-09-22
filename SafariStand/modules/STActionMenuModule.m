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


#pragma mark -


-(NSMenu*)actionPopupMenuForURL:(NSString*)currentURLString webView:(NSView*)currentWebView
{
    NSMenu* actMenu=[[NSMenu alloc]initWithTitle:@"act"];
    
    BOOL    needSeparator=NO;
    
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
    
    needSeparator=YES;
    
    if(currentURLString && currentWebView){
        //http header
        if([currentURLString hasPrefix:@"http"]){
            //needSeparator=YES;
        }
        needSeparator=YES;
    }
    /*
    if (needSeparator) {
        [actMenu addItem:[NSMenuItem separatorItem]];
    }
    */

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