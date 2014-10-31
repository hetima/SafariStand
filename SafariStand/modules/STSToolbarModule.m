//
//  STSToolbarModule.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import "SafariStand.h"
#import "STSToolbarModule.h"

#define kpBrowserToolbarIdentifier @"NSToolbar Configuration BrowserToolbarIdentifier-v2"


static STSToolbarModule* toolbarModule;

@implementation STSToolbarModule {
    NSMutableDictionary* _toolbarItemClasses; //key=itemIdentifier, obj=object
    NSMutableArray* _toolbarIdentifiers;
}

- (id)initWithStand:(id)core
{
    self = [super initWithStand:core];
    if (self) {
        //[self observePrefValue:];
        toolbarModule=self;
        _toolbarItemClasses=[[NSMutableDictionary alloc]initWithCapacity:8];
        _toolbarIdentifiers=[[NSMutableArray alloc]initWithCapacity:8];

        
        //- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
        KZRMETHOD_SWIZZLING_
        (
         "ToolbarController",
         "toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:",
         id, call, sel)
         ^id (id slf, id toolbar, NSString *itemIdentifier, BOOL real){
             if([[toolbarModule toolbarIdentifiers]containsObject:itemIdentifier]){
                 return [toolbarModule _toolbar:toolbar itemForItemIdentifier:itemIdentifier willBeInsertedIntoToolbar:real];
             }else{
                 id result=call(slf, sel, toolbar, itemIdentifier, real);
                 if ([[NSUserDefaults standardUserDefaults]boolForKey:kpExpandAddressBarWidthEnabled]
                     && [itemIdentifier isEqualToString:@"InputFieldsToolbarIdentifier"]) {
                     [self expandInputFieldsToolbar:result];
                 }
                 return result;
             }
             return nil;
         }_WITHBLOCK;
        
        //- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
        KZRMETHOD_SWIZZLING_
        (
         "ToolbarController",
         "toolbarAllowedItemIdentifiers:",
         id, call, sel)
         ^id (id slf, id toolbar){
             NSArray* result=call(slf, sel, toolbar);
             
             NSArray* myArray=[toolbarModule toolbarIdentifiers];
             if([myArray count]>0)result=[[result arrayByAddingObjectsFromArray:myArray]arrayByAddingObject:NSToolbarSpaceItemIdentifier];
             
             return result;
         }_WITHBLOCK;
        
        [self observePrefValue:kpExpandAddressBarWidthEnabled];
        [self observePrefValue:kpExpandAddressBarWidthValue];

    }
    return self;
}


- (void)dealloc
{

}


- (void)prefValue:(NSString*)key changed:(id)value
{
    if([key isEqualToString:kpBrowserToolbarIdentifier]){
        if(value)[[STCSafariStandCore si]setObject:value forKey:kpBrowserToolbarConfigurationBackup];
        [[STCSafariStandCore si]synchronize];
    }else if([key isEqualToString:kpExpandAddressBarWidthEnabled]||[key isEqualToString:kpExpandAddressBarWidthValue]){
        [self layoutAddressBarForExistingWindow];
    }

}

-(void)modulesDidFinishLoading:(id)core
{
    NSDictionary* toolbarConfig=[[NSUserDefaults standardUserDefaults]dictionaryForKey:kpBrowserToolbarIdentifier];
    toolbarConfig=[[STCSafariStandCore si]objectForKey:kpBrowserToolbarConfigurationBackup];
    NSArray* identifiers=[toolbarConfig objectForKey:@"TB Item Identifiers"];
    
    BOOL shouldReload=NO;
    for (NSString* identifier in identifiers) {
        if ([identifier hasPrefix:@"com.hetima."]) {
            shouldReload=YES;
            break;
        }
    }
    
    if (shouldReload) {
        STSafariEnumerateBrowserWindow(^(NSWindow* win, NSWindowController* winCtl, BOOL* stop){
            if ([win isVisible]) {
                NSToolbar* tb=[win toolbar];
                if (tb) {
                    [tb setConfigurationFromDictionary:toolbarConfig];
                    *stop=YES;
                }
            }
        });
    }
    
    if ([[NSUserDefaults standardUserDefaults]boolForKey:kpExpandAddressBarWidthEnabled]){
        [self layoutAddressBarForExistingWindow];
    }

    [self observePrefValue:kpBrowserToolbarIdentifier];
}


