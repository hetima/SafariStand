//
//  STTabPickerModule.m
//  SafariStand


#import "SafariStand.h"
#import "STTabPickerModule.h"


id STArrayNextItem(NSArray* ary, id itm)
{
    if ([ary count]>1) {
        NSUInteger idx=[ary indexOfObjectIdenticalTo:itm];
        if (idx+1<[ary count]) {
            return [ary objectAtIndex:idx+1];
        }
    }
    return nil;
}

id STArrayPrevItem(NSArray* ary, id itm)
{
    if ([ary count]>1) {
        NSUInteger idx=[ary indexOfObjectIdenticalTo:itm];
        if (idx>0) {
            return [ary objectAtIndex:idx-1];
        }
    }
    return nil;
}



@implementation STTabPickerProxy {
    id _ctl;
}


+ (id)proxyWithVisualTabPickerViewController:(id)ctl
{
    if (![[ctl className]isEqualToString:@"VisualTabPickerViewController"]) {
        return nil;
    }
    
    id proxy=[[STTabPickerProxy alloc]initWithVisualTabPickerViewController:ctl];
    
    return proxy;
}

- (id)initWithVisualTabPickerViewController:(id)ctl
{
    self = [super init];
    if (!self) return nil;
    
    _ctl=ctl;
    
    return self;
}


- (id)visualTabPickerViewController
{
    return _ctl;
}


// return VisualTabPickerGridView
- (id)gridView
{
    id rootView=[_ctl valueForKey:@"_rootView"];
    if (!rootView) {
        return nil;
    }
    
    id gridView=((id(*)(id, SEL, ...))objc_msgSend)(rootView, NSSelectorFromString(@"gridView"));
    
    return gridView;
}


- (id)searchField
{
    id rootView=[_ctl valueForKey:@"_rootView"];
    if (!rootView) {
        return nil;
    }
    
    id searchField=((id(*)(id, SEL, ...))objc_msgSend)(rootView, NSSelectorFromString(@"searchField"));
    
    return searchField;
    
}

- (BOOL)hasAnySearchText
{
    NSSearchField* searchField=[self searchField];
    
    NSString* str=[searchField stringValue];
    
    if ([str length]) {
        return YES;
    }
    return NO;
}

// return array[BrowserTabViewItem]
- (NSArray*)orderedTabItems
{
    id result=((id(*)(id, SEL, ...))objc_msgSend)(_ctl, NSSelectorFromString(@"orderedTabItemsInVisualTabPickerGridView:"), nil);
    return result;
}


#pragma mark - thumbnailView

- (id)firstThumbnailView
{
    return [self nextThumbnailView:nil];
}


- (id)lastThumbnailView
{
    return [self prevThumbnailView:nil];
}


- (id)focusedThumbnailView
{
    return [_ctl htao_valueForKey:@"focusedThumbnailView"];
}


- (id)nextThumbnailView:(id)aThumbnailView
{
    id gridView=[self gridView];
    if (!gridView) {
        return nil;
    }
    
    __block BOOL isTarget=NO;
    __block id targetView=nil;
    
    if (!aThumbnailView) {
        //force select first view
        isTarget=YES;
    }
    
    NSArray* tileContainerViews=[gridView valueForKey:@"_tileContainerViews"];
    [tileContainerViews enumerateObjectsUsingBlock:^(id containerView, NSUInteger idx, BOOL *stop) {
        NSArray* views=[containerView valueForKey:@"_thumbnailViews"];
        [views enumerateObjectsUsingBlock:^(id thumbnailView, NSUInteger idx2, BOOL *stop2) {
            if ([[thumbnailView className]isEqualToString:@"VisualTabPickerThumbnailView"]) {
                if (!targetView) {
                    targetView=thumbnailView; //fallback
                }
                if (isTarget) {
                    targetView=thumbnailView;
                    *stop2=YES;
                    *stop=YES;
                    return;
                }
            }
            if (thumbnailView==aThumbnailView) {
                isTarget=YES;
                return;
            }

        }];
    }];


    return targetView;
}


