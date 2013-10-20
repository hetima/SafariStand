//
//  STSToolbarModule.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import "SafariStand.h"
#import "STSToolbarModule.h"

static STSToolbarModule* toolbarModule;

@implementation STSToolbarModule {
    NSMutableDictionary* _toolbarItemClasses; //key=itemIdentifier, obj=object
    NSMutableArray* _toolbarIdentifiers;
}


//- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag

static id (*orig_TBitemForItemIdentifier)(id, SEL, ...);
static id ST_TBitemForItemIdentifier(id self, SEL _cmd, id toolbar, NSString *itemIdentifier, BOOL real)
{
    
	if([[toolbarModule toolbarIdentifiers]containsObject:itemIdentifier]){
		//return [HTActionButtonController toolBarItemForIdentifier:itemIdentifier];
        return [toolbarModule _toolbar:toolbar itemForItemIdentifier:itemIdentifier willBeInsertedIntoToolbar:real];
        
	}else{
		return orig_TBitemForItemIdentifier(self, _cmd, toolbar, itemIdentifier, real);
	}
	return nil;
}

//- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
static id (*orig_TBallowedItemIdentifiers)(id, SEL, ...);
static id ST_TBallowedItemIdentifiers(id self, SEL _cmd, id toolbar)
{
	NSArray* result=orig_TBallowedItemIdentifiers(self, _cmd, toolbar);
    
    NSArray* myArray=[toolbarModule toolbarIdentifiers];
    if([myArray count]>0)result= [result arrayByAddingObjectsFromArray:myArray];

	return result;
}



- (id)initWithStand:(id)core
{
    self = [super initWithStand:core];
    if (self) {
        //[self observePrefValue:];
        toolbarModule=self;
        _toolbarItemClasses=[[NSMutableDictionary alloc]initWithCapacity:8];
        _toolbarIdentifiers=[[NSMutableArray alloc]initWithCapacity:8];

        id tmpClas=NSClassFromString(@"ToolbarController");
        if(tmpClas){
            orig_TBitemForItemIdentifier=(id(*)(id, SEL, ...))RMF(tmpClas,
                            @selector(toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:), ST_TBitemForItemIdentifier);
            
            orig_TBallowedItemIdentifiers=(id(*)(id, SEL, ...))RMF(tmpClas,
                            @selector(toolbarAllowedItemIdentifiers:), ST_TBallowedItemIdentifiers);
        }

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

-(void)modulesDidFinishLoading:(id)core
{
    //check exists window
    NSDictionary* toolbarConfig=[[NSUserDefaults standardUserDefaults]dictionaryForKey:@"NSToolbar Configuration BrowserToolbarIdentifier"];
    NSArray* identifiers=[toolbarConfig objectForKey:@"TB Item Identifiers"];
    BOOL shouldReload=NO;
    for (NSString* identifier in identifiers) {
        if ([identifier hasPrefix:@"com.hetima."]) {
            shouldReload=YES;
            break;
        }
    }
    if (!shouldReload) {
        return;
    }
    
    NSArray *windows=[NSApp windows];
    for (NSWindow* win in windows) {
        id winCtl=[win windowController];
        if([win isVisible] && [[winCtl className]isEqualToString:kSafariBrowserWindowController])
        {
            NSToolbar* tb=[win toolbar];
            if ([tb isVisible])
            {
                [tb setConfigurationFromDictionary:toolbarConfig];
            }
        }
    }
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

@end


