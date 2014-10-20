//
//  STQuickSearchModule.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

/*
defaults delete com.apple.Safari Stand_QuerySeeds 
 */

#import "SafariStand.h"
#import "STSafariConnect.h"
#import "STQuickSearchModule.h"
#import "STPrefWindowModule.h"
#import "HTQuerySeedEditViewCtl.h"


STQuickSearchModule* quickSearchModule;

@implementation STQuickSearchModule {
    HTQuerySeedEditViewCtl* _querySeedEditViewCtl;
    HTQuerySeed* _googleQuerySeed;
    HTQuerySeed* _googleImageQuerySeed;
}


+ (STQuickSearchModule *)si
{    
    return quickSearchModule;
}


+(int)tabPolicy{
    NSInteger setting=[[NSUserDefaults standardUserDefaults]integerForKey:kpQuickSearchTabPolicy];
    
    switch (setting) {
        case kQuickSearchTabPolicyFront:
            return poNewTab;
            break;
        case kQuickSearchTabPolicyBack:
            return poNewTab_back;
            break;
            
        default:
            return STSafariWindowPolicyNewTab();
            break;
    }
}


- (id)initWithStand:(id)core
{
    self = [super initWithStand:core];
    if (self) {
        quickSearchModule=self;
        //[self observePrefValue:];
        //init querySeeds
        NSMutableArray* qss=[[NSMutableArray alloc]initWithCapacity:8];
        self.querySeeds=qss;


        // ttp
        KZRMETHOD_SWIZZLING_WITHBLOCK
        (
         "NSString", "bestURLForUserTypedString",
         KZRMethodInspection, call, sel,
         ^id (id slf)
        {
             if([slf hasPrefix:@"ttp://"]){
                 return [NSURL URLWithString:[@"h" stringByAppendingString:slf]];
             }
             id result=call.as_id(slf, sel);
             return result;
         });

        
        NSDictionary* dict=[NSDictionary dictionaryWithObjectsAndKeys:
                            @"Google",@"title",
                            @"http://www.google.com/search?client=safari&rls=en&q=%s&ie=UTF-8&oe=UTF-8",@"baseUrl",
                            @"",@"shortcut",
                            @"GET",@"method",
                            //[NSNumber numberWithBool:NO],@"use",
                            [NSNumber numberWithUnsignedInteger:NSUTF8StringEncoding],@"encoding",
                            //[NSString HTUUIDStringWithFormat:@"%@"],@"uuid",
                            nil];
        _googleQuerySeed=[[HTQuerySeed alloc]initWithDict:dict];
        
        dict=[NSDictionary dictionaryWithObjectsAndKeys:
                            @"GoogleImage",@"title",
                            @"http://www.google.com/searchbyimage?image_url=%s",@"baseUrl",
                            @"",@"shortcut",
                            @"GET",@"method",
                            //[NSNumber numberWithBool:NO],@"use",
                            [NSNumber numberWithUnsignedInteger:NSUTF8StringEncoding],@"encoding",
                            //[NSString HTUUIDStringWithFormat:@"%@"],@"uuid",
                            nil];
        _googleImageQuerySeed=[[HTQuerySeed alloc]initWithDict:dict];
        
        
        [self loadFromStorage];

        //temp off
        [self setupCompletionCtl];
        
        //Stand Search Menu
        NSMenuItem* silMenuItem=[[NSMenuItem alloc]initWithTitle:@"Stand Search" action:@selector(showStandSearchWindow:) keyEquivalent:@""];
        [core addItemToStandMenu:silMenuItem];

        //Search It Later Menu
        silMenuItem=[[NSMenuItem alloc]initWithTitle:@"Search It Later" action:@selector(showSearchItLaterWindow:) keyEquivalent:@""];
        [core addItemToStandMenu:silMenuItem];

        [core registerToolbarIdentifier:STQSToolbarIdentifier module:self];

    }
    return self;
}


- (void)modulesDidFinishLoading:(id)core
{
    
}


- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem* result=nil;
    if ([itemIdentifier isEqualToString:STQSToolbarIdentifier]) {
        return [self quickSearchToolbarItemWillBeInsertedIntoToolbar:flag];
        
    }
    return result;
}


- (void)dealloc
{

}


- (void)applicationWillTerminate:(STCSafariStandCore*)core
{
    [self saveToStorage];
}


- (void)prefValue:(NSString*)key changed:(id)value
{
    //if([key isEqualToString:])
}