- (id)prevThumbnailView:(id)aThumbnailView
{
    id gridView=[self gridView];
    if (!gridView) {
        return nil;
    }
    
    __block BOOL isTarget=NO;
    __block id targetView=nil;
    
    if (!aThumbnailView) {
        //force select last view
        isTarget=YES;
    }

    NSArray* tileContainerViews=[gridView valueForKey:@"_tileContainerViews"];
    [tileContainerViews enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id containerView, NSUInteger idx, BOOL *stop) {
        NSArray* views=[containerView valueForKey:@"_thumbnailViews"];
        [views enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id thumbnailView, NSUInteger idx2, BOOL *stop2) {
            if ([[thumbnailView className]isEqualToString:@"VisualTabPickerThumbnailView"]) {
                if (!targetView) {
                    targetView=thumbnailView; //fallback
                }
                if (isTarget) {
                    targetView=thumbnailView;
                    *stop2=YES;
                    *stop=YES;
                    return;
                }
            }
            if (thumbnailView==aThumbnailView) {
                isTarget=YES;
                return;
            }
            
        }];
    }];
    
    return targetView;
}


- (id)aboveThumbnailView:(NSView*)thumbnailView
{
    id targetView=nil;
    
    if (![[thumbnailView className]isEqualToString:@"VisualTabPickerThumbnailView"]) {
        return nil;
    }
    id containerView=[thumbnailView valueForKey:@"dataSource"];
    if (!containerView) {
        return nil;
    }
    
    //stacked
    NSArray* views=[containerView valueForKey:@"_thumbnailViews"];
    targetView=STArrayPrevItem(views, thumbnailView);
    if (targetView) {
        return targetView;
    }
    
    NSArray* containerViews=[self arrangedContainerViewsAtSameColumn:containerView];
    id targetContainerView=STArrayPrevItem(containerViews, containerView);
    if (targetContainerView) {
        targetView=[[targetContainerView valueForKey:@"_thumbnailViews"]lastObject];
        if (![[targetView className]isEqualToString:@"VisualTabPickerThumbnailView"]) {
            return nil;
        }
    }
    
    return targetView;
}


- (id)belowThumbnailView:(NSView*)thumbnailView
{
    id targetView=nil;
    
    if (![[thumbnailView className]isEqualToString:@"VisualTabPickerThumbnailView"]) {
        return nil;
    }
    id containerView=[thumbnailView valueForKey:@"dataSource"];
    if (!containerView) {
        return nil;
    }
    
    //stacked
    NSArray* views=[containerView valueForKey:@"_thumbnailViews"];
    targetView=STArrayNextItem(views, thumbnailView);
    if (targetView) {
        return targetView;
    }

    NSArray* containerViews=[self arrangedContainerViewsAtSameColumn:containerView];
    id targetContainerView=STArrayNextItem(containerViews, containerView);
    if (targetContainerView) {
        targetView=[[targetContainerView valueForKey:@"_thumbnailViews"]firstObject];
        if (![[targetView className]isEqualToString:@"VisualTabPickerThumbnailView"]) {
            return nil;
        }
    }
    
    return targetView;
}


- (NSArray*)arrangedContainerViewsAtSameColumn:(NSView*)containerView
{
    NSView* gridView=[self gridView];
    if (!gridView) {
        return nil;
    }
    

    CGFloat x=containerView.frame.origin.x;
    NSArray* tileContainerViews=[gridView valueForKey:@"_tileContainerViews"];
    
    NSMutableArray* result=[[NSMutableArray alloc]initWithCapacity:[tileContainerViews count]];
    
    for (NSView* view in tileContainerViews) {
        if (view.frame.origin.x==x) {
            [result addObject:view];
        }
    }
    
    return result;
}


