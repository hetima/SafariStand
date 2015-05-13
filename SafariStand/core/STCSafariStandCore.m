//
//  STCSafariStandCore.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif


#import "SafariStand.h"
#import <WebKit/WebKit.h>
#import "STTabProxyController.h"
#import "STWKClientHook.h"
#import "STCUserDefaultsController.h"

@implementation STCSafariStandCore {
    BOOL _startup;
    NSMutableDictionary* _modules;
    
}

static STCSafariStandCore *sharedInstance;

+ (STCSafariStandCore *)si
{

    if (sharedInstance == nil){
        sharedInstance = [[STCSafariStandCore alloc]init];
        [sharedInstance startup];
    }
    
    return sharedInstance;
}


+ (id)mi:(NSString*)moduleClassName
{
    return [[STCSafariStandCore si]moduleForClassName:moduleClassName];
}


+ (NSString *)standLibraryPath:(NSString*)subPath
{
    NSString* path=[NSHomeDirectory() stringByStandardizingPath];
    path=[path stringByAppendingPathComponent:@"Library/Safari/Stand"];
    if (![[NSFileManager defaultManager]fileExistsAtPath:path]) {
        [[NSFileManager defaultManager]createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    if (!subPath) {
        return path;
    }
    
    path=[path stringByAppendingPathComponent:subPath];
    if (![[NSFileManager defaultManager]fileExistsAtPath:path]) {
        [[NSFileManager defaultManager]createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return path;
}


+ (NSUserDefaults *)ud
{
    return [[STCSafariStandCore si]userDefaults];
}


- (id)init
{
    self = [super init];
    if (!self) return nil;
    
    
    _startup=NO;
    _missMatchAlertShown=NO;
    _userDefaults=[[STCUserDefaults alloc]initWithSuiteName:kSafariStandPrefDomain];
    
    
    return self;
}


- (void)registerBuiltInModules
{
#define registerAndAddOrder(name) module=[self registerModule:name];if(module)[orderedModule addObject:module];
    
    id module;
    NSMutableArray* orderedModule=[[NSMutableArray alloc]initWithCapacity:16];
    registerAndAddOrder(@"STSToolbarModule");
    registerAndAddOrder(@"STPrefWindowModule");
    registerAndAddOrder(@"STConsolePanelModule");

    registerAndAddOrder(@"STSContextMenuModule"); //STQuickSearchModule
    registerAndAddOrder(@"STQuickSearchModule"); //STPrefWindowModule
    registerAndAddOrder(@"STBookmarkSeparator");
    registerAndAddOrder(@"STActionMessageModule");

    registerAndAddOrder(@"STSTabBarModule");

    registerAndAddOrder(@"STSTitleBarModule");
    registerAndAddOrder(@"STSDownloadModule");
    
    
    registerAndAddOrder(@"STActionMenuModule"); //must after STSToolbarModule
    registerAndAddOrder(@"STSidebarModule");
    registerAndAddOrder(@"STKeyHandlerModule");
    registerAndAddOrder(@"STTabPickerModule");
    registerAndAddOrder(@"STSelfUpdaterModule");

#undef registerAndAddOrder
    
    for (id module in orderedModule) {
        if ([module respondsToSelector:@selector(modulesDidFinishLoading:)]) {
            [module modulesDidFinishLoading:self];
        }
    }
}


- (void)startup
{
    if(_startup)return;    
    _startup=YES;
    
    NSString* vstr=[[NSBundle bundleWithIdentifier:kSafariStandBundleID]objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey];
    self.currentVersionString=vstr;
    self.latestVersionString=@"-";
    
    NSString* shortVersionString=[[NSBundle mainBundle]objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString* revision=[shortVersionString stand_revisionFromVersionString];
    if (!revision) {
        revision=@"-";
    }
    _safariRevision=revision;
    
    /*
    NSString* systemVersion=@"10.10";
    if(floor(NSAppKitVersionNumber)==NSAppKitVersionNumber10_9){
        systemVersion=@"10.9";
    }
    */
    LOG(@"Startup.... %@", revision);
    
    [self migrateSetting];
    
    NSDictionary* dic=[NSDictionary dictionaryWithObjectsAndKeys:
                       [NSNumber numberWithBool:YES], kpQuickSearchMenuEnabled,
                       [NSNumber numberWithDouble:250.0], kpSuppressTabBarWidthValue,
                       [NSNumber numberWithBool:YES], kpEnhanceVisualTabPicker,
                       //@"-", kpCheckedLatestVariosn,
                       nil];
    [self.userDefaults registerDefaults:dic];
    
	//アプリ終了をobserve
	[[NSNotificationCenter defaultCenter]addObserver:self
                        selector:@selector(noteAppWillTerminate:)
                        name:NSApplicationWillTerminateNotification object:NSApp];


    [self setupStandMenu];
    
    [STTabProxyController si];
    STWKClientHook();

    [self registerBuiltInModules];

    
}


//保存のタイミング
- (void)noteAppWillTerminate:(NSNotification*)notification
{
    [self sendMessage:@selector(applicationWillTerminate:) toAllModule:self];
    
    [self.userDefaults synchronize];
}


- (id)registerModule:(NSString*)aClassName
{
    id aIns=nil;
    if(_modules==nil){
        _modules=[[NSMutableDictionary alloc]initWithCapacity:16];
    }
    Class aClass=NSClassFromString(aClassName);
    if([aClass instancesRespondToSelector:@selector(initWithStand:)] && [aClass respondsToSelector:@selector(canRegisterModule)]){
        if ([aClass canRegisterModule]) {
            aIns=[[aClass alloc]initWithStand:self];
            if(aIns)[_modules setObject:aIns forKey:aClassName];
        }else{
            NSLog(@"SafariStand:%@ was not loaded because of canRegisterModule==NO.", aClassName);
        }
    }
    return aIns;
}


- (id)moduleForClassName:(NSString*)name
{
    return [_modules objectForKey:name];
}


- (void)sendMessage:(SEL)selector toAllModule:(id)sender
{
    NSEnumerator *enumerator = [_modules objectEnumerator];
    for (id plgin in enumerator) {
        if([plgin respondsToSelector:selector]){
            objc_msgSend(plgin, selector, sender);
        }
    }
}


- (void)addItemToStandMenu:(NSMenuItem*)itm
{

    NSInteger idx=[self.standMenu indexOfItemWithTag:909];
    [self.standMenu insertItem:itm atIndex:idx];
}


- (void)setupStandMenu
{
    _standMenu=[[NSMenu alloc]initWithTitle:@"Stand"];
	NSMenu*	mainMenuBar=[NSApp mainMenu];
    NSMenuItem *myMenuItem=[[NSMenuItem alloc]initWithTitle:@"Stand" action:NULL keyEquivalent:@""];
	if(mainMenuBar && myMenuItem){

        [_standMenu setTitle:@"Stand"];
        [myMenuItem setSubmenu:_standMenu];


        NSMenuItem* m=[_standMenu addItemWithTitle:@"Anchor" action:nil keyEquivalent:@""];
        [m setTag:909];
        [m setHidden:YES];
        
        NSInteger menuCount=8;
        if([mainMenuBar numberOfItems]<8) menuCount=[mainMenuBar numberOfItems];
        [mainMenuBar insertItem:myMenuItem atIndex:menuCount];
         
    }
}


#pragma mark -

- (void)openWebSite
{

}


- (void)showMissMatchAlert
{
    if (self.missMatchAlertShown) {
        return;
    }
    self.missMatchAlertShown=YES;
    [self performSelector:@selector(showMissMatchAlertM) onThread:[NSThread mainThread] withObject:nil waitUntilDone:NO];

}


- (void)showMissMatchAlertM
{
    NSString* messageTitle=LOCALIZE(@"Miss Match Title");
    NSString* info=LOCALIZE(@"Miss Match Info");
    
    messageTitle=[NSString stringWithFormat:messageTitle, self.currentVersionString];
    NSAlert* alert=[[NSAlert alloc]init];
    alert.messageText=messageTitle;
    alert.informativeText=info;
    [alert addButtonWithTitle:@"OK"]; //1000
    [alert addButtonWithTitle:@"Visit SafariStand web site"]; //1001
    

    NSModalResponse returnCode=[alert runModal];
    if (returnCode==1001) {
        [self openWebSite];
    }

}


- (void)missMatchAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    //ok=1, visit=0
    [[alert window]orderOut:nil];
    if (returnCode==0) {
        [self openWebSite];
    }
}



- (void)migrateSetting
{
    if ([[NSUserDefaults standardUserDefaults]boolForKey:kpSettingMigratedV1]) {
        return;
    }
    if ([self.userDefaults boolForKey:kpSettingMigratedV1]) {
        return;
    }
    
    NSArray* keys=@[kpActionMessageEnabled,
                    kpQuickSearchMenuEnabled,
                    kpQuickSearchMenuPlace,
                    kpQuickSearchMenuIsFlat,
                    kpQuickSearchTabPolicy,
                    kpQuickSearchMenuGroupingEnabled,
                    kpSwitchTabWithWheelEnabled,
                    kpSwitchTabWithOneKeyEnabled,
                    kpShowCopyLinkTagContextMenu,
                    kpCopyLinkTagAddTargetBlank,
                    kpShowCopyLinkAndTitleContextMenu,
                    kpShowCopyLinkTitleContextMenu,
                    kpShowClipWebArchiveContextMenu,
                    kpShowGoogleImageSearchContextMenu,
                    kpImprovePathPopupMenu,
                    kpSidebarShowsDefault,
                    kpSidebarIsRightSide,
                    kpSidebarWidth,
                    kpSquashContextMenuItemEnabled,
                    kpSquashContextMenuItemTags,
                    kpClassifyDownloadFolderBasicEnabled,
                    kpDownloadMonitorMovesToConsolePanel,
                    kpSuppressTabBarWidthEnabled,
                    kpSuppressTabBarWidthValue,
                    kpShowIconOnTabBarEnabled,
                    kpExpandAddressBarWidthEnabled,
                    kpExpandAddressBarWidthValue,
                    kpShowIconOnSidebarBookmarkEnabled,
                    kpShowBrowserWindowTitlebar,
                    kpEnhanceVisualTabPicker,
                    kpDontStackVisualTabPicker,
                    kpCtlTabTriggersVisualTabPicker,
                    @"HTFilePresetPopUpButtonCurrentValue_HTWebClipwin",
                    @"HTFilePresetPopUpButtonAllValues_HTWebClipwin"];
    
    for (NSString* key in keys) {
        id val=[[NSUserDefaults standardUserDefaults]objectForKey:key];
        if (val) {
            [self.userDefaults setObject:val forKey:key];
        }
    }
    
    [self.userDefaults setObject:[NSNumber numberWithBool:YES] forKey:kpSettingMigratedV1];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:kpSettingMigratedV1];
    
    NSLog(@"SafariStand setting was migrated (V1)");
    
    [self.userDefaults synchronize];
}


@end


@implementation STCSafariStandCore (STCSafariStandCore_Pref)


- (id)objectForKey:(NSString*)key
{
    id result=(__bridge id)CFPreferencesCopyAppValue((__bridge CFStringRef)key, (CFStringRef)kSafariStandPrefDomain);
    return result;
}


- (BOOL)boolForKey:(NSString*)key
{
	return [self boolForKey:key defaultValue:NO];
}


- (BOOL)boolForKey:(NSString*)key  defaultValue:(BOOL)inValue
{
	BOOL	tempB;
    Boolean isValid;
    tempB=CFPreferencesGetAppBooleanValue((__bridge CFStringRef)key, (CFStringRef)kSafariStandPrefDomain, &isValid);
    
	if(isValid)	return tempB;
	else		return inValue;
}


- (id)mutableObjectForKey:(NSString*)key
{
	return [self makeMutablePlistCopy:[self objectForKey:key]];
}


- (void)setObject:(id)value forKey:(NSString*)key
{
    CFPreferencesSetAppValue( (__bridge CFStringRef) key, (__bridge CFPropertyListRef) value, (CFStringRef)kSafariStandPrefDomain);
}


- (void)setBool:(BOOL)value forKey:(NSString*)key
{
    CFPreferencesSetAppValue((__bridge CFStringRef)key, (CFPropertyListRef)(value ? kCFBooleanTrue : kCFBooleanFalse),
                             (CFStringRef)kSafariStandPrefDomain);
}


- (BOOL)synchronize
{
    return CFPreferencesAppSynchronize((CFStringRef)kSafariStandPrefDomain);
}



- (id)makeMutablePlistCopy:(id)plist
{
	id copyPlist;
	if ([plist isKindOfClass:[NSArray class]]) {
		copyPlist = [self makeMutableArrayCopy:plist];
	}else if ([plist isKindOfClass:[NSDictionary class]]) {
		copyPlist = [self makeMutableDictionaryCopy:plist];
	}else {
		copyPlist = plist;
	}
	return copyPlist;
}


- (NSMutableArray*)makeMutableArrayCopy:(NSArray*)array
{
	id  copy;
	int i;
    
	// Make copy
	copy = [[NSMutableArray alloc] initWithCapacity:[array count]];
    
    
	// Enumerate object
	for (i = 0; i < [array count]; i++) {
		id      object;
        
		object = [array objectAtIndex:i];
		if ([object isKindOfClass:[NSArray class]]) {
			object=[self makeMutableArrayCopy:object];
        }else if ([object isKindOfClass:[NSDictionary class]]) {
			object=[self makeMutableDictionaryCopy:object];
		}
		[copy addObject:object];
	}
    
	return copy;
}


- (NSMutableDictionary*)makeMutableDictionaryCopy:(NSDictionary*)dict
{
	id		copy = [[NSMutableDictionary alloc] initWithCapacity:[dict count]];
	
	// Enumerate object
	NSEnumerator* enumerator = [dict keyEnumerator];
    for (id key in enumerator) {
		id object;
		object = [dict objectForKey:key];
		if ([object isKindOfClass:[NSArray class]]) {
			object=[self makeMutableArrayCopy:object];
        }else if ([object isKindOfClass:[NSDictionary class]]) {
			object=[self makeMutableDictionaryCopy:object];
		}
		[copy setObject:object forKey:key];
	}
    
	return copy;
}


@end
