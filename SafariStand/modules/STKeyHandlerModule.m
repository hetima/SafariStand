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
    
    //Intercept cmd+num
    KZRMETHOD_SWIZZLING_(STSafariBookmarksControllerClass(), "goToNthFavoriteLeaf:", void, call, sel)
    ^(id slf, int arg1)
    {
        if ([[STCSafariStandCore ud]boolForKey:kpInterceptGoToNthFavorite]) {
            [self handleGoToNthFavoriteLeaf:arg1];
        }else{
            call(slf, sel, arg1);
        }
        
    }_WITHBLOCK;
    
    //switch tab with ,. 
    [core registerBrowserWindowKeyDownHandler:^BOOL(NSEvent *event, NSWindow* window) {

        if ([[STCSafariStandCore ud]boolForKey:kpSwitchTabWithOneKeyEnabled]) {
            unsigned short key=[event keyCode];
            NSEventModifierFlags flag=([event modifierFlags] & NSDeviceIndependentModifierFlagsMask);
            SEL cmd=nil;
            
            if (flag && flag!=NSControlKeyMask) {
                return NO;
            }
            if(key==0x2B||key==0x5F){//kVK_ANSI_Comma kVK_JIS_KeypadComma
                cmd=@selector(selectPreviousTab:);
            }else if(key==0x2F||key==0x41){//kVK_ANSI_Period kVK_ANSI_KeypadDecimal
                cmd=@selector(selectNextTab:);
            }
            
            if (cmd) {
                [NSApp sendAction:cmd to:nil from:nil];
                return YES;
            }
        }
        return NO;
    }];
    
    return self;
}


- (void)prefValue:(NSString*)key changed:(id)value
{

}



#pragma mark - Intercept cmd+num

- (BOOL)handleGoToNthFavoriteLeaf:(NSInteger)idx
{
    NSWindow* win=STSafariCurrentBrowserWindow();
    id winCtl=[win windowController];
    if (!winCtl) {
        return NO;
    }
    
    NSTabView* tabView=STTabSwitcherForWinCtl(winCtl);
    NSInteger cnt=[tabView numberOfTabViewItems];
    
    //cmd+9 selects the right end tab
    if (idx>=8) {
        idx=cnt-1;
    }
    
    if (cnt>idx) {
        id tab=[tabView tabViewItemAtIndex:idx];
        if ([tab tabState]!=NSSelectedTab && [winCtl respondsToSelector:@selector(_selectTab:)]) {
            objc_msgSend(winCtl, @selector(_selectTab:), tab);
            return YES;
        }
    }
    return NO;
}

@end