- (void)focusThumbnailView:(NSView*)aThumbnailView
{
    if(!aThumbnailView){
        return;
    }
    
    NSView* gridView=[self gridView];
    if (!gridView) {
        return;
    }
    
    [_ctl htao_setValue:nil forKey:@"focusedThumbnailView"];
    
    static CGColorRef focusedColor=nil;
    if (!focusedColor) {
        focusedColor=//[[NSColor colorWithDeviceRed:50.0f/255.0f green:150.0f/255.0f blue:250.0f/255.0f alpha:1.0]CGColor];
        [[NSColor selectedMenuItemColor]CGColor];
        CFRetain(focusedColor);
    }
    

    NSArray* tileContainerViews=[gridView valueForKey:@"_tileContainerViews"];
    [tileContainerViews enumerateObjectsUsingBlock:^(NSView* containerView, NSUInteger idx, BOOL *stop) {
        NSArray* views=[containerView valueForKey:@"_thumbnailViews"];
        [views enumerateObjectsUsingBlock:^(NSView* thumbnailView, NSUInteger idx2, BOOL *stop2) {
            id focusMark=[thumbnailView htao_valueForKey:@"focusMark"];
            if (focusMark) {
                NSView* headerView=[thumbnailView valueForKey:@"_headerBackgroundView"];
                headerView.layer.backgroundColor=[[NSColor controlHighlightColor]CGColor];
                if ([[thumbnailView className]isEqualToString:@"VisualTabPickerThumbnailView"]) {
                    NSTextField *titleTextField=[thumbnailView valueForKey:@"_titleTextField"];
                    titleTextField.textColor=[NSColor controlTextColor];
                }
                [thumbnailView htao_setValue:nil forKey:@"focusMark"];
            }
            if (thumbnailView==aThumbnailView) {
                NSView* headerView=[thumbnailView valueForKey:@"_headerBackgroundView"];
                headerView.layer.backgroundColor=focusedColor;
                if ([[thumbnailView className]isEqualToString:@"VisualTabPickerThumbnailView"]) {
                    NSTextField *titleTextField=[thumbnailView valueForKey:@"_titleTextField"];
                    titleTextField.textColor=[NSColor selectedMenuItemTextColor];
                }
                [thumbnailView htao_setValue:@"YES" forKey:@"focusMark"];
                [_ctl htao_setValue:aThumbnailView forKey:@"focusedThumbnailView"];
                
                [[gridView valueForKey:@"_gridContainerView"] scrollRectToVisible:[containerView frame]];

            }
        }];
    }];
}


- (void)focusNextThumbnailView
{
    id thumbnailView=[self nextThumbnailView:[self focusedThumbnailView]];
    [self focusThumbnailView:thumbnailView];
}


- (void)focusPrevThumbnailView
{
    id thumbnailView=[self prevThumbnailView:[self focusedThumbnailView]];
    [self focusThumbnailView:thumbnailView];
}


- (void)focusAboveThumbnailView
{
    id thumbnailView=[self aboveThumbnailView:[self focusedThumbnailView]];
    [self focusThumbnailView:thumbnailView];
}


- (void)focusBelowThumbnailView
{
    id thumbnailView=[self belowThumbnailView:[self focusedThumbnailView]];
    [self focusThumbnailView:thumbnailView];
}


- (void)selectFocusedTab
{
    id thumbnailView=[self focusedThumbnailView];
    if (!thumbnailView && ![[thumbnailView className]isEqualToString:@"VisualTabPickerThumbnailView"]) {
        return;
    }
    id containerView=[thumbnailView valueForKey:@"dataSource"];
    if (!containerView) {
        return;
    }
    NSArray* views=[containerView valueForKey:@"_thumbnailViews"];
    NSUInteger idx=[views indexOfObjectIdenticalTo:thumbnailView];
    if (idx!=NSNotFound) {
        id gridView=[self gridView];
        if ([gridView respondsToSelector:@selector(visualTabPickerTileContainerView:didSelectTileAtIndex:)]) {
            ((void(*)(id, SEL, ...))objc_msgSend)(gridView, @selector(visualTabPickerTileContainerView:didSelectTileAtIndex:), containerView, idx);
        }

    }
}


@end


@implementation STTabPickerModule

