//
//  STSTabBarModule.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import <mach/mach_time.h>
#import "SafariStand.h"
#import "STSTabBarModule.h"
#import "STTabProxy.h"

@implementation STSTabBarModule {
    uint64_t _nextTime;
    uint64_t _duration;
}


-(void)layoutTabBarForExistingWindow
{
    //check exists window
    STSafariEnumerateBrowserWindow(^(NSWindow* win, NSWindowController* winCtl, BOOL* stop){
        if([win isVisible] && [winCtl respondsToSelector:@selector(isTabBarVisible)]
           && [winCtl respondsToSelector:@selector(tabBarView)]
           ){
            if (objc_msgSend(winCtl, @selector(isTabBarVisible))) {
                id tabBarView = objc_msgSend(winCtl, @selector(tabBarView));
                if([tabBarView respondsToSelector:@selector(_updateButtonsAndLayOutAnimated:)]){
                    objc_msgSend(tabBarView, @selector(_updateButtonsAndLayOutAnimated:), YES);
                }
            }
        }
    });
}

- (id)initWithStand:(id)core
{
    self = [super initWithStand:core];
    if (!self) return nil;
    
    //SwitchTabWithWheel
    mach_timebase_info_data_t timebaseInfo;
    mach_timebase_info(&timebaseInfo);
    _duration = ((1000000000 * timebaseInfo.denom) / 3) / timebaseInfo.numer; //1/3sec
    _nextTime=mach_absolute_time();
    
    KZRMETHOD_SWIZZLING_("TabBarView", "scrollWheel:", void, call, sel)
    ^void (id slf, NSEvent* event)
    {
        if([[STCSafariStandCore ud]boolForKey:kpSwitchTabWithWheelEnabled]){
            id window=objc_msgSend(slf, @selector(window));
            if([[[window windowController]className]isEqualToString:kSafariBrowserWindowController]){
                if ([self canAction]) {
                    SEL action=nil;
                    //[theEvent deltaY] が+なら上、-なら下
                    CGFloat deltaY=[event deltaY];
                    if(deltaY>0){
                        action=@selector(selectPreviousTab:);
                    }else if(deltaY<0){
                        action=@selector(selectNextTab:);
                    }
                    if(action){
                        [NSApp sendAction:action to:nil from:self];
                        return;
                    }
                }
            }
        }
        
        call(slf, sel, event);
        
    }_WITHBLOCK;
    
    
    //タブバー幅変更
    KZRMETHOD_SWIZZLING_("TabBarView", "_buttonWidthForNumberOfButtons:inWidth:remainderWidth:", double, call, sel)
    ^double (id slf, unsigned long long buttonNum, double inWidth, double* remainderWidth)
    {
        double result=call(slf, sel, buttonNum, inWidth, remainderWidth);
        if ([[STCSafariStandCore ud]boolForKey:kpSuppressTabBarWidthEnabled]) {
            double maxWidth=floor([[STCSafariStandCore ud]doubleForKey:kpSuppressTabBarWidthValue]);
            if (result>maxWidth) {
                //double diff=result-maxWidth;
                //*remainderWidth=diff+*remainderWidth;
                return maxWidth;
            }
        }
        return result;
    }_WITHBLOCK;
    
    KZRMETHOD_SWIZZLING_("TabBarView", "_shouldLayOutButtonsToAlignWithWindowCenter", BOOL, call, sel)
    ^BOOL (id slf)
    {
        if ([[STCSafariStandCore ud]boolForKey:kpSuppressTabBarWidthEnabled]) {
            return NO;
        }
        
        BOOL result=call(slf, sel);
        return result;
    }_WITHBLOCK;
    
    //follow empty space
    KZRMETHOD_SWIZZLING_("TabBarView", "_tabIndexAtPoint:", unsigned long long, call, sel)
    ^NSUInteger(id slf, struct CGPoint arg1)
    {
        NSUInteger result=call(slf, sel, arg1);
        if ([[STCSafariStandCore ud]boolForKey:kpSuppressTabBarWidthEnabled]) {
            if (result==0) {
                double maxWidth=floor([[STCSafariStandCore ud]doubleForKey:kpSuppressTabBarWidthValue]);
                if (arg1.x > maxWidth) {
                    result=NSNotFound;
                }
            }else if (result!=NSNotFound) {
                if ([slf respondsToSelector:@selector(_numberOfTabsForLayout)]) {
                    NSUInteger num=((NSUInteger(*)(id, SEL, ...))objc_msgSend)(slf, @selector(_numberOfTabsForLayout));
                    if (num <= result) {
                        result=NSNotFound;
                    }
                }
            }
        }
        return result;
    }_WITHBLOCK;
    
    //タブバー狭くして空きスペースができているときドロップの対処
    KZRMETHOD_SWIZZLING_("TabBarView", "_moveButton:toIndex:", void, call, sel)
    ^(id slf, id button, unsigned long long index)
    {
        if (index==NSNotFound) {
            index=0;
            if ([slf respondsToSelector:@selector(tabButtons)]) {
                NSArray *tabButtons=((id(*)(id, SEL, ...))objc_msgSend)(slf, @selector(tabButtons));
                NSUInteger num=[tabButtons count];
                if (num>0) {
                    index=num-1;
                }
            }
        }
        
        call(slf, sel, button, index);
    }_WITHBLOCK;
    
    
    double minX=[[STCSafariStandCore ud]doubleForKey:kpSuppressTabBarWidthValue];
    if (minX<140.0 || minX>480.0) minX=240.0;
    if ([[STCSafariStandCore ud]boolForKey:kpSuppressTabBarWidthEnabled]) {
        [self layoutTabBarForExistingWindow];
    }
    [self observePrefValue:kpSuppressTabBarWidthEnabled];
    [self observePrefValue:kpSuppressTabBarWidthValue];
    
    
    //ShowIconOnTabBar
    KZRMETHOD_SWIZZLING_("TabButton", "initWithFrame:tabBarViewItem:", id, call, sel)
    ^id (id slf, NSRect frame, id obj)
    {
        NSButton* result=call(slf, sel, frame, obj);
        if ([[STCSafariStandCore ud]boolForKey:kpShowIconOnTabBarEnabled]) {
            [self _installIconToTabButton:result ofTabViewItem:obj];
        }
        
        return result;
    }_WITHBLOCK;
    KZRMETHOD_SWIZZLING_("TabButton", "setHasMouseOverHighlight:shouldAnimateCloseButton:", void, call, sel)
    ^(id slf, BOOL arg1, BOOL arg2)
    {
        call(slf, sel, arg1, arg2);
        STTabIconLayer* layer=[STTabIconLayer installedIconLayerInView:slf];
        if (layer) {
            layer.hidden=arg1;
        }
    }_WITHBLOCK;


    
    if ([[STCSafariStandCore ud]boolForKey:kpShowIconOnTabBarEnabled]) {
        [self installIconToExistingWindows];
    }
    [self observePrefValue:kpShowIconOnTabBarEnabled];
    

    return self;
}


