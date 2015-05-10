//
//  STKeyHandlerModule.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import "SafariStand.h"
#import "STKeyHandlerModule.h"


@implementation STKeyHandlerModule{
    NSMenuItem* _oneKeyNavigationMenuItem;
}

- (id)initWithStand:(id)core
{
    self = [super initWithStand:core];
    if (!self) return nil;
    
    
    [self setupOneKeyNavigationMenuItem];
    BOOL enabled=[[STCSafariStandCore ud]boolForKey:kpSwitchTabWithOneKeyEnabled];
    [self setupTabNavigationMenuItem:enabled];
    
    
    [self observePrefValue:kpSwitchTabWithOneKeyEnabled];
    
    
    return self;
}


- (void)prefValue:(NSString*)key changed:(id)value
{
    if([key isEqualToString:kpSwitchTabWithOneKeyEnabled]){
        //BOOL enabled=[[STCSafariStandCore ud]boolForKey:kpSwitchTabWithOneKeyEnabled];
        BOOL enabled=[value boolValue];
        [self setupTabNavigationMenuItem:enabled];
        //if(enabled)[self insertOneKeyNavigationMenuItem];
        //else [self removeOneKeyNavigationMenuItem];
    }
}


- (void)setupOneKeyNavigationMenuItem
{
    NSMenu* subMenu=[[NSMenu alloc]initWithTitle:@"Navigation"];
    _oneKeyNavigationMenuItem=[[NSMenuItem alloc]initWithTitle:@"Navigation" action:nil keyEquivalent:@""];
    //[_oneKeyNavigationMenuItem setHidden:YES];
    
    id m;
    m=[subMenu addItemWithTitle:@"selectPreviousTab" action:@selector(selectPreviousTab:) keyEquivalent:@""];
    [m setKeyEquivalentModifierMask:0];
    [m setTag:kMenuItemTagSelectPreviousTab];
    m=[subMenu addItemWithTitle:@"selectNextTab" action:@selector(selectNextTab:) keyEquivalent:@""];
    [m setKeyEquivalentModifierMask:0];
    [m setTag:kMenuItemTagSelectNextTab];

    
    [_oneKeyNavigationMenuItem setSubmenu:subMenu];

    [_oneKeyNavigationMenuItem setTag:kMenuItemTagOneKeyNavigation];
    
    //insert
    NSMenu* standMenu=[STCSafariStandCore si].standMenu;
    id toRemove=[standMenu itemWithTag:kMenuItemTagOneKeyNavigation];
    if(!toRemove){
        [[STCSafariStandCore si]addItemToStandMenu:_oneKeyNavigationMenuItem];
    }
}


- (void)insertOneKeyNavigationMenuItem
{
    NSMenu* standMenu=[STCSafariStandCore si].standMenu;
    id toRemove=[standMenu itemWithTag:kMenuItemTagOneKeyNavigation];
    if(!toRemove){
        [[STCSafariStandCore si]addItemToStandMenu:_oneKeyNavigationMenuItem];
    }
}


- (void)removeOneKeyNavigationMenuItem
{
    NSMenu* standMenu=[STCSafariStandCore si].standMenu;
    id toRemove=[standMenu itemWithTag:kMenuItemTagOneKeyNavigation];
    if(toRemove){
        [standMenu removeItem:toRemove];
    }
}


- (void)setupTabNavigationMenuItem:(BOOL)enabled
{
    NSMenuItem* m;

    m=[[_oneKeyNavigationMenuItem submenu]itemWithTag:kMenuItemTagSelectPreviousTab];
    if (m) {
        if (enabled) [m setKeyEquivalent:@","];
        else  [m setKeyEquivalent:@""];
    }
    m=[[_oneKeyNavigationMenuItem submenu]itemWithTag:kMenuItemTagSelectNextTab];
    if (m) {
        if (enabled) [m setKeyEquivalent:@"."];
        else  [m setKeyEquivalent:@""];
    }
}


@end
