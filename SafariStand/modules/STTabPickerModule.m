//
//  STTabPickerModule.m
//  SafariStand


#import "SafariStand.h"
#import "STTabPickerModule.h"

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


// return VisualTabPickerThumbnailView
- (id)thumbnailViewForTabViewItem:(id)tabviewItem
{
    if (!tabviewItem) {
        return nil;
    }
    
    id gridView=[self gridView];
    if (!gridView) {
        return nil;
    }
    
    NSArray* tileContainerViews=[gridView valueForKey:@"_tileContainerViews"];
    NSArray* arrayOfTabItemsPerContainer=[gridView valueForKey:@"_arrayOfTabItemsPerContainer"];
    
    __block NSInteger cIdx=-1;
    __block NSInteger tIdx=-1;
    [arrayOfTabItemsPerContainer enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj enumerateObjectsUsingBlock:^(id obj2, NSUInteger idx2, BOOL *stop2) {
            if (obj2==tabviewItem) {
                tIdx=idx2;
                cIdx=idx;
                *stop2=YES;
                *stop=YES;
            }
        }];
    }];
    
    if (tIdx<0 || cIdx>=[tileContainerViews count]) {
        return nil;
    }
    
    id containerView=[tileContainerViews objectAtIndex:cIdx];
    NSArray* views=[containerView valueForKey:@"_thumbnailViews"];
    if (tIdx>=[views count]) {
        return nil;
    }
    
    NSView* thumbnailView=[views objectAtIndex:tIdx];
    return thumbnailView;

}


- (id)firstTabViewItem
{
    NSArray* orderedTabItems=[self orderedTabItems];
    return [orderedTabItems firstObject];
}


- (id)focusedTabViewItem
{
    return [_ctl htao_valueForKey:@"focusedTabViewItem"];
}


- (id)nextTabViewItem:(id)tabviewItem
{
    NSArray* orderedTabItems=[self orderedTabItems];
    if (!tabviewItem) {
        return [orderedTabItems firstObject];
    }
    NSUInteger idx=[orderedTabItems indexOfObjectIdenticalTo:tabviewItem];
    if (idx==NSNotFound || [orderedTabItems count]<=idx+1) {
        return [orderedTabItems firstObject];
    }
    return [orderedTabItems objectAtIndex:idx+1];
}


- (id)prevTabViewItem:(id)tabviewItem
{
    NSArray* orderedTabItems=[self orderedTabItems];
    if (!tabviewItem) {
        return [orderedTabItems firstObject];
    }
    NSUInteger idx=[orderedTabItems indexOfObjectIdenticalTo:tabviewItem];
    if (idx==NSNotFound) {
        return [orderedTabItems firstObject];
    }
    if (idx==0) {
        return [orderedTabItems lastObject];
    }
    return [orderedTabItems objectAtIndex:idx-1];
}


- (void)focusTabViewItem:(id)tabviewItem
{
    [_ctl htao_setValue:nil forKey:@"focusedTabViewItem"];
    id gridView=[self gridView];
    if (!gridView) {
        return;
    }
    
    //clear
    NSArray* tileContainerViews=[gridView valueForKey:@"_tileContainerViews"];
    [tileContainerViews enumerateObjectsUsingBlock:^(id containerView, NSUInteger idx, BOOL *stop) {
        NSArray* views=[containerView valueForKey:@"_thumbnailViews"];
        [views enumerateObjectsUsingBlock:^(id thumbnailView, NSUInteger idx2, BOOL *stop2) {
            id focusMark=[thumbnailView htao_valueForKey:@"focusMark"];
            if (focusMark) {
                NSView* headerView=[thumbnailView valueForKey:@"_headerBackgroundView"];
                headerView.layer.backgroundColor=[[NSColor controlHighlightColor]CGColor];
                NSTextField *titleTextField=[thumbnailView valueForKey:@"_titleTextField"];
                titleTextField.textColor=[NSColor controlTextColor];
                [thumbnailView htao_setValue:nil forKey:@"focusMark"];
            }
        }];
    }];
    
    //set
    static CGColorRef focusedColor=nil;
    if (!focusedColor) {
        focusedColor=//[[NSColor colorWithDeviceRed:50.0f/255.0f green:150.0f/255.0f blue:250.0f/255.0f alpha:1.0]CGColor];
        [[NSColor selectedMenuItemColor]CGColor];
        CFRetain(focusedColor);
    }
    id thumbnailView=[self thumbnailViewForTabViewItem:tabviewItem];
    if (thumbnailView) {
        NSView* headerView=[thumbnailView valueForKey:@"_headerBackgroundView"];
        headerView.layer.backgroundColor=focusedColor;
        NSTextField *titleTextField=[thumbnailView valueForKey:@"_titleTextField"];
        titleTextField.textColor=[NSColor selectedMenuItemTextColor];
        [thumbnailView htao_setValue:@"YES" forKey:@"focusMark"];
        [_ctl htao_setValue:tabviewItem forKey:@"focusedTabViewItem"];
    }
    
}

- (void)selectFocusedTab
{
    id item=[self focusedTabViewItem];
    if (!item) {
        return;
    }
    id thumbnailView=[self thumbnailViewForTabViewItem:item];
    if (!thumbnailView) {
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
            id tabViewItem=[proxy prevTabViewItem:[proxy focusedTabViewItem]];
            [proxy focusTabViewItem:tabViewItem];
            return YES;
        }
    }else if ([command isEqualToString:@"moveRight:"]){
        if (![proxy hasAnySearchText]) {
            id tabViewItem=[proxy nextTabViewItem:[proxy focusedTabViewItem]];
            [proxy focusTabViewItem:tabViewItem];
            return YES;
        }
    //}else if ([command isEqualToString:@"moveDown:"]){
    //}else if ([command isEqualToString:@"moveUp:"]){
    }else if ([command isEqualToString:@"insertTab:"]){
        id tabViewItem=[proxy nextTabViewItem:[proxy focusedTabViewItem]];
        [proxy focusTabViewItem:tabViewItem];
        return YES;
    }else if ([command isEqualToString:@"insertBacktab:"]){
        id tabViewItem=[proxy prevTabViewItem:[proxy focusedTabViewItem]];
        [proxy focusTabViewItem:tabViewItem];
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
    id firstTabViewItem=[proxy firstTabViewItem];
    [proxy focusTabViewItem:firstTabViewItem];
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
    
    /*
    id firstResponder=[[NSApp keyWindow]firstResponder];
    if (![firstResponder isKindOfClass:[NSView class]]) {
        return nil;
    }
    NSView* v=firstResponder;
    while (v) {
        if ([[v className]isEqualToString:@"VisualTabPickerRootView"]) {
            return [v valueForKey:@"_visualTabPickerViewController"];
        }
        v=[v superview];
    }*/
    return nil;
}


@end

