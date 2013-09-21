//
//  STKeyHandler.m
//  SafariStand

#if __has_feature(objc_arc)
#error This file must be compiled with -fno-objc_arc
#endif

#import "SafariStand.h"
#import "STKeyHandler.h"


@implementation STKeyHandler

//10.6
//BrowserWindowControllerMac
IMP orig_goBack;
void ST_goBack(id self, SEL _cmd, id sender)
{
    if([[NSUserDefaults standardUserDefaults]boolForKey:kpSwitchTabWithSwipeEnabled]){
        NSEvent* event=[NSApp currentEvent];
        if([event type]==NSEventTypeSwipe){
            [NSApp sendAction:@selector(selectPreviousTab:) to:nil from:nil];
            return;
        }
    }
    orig_goBack(self, _cmd, sender);
}
IMP orig_goForward;
void ST_goForward(id self, SEL _cmd, id sender)
{
    if([[NSUserDefaults standardUserDefaults]boolForKey:kpSwitchTabWithSwipeEnabled]){
        NSEvent* event=[NSApp currentEvent];
        if([event type]==NSEventTypeSwipe){
            [NSApp sendAction:@selector(selectNextTab:) to:nil from:nil];
            return;
        }
    }
    orig_goForward(self, _cmd, sender);
}

//10.7
//- (void)swipeWithEvent:(id)arg1;
/*
 (gdb) bt
 #0  0x00007fff89ce6db1 in -[NSEvent trackSwipeEventWithOptions:dampenAmountThresholdMin:max:usingHandler:] ()
 #0  0x00007fff8a459f92 in -[TabContentView beginSwipeGestureWithEvent:] ()
 #1  0x00007fff8a2c68cd in -[BrowserWKView performGestureWithScrollEvent:] ()
 canGoBack やら調べてるぽいNOならperform行かない
 #2  0x00007fff8a2c67b2 in -[BrowserWKView scrollWheel:] ()
 #3  0x00007fff87d22ad2 in -[NSWindow sendEvent:] ()
 #4  0x00007fff8a4a00c5 in -[Window sendEvent:] ()
 #5  0x00007fff8a2a77e8 in -[BrowserWindow sendEvent:] ()
 #6  0x00007fff87cbaae8 in -[NSApplication sendEvent:] ()
 #7  0x00007fff8a25047a in -[BrowserApplication sendEvent:] ()
 #8  0x00007fff87c5142b in -[NSApplication run] ()
 #9  0x00007fff87ecf52a in NSApplicationMain ()
 #10 0x00007fff8a402725 in SafariMain ()
 #11 0x0000000101234f24 in ?? ()
 (gdb)
 
 */
IMP orig_beginSwipeGestureWithEvent;
void ST_beginSwipeGestureWithEvent(id self, SEL _cmd, NSEvent* event){
    LOG(@"WKView x=%f,y=%f",[event deltaX],[event deltaY]);
}
IMP orig_beginTCSwipeGestureWithEvent;
void ST_beginTCSwipeGestureWithEvent(id self, SEL _cmd, NSEvent* event){
    LOG(@"tc begin x=%f,y=%f",[event deltaX],[event deltaY]);
}
IMP orig_endSwipeGestureWithEvent;
void ST_endSwipeGestureWithEvent(id self, SEL _cmd, NSEvent* event){
    LOG(@"tc end x=%f,y=%f",[event deltaX],[event deltaY]);
}



- (id)initWithStand:(id)core
{
    self = [super initWithStand:core];
    if (self) {
        [self setupOneKeyNavigationMenuItem];
        BOOL enabled=[[NSUserDefaults standardUserDefaults]boolForKey:kpSwitchTabWithOneKeyEnabled];
        [self setupTabNavigationMenuItem:enabled];
        
        enabled=[[NSUserDefaults standardUserDefaults]boolForKey:kpGoBackForwardByDeleteKeyEnabled];
        [self setupGoBackForwardMenuItem:enabled];
        
        [self observePrefValue:kpSwitchTabWithOneKeyEnabled];
        [self observePrefValue:kpGoBackForwardByDeleteKeyEnabled];
//スワイプでタブ移動 保留
#if 0
        if(floor(NSAppKitVersionNumber)<=NSAppKitVersionNumber10_6){
        //10.6
            orig_goBack = RMF(NSClassFromString(kSafariBrowserWindowController),
                                                 @selector(goBackAndFlashToolbarButton:), ST_goBack);
            orig_goForward = RMF(NSClassFromString(kSafariBrowserWindowController),
                                                    @selector(goForwardAndFlashToolbarButton:), ST_goForward);
        }else{
        //10.7
           /*orig_beginSwipeGestureWithEvent = RMF(NSClassFromString(@"WKView"),
                                                 @selector(beginGestureWithEvent:), ST_beginSwipeGestureWithEvent);
            orig_beginTCSwipeGestureWithEvent = RMF(NSClassFromString(@"TabContentView"),
                                                @selector(beginSwipeGestureWithEvent:), ST_beginTCSwipeGestureWithEvent);
            orig_endSwipeGestureWithEvent = RMF(NSClassFromString(@"TabContentView"),
                                                 @selector(endGestureWithEvent:), ST_endSwipeGestureWithEvent);

            */
        }
#endif
//スワイプでタブ移動 保留

    }
    return self;
}