- (void)stMessagePrefWindowLoaded:(STPrefWindowModule*)sender
{
    _querySeedEditViewCtl=[[HTQuerySeedEditViewCtl alloc]initWithNibName:@"HTQuerySeedEditViewCtl"
                            bundle:[NSBundle bundleWithIdentifier:kSafariStandBundleID]];

    _querySeedEditViewCtl.querySeedsBinder=self;
    NSView* sqView=[_querySeedEditViewCtl view];
    
    [_querySeedEditViewCtl setupAddPopup:self.defaultQuerySeeds];
    
    //STPrefSearch
    NSString* imgPath=[[NSBundle bundleWithIdentifier:kSafariStandBundleID]pathForImageResource:@"STPrefSearch"];
    NSImage* img=[[NSImage alloc]initWithContentsOfFile:imgPath];
    [sender addPane:sqView withIdentifier:@"querySeedEdit" title:@"QuickSearch" icon:img];

}


- (void)stMessagePrefWindowWillClose:(id)prefWindowCtl
{
    [self saveToStorage];
}


- (void)addQuerySeed:(HTQuerySeed*)qs
{
    [self.querySeeds addObject:qs];
}




//botu
- (void)showSearchComplViewForLocationFieldEditor:(id)textView
{

}

#pragma mark -
#pragma mark action

- (void)actQuickSearchMenu:(id)sender
{
    HTQuerySeed* seed=[sender representedObject];
    NSPasteboard* pb=[NSPasteboard pasteboardWithName:kSafariStandPBKey];
    NSString* selectedText=[pb stringForType:NSStringPboardType];
    if(seed && selectedText){
        [self sendQuerySeed:seed withSearchString:selectedText  policy:[STQuickSearchModule tabPolicy]];
    }
}


#pragma mark -

- (NSMenu*)standardQuickSearchMenuWithSearchString:(NSString*)searchString
{
    if ([searchString length]) {

        NSPasteboard* qspb=[NSPasteboard pasteboardWithName:kSafariStandPBKey];
        [qspb clearContents];
        [qspb setString:searchString forType:NSStringPboardType];
        
        NSMenu* menu=[[NSMenu alloc]initWithTitle:@""];
        [self insertQuickSearchMenuItemsToMenu:menu withSelector:@selector(actQuickSearchMenu:) target:self onTop:YES];
        return menu;
    }
    
    return nil;
}

- (NSInteger)insertQuickSearchMenuItemsToMenu:(NSMenu*)menu withSelector:(SEL)sel target:(id)target onTop:(BOOL)onTop
{

    if (!menu) {
        return 0;
    }
    
    BOOL grouping=[[NSUserDefaults standardUserDefaults]boolForKey:kpQuickSearchMenuGroupingEnabled];
    NSInteger idx, insertedCount=0;
    if(onTop)idx=0;
    else idx=[menu numberOfItems];

    for (HTQuerySeed* one in self.querySeeds) {
        if([one.use boolValue] && [one.title length]>0){
            NSString* keyEq=one.shortcut;
            if(!keyEq||[keyEq length]!=1)keyEq=@"";
            NSMenuItem* itm=[[NSMenuItem alloc]initWithTitle:one.title action:sel keyEquivalent:keyEq];
            [itm setKeyEquivalentModifierMask:0];
            [itm setTarget:target];
            [itm setRepresentedObject:one];

            if (grouping) {
                NSArray* dividedTitle=[one.title componentsSeparatedByString:@"#"];
                if ([dividedTitle count]==2 && [[dividedTitle firstObject]length]>0 && [[dividedTitle lastObject]length]>0) {
                    [itm setTitle:[dividedTitle firstObject]];
                    NSString* group=[dividedTitle lastObject];
                    NSMenu* groupMenu=[[menu itemWithTitle:group]submenu];
                    if (!groupMenu) {
                        NSMenuItem* groupMenuItem=[[NSMenuItem alloc]initWithTitle:group action:nil keyEquivalent:@""];
                        groupMenu=[[NSMenu alloc]initWithTitle:group];
                        [groupMenuItem setSubmenu:groupMenu];
                        [menu insertItem:groupMenuItem atIndex:idx];
                        ++idx;
                        ++insertedCount;
                    }
                    [groupMenu addItem:itm];
                    itm=nil;
                }
            }

            if (itm) {
                [menu insertItem:itm atIndex:idx];
                ++idx;
                ++insertedCount;
            }
        }
    }
    
    if(insertedCount==0){
        HTQuerySeed* one=_googleQuerySeed;
        NSMenuItem* itm=[[NSMenuItem alloc]initWithTitle:one.title action:sel keyEquivalent:@""];
        [itm setKeyEquivalentModifierMask:0];
        [itm setTarget:target];
        [itm setRepresentedObject:one];
        [menu insertItem:itm atIndex:idx];
        ++insertedCount;
    }
    
    return insertedCount;
}