+ (BOOL)canUseModule
{
    Class visualTabPickerViewController=NSClassFromString(@"VisualTabPickerViewController");
    
    if (![visualTabPickerViewController instancesRespondToSelector:NSSelectorFromString(@"orderedTabItemsInVisualTabPickerGridView:")]) {
        return NO;
    }
    
    return YES;
}

- (id)initWithStand:(id)core
{
    self = [super initWithStand:core];
    if (!self) return nil;
    
    
    KZRMETHOD_SWIZZLING_("VisualTabPickerViewController", "shouldStackMultipleThumbnailsInOneContainerIfPossible",
                         BOOL, call, sel)
    ^BOOL(id slf)
    {
        if([[NSUserDefaults standardUserDefaults]boolForKey:kpDontStackVisualTabPicker]){
            return NO;
        }
        
        BOOL result=call(slf, sel);
        return result;
    }_WITHBLOCK;
    

    
    KZRMETHOD_SWIZZLING_("VisualTabPickerViewController", "loadView", void, call, sel)
    ^(id slf)
    {
        call(slf, sel);
        if([[NSUserDefaults standardUserDefaults]boolForKey:kpEnhanceVisualTabPicker]){
            STTabPickerProxy* proxy=[STTabPickerProxy proxyWithVisualTabPickerViewController:slf];
            [self resetPickerFocus:proxy];
//            ((void(*)(id, SEL, ...))objc_msgSend)(slf, NSSelectorFromString(@"focusSearchField"));
        }
        
    }_WITHBLOCK;
    
    KZRMETHOD_SWIZZLING_("VisualTabPickerViewController", "_reloadGridView", void, call, sel)
    ^(id slf)
    {
        call(slf, sel);
        if([[NSUserDefaults standardUserDefaults]boolForKey:kpEnhanceVisualTabPicker]){
            STTabPickerProxy* proxy=[STTabPickerProxy proxyWithVisualTabPickerViewController:slf];
            [self resetPickerFocus:proxy];
        }
    }_WITHBLOCK;
    

    
    KZRMETHOD_SWIZZLING_("VisualTabPickerViewController", "control:textView:doCommandBySelector:", BOOL, call, sel)
    ^BOOL(id slf, id arg1, id arg2, SEL arg3)
    {
        BOOL result;
        if([[NSUserDefaults standardUserDefaults]boolForKey:kpEnhanceVisualTabPicker]){
            STTabPickerProxy* proxy=[STTabPickerProxy proxyWithVisualTabPickerViewController:slf];
            result=[self visualTabPicker:proxy handleCommandBySelector:arg3];
            if (result) {
                return YES;
            }
        }
        result=call(slf, sel, arg1, arg2, arg3);
        return result;
        
    }_WITHBLOCK;

    
    [NSEvent addLocalMonitorForEventsMatchingMask:NSKeyDownMask handler:^NSEvent *(NSEvent *event) {
        unsigned short key=[event keyCode];
        if(key!=48){
            return event;
        }

        if (![[NSUserDefaults standardUserDefaults]boolForKey:kpEnhanceVisualTabPicker]) {
            return event;
        }
        
        if (![[NSUserDefaults standardUserDefaults]boolForKey:kpCtlTabTriggersVisualTabPicker]) {
            return event;
        }
        
        NSEventModifierFlags flag=[event modifierFlags];
        if ((flag & NSDeviceIndependentModifierFlagsMask)==NSControlKeyMask) {
            id picker=[self activeVisualTabPicker];
            if (picker) {
                STTabPickerProxy* proxy=[STTabPickerProxy proxyWithVisualTabPickerViewController:picker];
                [self visualTabPicker:proxy handleCommandBySelector:@selector(insertTab:)];
            }else{
                [NSApp sendAction:NSSelectorFromString(@"toggleVisualTabPicker:") to:nil from:nil];
            }
            return nil;
        }else if((flag & NSDeviceIndependentModifierFlagsMask)==(NSControlKeyMask|NSShiftKeyMask)) {
            id picker=[self activeVisualTabPicker];
            if (picker) {
                STTabPickerProxy* proxy=[STTabPickerProxy proxyWithVisualTabPickerViewController:picker];
                [self visualTabPicker:proxy handleCommandBySelector:@selector(insertBacktab:)];
            }
            return nil;
        }
        return event;
    }];
    
    //VisualTabPicker 表示中に responder から外れることがある対策
    KZRMETHOD_SWIZZLING_("BrowserWindow", "keyDown:", void, call, sel)
    ^(id slf, NSEvent* event)
    {
        unsigned short key=[event keyCode];
        SEL cmd=nil;
        if ([[NSUserDefaults standardUserDefaults]boolForKey:kpEnhanceVisualTabPicker]) {

            if(key==48){
                cmd= ([event modifierFlags] & NSShiftKeyMask)==NSShiftKeyMask ? @selector(insertBacktab:):@selector(insertTab:);
            }else if(key==36||key==76){
                cmd=@selector(insertNewline:);
            }else if(key==0x7B){
                cmd=@selector(moveLeft:);
            }else if(key==0x7C){
                cmd=@selector(moveRight:);
            }else if(key==0x7E){
                cmd=@selector(moveUp:);
            }else if(key==0x7D){
                cmd=@selector(moveDown:);
            }
        }
        
        if (cmd) {
            id picker=[self activeVisualTabPicker];
            if (picker) {
                STTabPickerProxy* proxy=[STTabPickerProxy proxyWithVisualTabPickerViewController:picker];
                [self visualTabPicker:proxy handleCommandBySelector:cmd];
                return;
            }
        }

        call(slf, sel, event);
        
    }_WITHBLOCK;

    
    return self;
}