- (void)dealloc
{
    [oneKeyNavigationMenuItem release];
    [super dealloc];
}

- (void)prefValue:(NSString*)key changed:(id)value
{
    if([key isEqualToString:kpSwitchTabWithOneKeyEnabled]){
        //BOOL enabled=[[NSUserDefaults standardUserDefaults]boolForKey:kpSwitchTabWithOneKeyEnabled];
        BOOL enabled=[value boolValue];
        [self setupTabNavigationMenuItem:enabled];
        //if(enabled)[self insertOneKeyNavigationMenuItem];
        //else [self removeOneKeyNavigationMenuItem];
    }else if([key isEqualToString:kpGoBackForwardByDeleteKeyEnabled]){
        BOOL enabled=[value boolValue];
        [self setupGoBackForwardMenuItem:enabled];
    }
}


-(void)setupOneKeyNavigationMenuItem{
    
    NSMenu* subMenu=[[NSMenu alloc]initWithTitle:@"Navigation"];
    oneKeyNavigationMenuItem=[[NSMenuItem alloc]initWithTitle:@"Navigation" action:nil keyEquivalent:@""];
    //[oneKeyNavigationMenuItem setHidden:YES];
    
    id m;
    m=[subMenu addItemWithTitle:@"selectPreviousTab" action:@selector(selectPreviousTab:) keyEquivalent:@""];
    [m setKeyEquivalentModifierMask:0];
    [m setTag:kMenuItemTagSelectPreviousTab];
    m=[subMenu addItemWithTitle:@"selectNextTab" action:@selector(selectNextTab:) keyEquivalent:@""];
    [m setKeyEquivalentModifierMask:0];
    [m setTag:kMenuItemTagSelectNextTab];

    m=[subMenu addItemWithTitle:@"goBack" action:@selector(goBack:) keyEquivalent:@""];
    [m setKeyEquivalentModifierMask:0];
    [m setTag:kMenuItemTagGoBack];
    m=[subMenu addItemWithTitle:@"goForward" action:@selector(goForward:) keyEquivalent:@""];
    [m setKeyEquivalentModifierMask:0];
    [m setTag:kMenuItemTagGoForward];
    
    [oneKeyNavigationMenuItem setSubmenu:subMenu];
    [subMenu release];
    [oneKeyNavigationMenuItem setTag:kMenuItemTagOneKeyNavigation];
    
    //insert
    NSMenu* standMenu=[STCSafariStandCore si].standMenu;
    id toRemove=[standMenu itemWithTag:kMenuItemTagOneKeyNavigation];
    if(!toRemove){
        [[STCSafariStandCore si]addItemToStandMenu:oneKeyNavigationMenuItem];
    }
}

-(void)insertOneKeyNavigationMenuItem{
    NSMenu* standMenu=[STCSafariStandCore si].standMenu;
    id toRemove=[standMenu itemWithTag:kMenuItemTagOneKeyNavigation];
    if(!toRemove){
        [[STCSafariStandCore si]addItemToStandMenu:oneKeyNavigationMenuItem];
    }
}
-(void)removeOneKeyNavigationMenuItem{
    NSMenu* standMenu=[STCSafariStandCore si].standMenu;
    id toRemove=[standMenu itemWithTag:kMenuItemTagOneKeyNavigation];
    if(toRemove){
        [standMenu removeItem:toRemove];
    }
}

-(void)setupTabNavigationMenuItem:(BOOL)enabled
{
    NSMenuItem* m;

    m=[[oneKeyNavigationMenuItem submenu]itemWithTag:kMenuItemTagSelectPreviousTab];
    if (m) {
        if (enabled) [m setKeyEquivalent:@","];
        else  [m setKeyEquivalent:@""];
    }
    m=[[oneKeyNavigationMenuItem submenu]itemWithTag:kMenuItemTagSelectNextTab];
    if (m) {
        if (enabled) [m setKeyEquivalent:@"."];
        else  [m setKeyEquivalent:@""];
    }
}

-(void)setupGoBackForwardMenuItem:(BOOL)enabled
{
    NSMenuItem* m;
    NSString* key;
    
    if (enabled) {
        unichar *del=(unichar *)NSBackspaceCharacter;
        key=[NSString stringWithCharacters:(const unichar *)&del length:1];
    }else {
        key=@"";
    }
    
    m=[[oneKeyNavigationMenuItem submenu]itemWithTag:kMenuItemTagGoBack];
    if (m) {
        [m setKeyEquivalent:key];
    }
    m=[[oneKeyNavigationMenuItem submenu]itemWithTag:kMenuItemTagGoForward];
    if (m) {
        [m setKeyEquivalent:key];
        if (enabled) [m setKeyEquivalentModifierMask:NSControlKeyMask];
        else  [m setKeyEquivalentModifierMask:0];
    }
}



@end