- (void)setupContextMenu:(NSMenu*)menu forceBottom:(BOOL)forceBottom
{
    BOOL flat=NO;
    BOOL onTop=YES;
    NSInteger idx;
    
    if(![[NSUserDefaults standardUserDefaults]boolForKey:kpQuickSearchMenuEnabled]){
        return;
    }
    
    if([[NSUserDefaults standardUserDefaults]integerForKey:kpQuickSearchMenuPlace]>0)onTop=NO;
    if([[NSUserDefaults standardUserDefaults]integerForKey:kpQuickSearchMenuIsFlat]>0)flat=YES;
    
    if (forceBottom) {
        onTop=NO;
    }
    
    if(onTop){
        idx=0;
    }else{
        idx=[menu numberOfItems];
        [menu insertItem:[NSMenuItem separatorItem] atIndex:idx];
        ++idx;
    }

    if(!flat){
        NSMenuItem* itm=[[NSMenuItem alloc]initWithTitle:@"Quick Search" action:nil keyEquivalent:@""];
        NSMenu* subMenu=[[NSMenu alloc]initWithTitle:@"Quick Search"];
        [itm setSubmenu:subMenu];
        [menu insertItem:itm atIndex:idx];
        [itm setState:NSOffState];
        idx=0;
        menu=subMenu;
    }
    
    NSInteger insertedCount=[self insertQuickSearchMenuItemsToMenu:menu withSelector:@selector(actQuickSearchMenu:) target:self onTop:onTop];
    idx+=insertedCount;
    
    //search it later
    if(insertedCount>0){
        [menu insertItem:[NSMenuItem separatorItem] atIndex:idx];
        ++idx;
    }
    
    NSMenuItem* itm=[[NSMenuItem alloc]initWithTitle:@"Search It Later" action:@selector(actAddSearchItLaterMenu:) keyEquivalent:@""];
    [itm setTarget:self];
    [menu insertItem:itm atIndex:idx];

}


- (HTQuerySeed*)querySeedForShortcut:(NSString*)inStr
{    
    for (HTQuerySeed* seed in self.querySeeds) {
        NSString* key=seed.shortcut;
        if(key && [key length] && [key isEqualToString:inStr])return seed;
    }
    return nil;
}


- (HTQuerySeed*)querySeedForUUID:(NSString*)uuid
{
    for (HTQuerySeed* seed in self.querySeeds) {
        if([seed.uuid isEqualToString:uuid])return seed;
    }
    return nil;
}


- (void)sendQuerySeed:(HTQuerySeed*)inSeed withSearchString:(NSString*)inStr  policy:(int)policy
{
    NSURLRequest* req=[inSeed requestWithSearchString:inStr];
    STSafariAddSearchStringHistory(inStr);
    STSafariGoToRequestWithPolicy(req, policy);
}


- (void)sendQuerySeedUUID:(NSString*)uuid withSearchString:(NSString*)inStr  policy:(int)policy
{
    HTQuerySeed* inSeed=[self querySeedForUUID:uuid];
    [self sendQuerySeed:inSeed withSearchString:inStr policy:policy];
}

- (void)sendGoogleQuerySeedWithSearchString:(NSString*)inStr  policy:(int)policy
{
    NSURLRequest* req=[_googleQuerySeed requestWithSearchString:inStr];
    STSafariAddSearchStringHistory(inStr);
    STSafariGoToRequestWithPolicy(req, policy);
}


- (void)sendGoogleQuerySeedWithoutAddHistoryWithSearchString:(NSString*)inStr  policy:(int)policy
{
    NSURLRequest* req=[_googleQuerySeed requestWithSearchString:inStr];
    STSafariGoToRequestWithPolicy(req, policy);
}


- (void)sendGoogleImageQuerySeedWithoutAddHistoryWithSearchString:(NSString*)inStr  policy:(int)policy
{
    if (![inStr hasPrefix:@"http"]) {
        return;
    }
    NSURLRequest* req=[_googleImageQuerySeed requestWithSearchString:inStr];
    STSafariGoToRequestWithPolicy(req, policy);
}


- (void)sendDefaultQuerySeedWithSearchString:(NSString*)inStr  policy:(int)policy
{
    HTQuerySeed* defaultSeed=[self querySeedForShortcut:kDefaultSeedShortcut];
    if (!defaultSeed) {
        defaultSeed=_googleQuerySeed;
    }
    [self sendQuerySeed:defaultSeed withSearchString:inStr  policy:policy];
    
}

@end



@implementation STQuickSearchModule (DataIo)

- (NSArray*)enabledQuerySeeds
{
    return [self.querySeeds filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"use=true"]];
}