- (NSToolbarItem *)_toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    id deleg=[_toolbarItemClasses objectForKey:itemIdentifier];
    if(deleg){
        return [deleg toolbar:toolbar itemForItemIdentifier:itemIdentifier willBeInsertedIntoToolbar:flag];
    }
    return nil;
}

-(NSArray*)toolbarIdentifiers
{
    return _toolbarIdentifiers;
}

-(void)registerToolbarIdentifier:(NSString*)identifier module:(id)obj
{
    if(![obj respondsToSelector:@selector(toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:)])return;
    [_toolbarItemClasses setObject:obj forKey:identifier];
    [_toolbarIdentifiers addObject:identifier];
}



-(id)simpleToolBarItem:(NSString*)identifier label:(NSString*)label action:(SEL)action iconImage:(NSImage*)iconImage
{
    
	//NSSegmentedControl
	NSButton*	btn=[[NSButton alloc]initWithFrame:NSMakeRect(0,0, 28, 25)];

	[btn setAutoresizingMask:NSViewNotSizable];
    [btn setImagePosition:NSImageOnly];
    [btn setBezelStyle:NSTexturedRoundedBezelStyle];
    [btn setBordered:YES];
    
	if(iconImage)[btn setImage:iconImage];
	
	[btn setEnabled:YES];
	[btn setAction:action];
	
	NSToolbarItem*	result=[self toolBarItem:identifier label:label view:btn];

    return result;
}

-(id)toolBarItem:(NSString*)identifier label:(NSString*)label view:(NSView*)view
{
	NSToolbarItem*	result=[[NSToolbarItem alloc] initWithItemIdentifier:identifier];
    NSSize frameSize=[view frame].size;
	[result setView:view];
	[result setMinSize:frameSize];
	[result setMaxSize:frameSize];
	[result setLabel:label];
	[result setPaletteLabel:label];
	
	return result;
}

#pragma mark - ExpandAddressBarWidth

#define kPreferredWidthRatioDefault 0.41
- (void)expandInputFieldsToolbar:(NSToolbarItem*)item
{
    if ([[NSUserDefaults standardUserDefaults]boolForKey:kpExpandAddressBarWidthEnabled]){
        CGFloat factor=[[NSUserDefaults standardUserDefaults]floatForKey:kpExpandAddressBarWidthValue];
        if (factor<kPreferredWidthRatioDefault) {
            factor=kPreferredWidthRatioDefault;
        }else if (factor>1.0){
            factor=1.0;
        }
        [self expandInputFieldsToolbar:item factor:factor];
    }else{
        //reset
        [self expandInputFieldsToolbar:item factor:kPreferredWidthRatioDefault];
    }
}


- (void)expandInputFieldsToolbar:(NSToolbarItem*)item factor:(CGFloat)factor
{
    if ([item respondsToSelector:@selector(setPreferredWidthRatio:)]) {
        objc_msgSend(item, @selector(setPreferredWidthRatio:), factor);
    }
}


-(void)layoutAddressBarForExistingWindow
{
    //check exists window
    STSafariEnumerateBrowserWindow(^(NSWindow* win, NSWindowController* winCtl, BOOL* stop){
        if([win isVisible]){
            NSToolbar* tb=[win toolbar];
            if (tb) {
                NSArray* items=[tb items];
                for (NSToolbarItem* itm in items) {
                    if([[itm itemIdentifier]isEqualToString:@"InputFieldsToolbarIdentifier"]){
                        [self expandInputFieldsToolbar:itm];
                    }
                }
            }
        }
    });
}

@end