- (void)dealloc
{

}


- (void)prefValue:(NSString*)key changed:(id)value
{
    if([key isEqualToString:kpSuppressTabBarWidthEnabled]||[key isEqualToString:kpSuppressTabBarWidthValue]){
        [self layoutTabBarForExistingWindow];
    }else if([key isEqualToString:kpShowIconOnTabBarEnabled]){
        if ([value boolValue]) {
            [self installIconToExistingWindows];
        }else{
            [self removeIconFromExistingWindows];
        }
    }
}


- (BOOL)canAction
{
    uint64_t now=mach_absolute_time();
    if (now>_nextTime) {
        _nextTime=now+_duration;
        return YES;
    }
    return NO;
}

#pragma mark -

-(void)_installIconToTabButton:(NSButton*)tabButton ofTabViewItem:(NSTabViewItem*)tabViewItem
{

    if([STTabIconLayer installedIconLayerInView:tabButton] != nil) {
        return;
    }

    if([[tabViewItem valueForKey:@"pinned"] boolValue]) {
        return;
    }

    NSView* closeButton=[tabButton valueForKey:@"_closeButton"];
    if (!closeButton) {
        return;
    }
    
    CALayer* layer=[STTabIconLayer layer];
    layer.frame=NSMakeRect(4, 3, 16, 16);
    layer.contents=nil;
    [tabButton.layer addSublayer:layer];

//    [layer bind:NSHiddenBinding toObject:closeButton withKeyPath:NSHiddenBinding options:@{ NSValueTransformerNameBindingOption : NSNegateBooleanTransformerName }];
    STTabProxy* tp=[STTabProxy tabProxyForTabViewItem:tabViewItem];
    if (tp) {
        [layer bind:@"contents" toObject:tp withKeyPath:@"image" options:nil];
    }
    
}


- (void)installIconToExistingWindows
{
    STSafariEnumerateTabButton(^(NSButton* tabBtn, BOOL* stop){
        if (![tabBtn respondsToSelector:@selector(tabBarViewItem)]) {
            return;
        }
        NSTabViewItem* tabViewItem=((id(*)(id, SEL, ...))objc_msgSend)(tabBtn, @selector(tabBarViewItem));
        
        [self _installIconToTabButton:tabBtn ofTabViewItem:tabViewItem];

    });
}


- (void)_removeIconFromTabButton:(NSButton*)tabButton ofTabViewItem:(NSTabViewItem*)tabViewItem
{
    CALayer* layer=[STTabIconLayer installedIconLayerInView:tabButton];
    if(layer)[layer removeFromSuperlayer];
}


- (void)removeIconFromExistingWindows
{
    STSafariEnumerateTabButton(^(NSButton* tabBtn, BOOL* stop){
        if (![tabBtn respondsToSelector:@selector(tabBarViewItem)]) {
            return;
        }
        NSTabViewItem* tabViewItem=((id(*)(id, SEL, ...))objc_msgSend)(tabBtn, @selector(tabBarViewItem));
        
        [self _removeIconFromTabButton:tabBtn ofTabViewItem:tabViewItem];

    });
}

@end



@implementation STTabIconLayer

+ (id)installedIconLayerInView:(NSView*)view
{
    NSArray* sublayers=view.layer.sublayers;
    for (CALayer* layer in sublayers) {
        if ([layer isKindOfClass:[self class]]) {
            return layer;
        }
    }
    return nil;
}


- (void)dealloc
{
//    [self unbind:NSHiddenBinding];
    [self unbind:@"contents"];
    LOG(@"layer d");
}

@end