- (void)loadFromStorage
{
    //querySeeds
    id data=[[STCSafariStandCore si]objectForKey:kpQuerySeeds];
    if(data){
        [self loadQuerySeedDictionaries:data];
    }
    
    //old QuickSearch
    [self importOldSetting];
    //default
    [self importDefaultSetting];
    
    //searchItLaterStrings
    NSArray* savedArray=[[STCSafariStandCore si]objectForKey:kpSearchItLaterStrings];
    [self loadSearchItLaterStringDictionaries:savedArray];
}


- (void)saveToStorage
{
    id data=[self querySeedsRawData];
    if(data)[[STCSafariStandCore si]setObject:data forKey:kpQuerySeeds];
    
    data=self.searchItLaterStrings;
    if(data)[[STCSafariStandCore si]setObject:data forKey:kpSearchItLaterStrings];
    
    [[STCSafariStandCore si]synchronize];
}

- (id)querySeedsRawData
{
    NSMutableArray* ary=[NSMutableArray arrayWithCapacity:[self.querySeeds count]];
    for (HTQuerySeed* qs in self.querySeeds) {
        id data=[qs dictionaryData];
        if (data) {
            [ary addObject:data];
        }
    }
    return ary;
}

- (void)loadSearchItLaterStringDictionaries:(NSArray*)ary
{
    NSMutableArray* sil=[[NSMutableArray alloc]initWithCapacity:[ary count]+4];
    for (NSDictionary* data in ary) {
        NSMutableDictionary* qs=[[NSMutableDictionary alloc]initWithDictionary:data];
        if (qs) {
            [sil addObject:qs];
        }
    }
    self.searchItLaterStrings=sil;

}


- (void)loadQuerySeedDictionaries:(NSArray*)ary
{
    NSMutableArray* qss=[[NSMutableArray alloc]initWithCapacity:[ary count]+4];
    for (NSDictionary* data in ary) {
        HTQuerySeed* qs=[[HTQuerySeed alloc]initWithDict:data];
        if (qs) {
            [qss addObject:qs];
        }
    }
    self.querySeeds=qss;

}


- (void)importOldSetting
{
    if([[STCSafariStandCore si]boolForKey:kpQuickSearchOldSettingImported]) return;
    
    [[STCSafariStandCore si]setBool:YES forKey:kpQuickSearchOldSettingImported];
    
    id ary = (__bridge id)CFPreferencesCopyAppValue( (CFStringRef)@"Hetima_QuickSearchDict", (CFStringRef)@"jp.hetima.SafariStand");
    if(ary && (CFGetTypeID((__bridge CFTypeRef)(ary)) == CFArrayGetTypeID()) ){
        for (NSDictionary* one in ary) {
            NSString* title=[one objectForKey:@"title"];
            NSString* baseUrl=[one objectForKey:@"url"];
            NSString* shortcut=[one objectForKey:@"shortcut"];
            NSNumber* use=[one objectForKey:@"state"];
            NSNumber* encoding=[one objectForKey:@"encode"];
            if(!baseUrl||[baseUrl length]<=0)continue;
            baseUrl=[baseUrl stringByReplacingOccurrencesOfString:@"@key" withString:@"%s"];
            if(!title)title=@"imported";
            if(!shortcut)shortcut=@"";
            if(!use)use=[NSNumber numberWithBool:NO];
            if(!encoding)encoding=[NSNumber numberWithUnsignedInteger:NSUTF8StringEncoding];
            NSDictionary* dict=[NSDictionary dictionaryWithObjectsAndKeys:
                                title,@"title",
                                baseUrl,@"baseUrl",
                                shortcut,@"shortcut",
                                @"GET",@"method",
                                use,@"use",
                                encoding,@"encoding",
                                
                                [NSString HTUUIDStringWithFormat:@"%@"],@"uuid",
                                nil];
            
            HTQuerySeed* qs=[[HTQuerySeed alloc]initWithDict:dict];
            if(qs){
                [self addQuerySeed:qs];
            }
        }
    }
    
    id data=[self querySeedsRawData];
    if(data)[[STCSafariStandCore si]setObject:data forKey:kpQuerySeeds];
    [[STCSafariStandCore si]synchronize];
    
}


- (void)importDefaultSetting
{
    NSBundle* b=[NSBundle bundleForClass:[self class]];
    NSString* plst=[b pathForResource:@"quicksearch_defaults" ofType:@"plist"];
    NSArray* qs=[[NSDictionary dictionaryWithContentsOfFile:plst]objectForKey:kpQuerySeeds];
    self.defaultQuerySeeds=qs;
}


@end
