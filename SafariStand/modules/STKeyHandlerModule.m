//
//  STKeyHandlerModule.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import "SafariStand.h"
#import "STKeyHandlerModule.h"


@implementation STKeyHandlerModule

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

    }
    return self;
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


-(void)setupOneKeyNavigationMenuItem
{
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

    [oneKeyNavigationMenuItem setTag:kMenuItemTagOneKeyNavigation];
    
    //insert
    NSMenu* standMenu=[STCSafariStandCore si].standMenu;
    id toRemove=[standMenu itemWithTag:kMenuItemTagOneKeyNavigation];
    if(!toRemove){
        [[STCSafariStandCore si]addItemToStandMenu:oneKeyNavigationMenuItem];
    }
}

-(void)insertOneKeyNavigationMenuItem
{
    NSMenu* standMenu=[STCSafariStandCore si].standMenu;
    id toRemove=[standMenu itemWithTag:kMenuItemTagOneKeyNavigation];
    if(!toRemove){
        [[STCSafariStandCore si]addItemToStandMenu:oneKeyNavigationMenuItem];
    }
}

-(void)removeOneKeyNavigationMenuItem
{
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
    return; //do nothing
    
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