- (void)dealloc
{
    
}


- (void)prefValue:(NSString*)key changed:(id)value
{
    //if([key isEqualToString:])
}


- (BOOL)visualTabPicker:(STTabPickerProxy*)proxy handleCommandBySelector:(SEL)cmd
{
    NSString* command=NSStringFromSelector(cmd);
    //LOG(@"%@",command);
    if ([command isEqualToString:@"insertNewline:"]) {
        [proxy selectFocusedTab];
        return YES;
        
    }else if ([command isEqualToString:@"moveLeft:"]){
        if (![proxy hasAnySearchText]) {
            [proxy focusPrevThumbnailView];
            return YES;
        }
        
    }else if ([command isEqualToString:@"moveRight:"]){
        if (![proxy hasAnySearchText]) {
            [proxy focusNextThumbnailView];
            return YES;
        }
    }else if ([command isEqualToString:@"moveDown:"]){
        [proxy focusBelowThumbnailView];
        return YES;
        
    }else if ([command isEqualToString:@"moveUp:"]){
        [proxy focusAboveThumbnailView];
        return YES;
        
    }else if ([command isEqualToString:@"insertTab:"]){
        [proxy focusNextThumbnailView];
        return YES;
        
    }else if ([command isEqualToString:@"insertBacktab:"]){
        [proxy focusPrevThumbnailView];
        return YES;
        
    }else if ([command isEqualToString:@"cancelOperation:"]){
        return NO;
        
    }
    
    return NO;
    
}


- (void)resetPickerFocus:(STTabPickerProxy*)proxy
{
    id ary=[proxy orderedTabItems];
    if ([ary count]==0) {
        return;
    }
    id firstThumbnailView=[proxy firstThumbnailView];
    [proxy focusThumbnailView:firstThumbnailView];
}


- (id)activeVisualTabPicker
{
    id winCtl=[[NSApp keyWindow]windowController];
    if ([[winCtl className]isEqualToString:kSafariBrowserWindowController]) {
        if ([winCtl respondsToSelector:@selector(isShowingVisualTabPicker)]) {
            BOOL isShowing=((BOOL(*)(id, SEL, ...))objc_msgSend)(winCtl, @selector(isShowingVisualTabPicker));
            if (isShowing) {
                return [winCtl valueForKey:@"_visualTabPickerViewController"];;
            }
        }

    }

    return nil;
}


@end

