//
//  STSContextMenuModule.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with -fno-objc-arc
#endif

#import "SafariStand.h"
#import "STSContextMenuModule.h"
#import "STQuickSearchModule.h"
#import <WebKit/WebKit.h>
#import "HTWebKit2Adapter.h"
#import "HTWebClipwinCtl.h"
#import "STFakeJSCommand.h"

#import "STSquashContextMenuSheetCtl.h"

#ifdef DEBUG
//#define DEBUG_MENUDUMP 0
#endif

@implementation STSContextMenuModule

- (void)injectToContextMenuProxy:(void*)menuProxy
{
    
    // menuProxy は WebContextMenuProxyMac クラスのポインタ
    // 16バイト目に NSPopUpButtonCell * へのポインタが格納されている
    void* cellPtr=*((void **)menuProxy + 2);
    NSPopUpButtonCell *cell = (__bridge NSPopUpButtonCell *)(cellPtr);

    // WKView を取得。
    //Safari 7 menuProxy の 24バイト目
    //void* wkviewPtr= *((void **)menuProxy + 3);
    //Safari 8 menuProxy の 32バイト目
    void* wkviewPtr= *((void **)menuProxy + 4);
    id wkview = (__bridge id)(wkviewPtr);
    
    // cell から menu を取得
    // プラグインや機能拡張によって追加されたメニュー項目も含む、画面に表示する直前の状態のメニューが取り出せる
    NSMenu *menu = [cell menu];
    NSMenuItem* itm;
    
    // 既存のメニュー項目をいくつか取得
    NSMenuItem* copyTextItem=[menu itemWithTag:8]; //8 == copy text
    NSMenuItem* copyLinkItem=[menu itemWithTag:3]; //3 == copy link
    NSMenuItem* copyImageItem=[menu itemWithTag:6]; //6 == copy link
    

#ifdef DEBUG_MENUDUMP
    static NSMutableDictionary* tagdic=nil;
    if (tagdic==nil) {
        tagdic=[[NSMutableDictionary alloc]init];
    }
    static NSMutableArray* tagary=nil;
    if (tagary==nil) {
        tagary=[[NSMutableArray alloc]init];
    }

    for (NSMenuItem* itm in [menu itemArray]) {
        if ([itm tag] && [itm title]) {
            NSNumber *tagNum=[NSNumber numberWithInteger:[itm tag]];
            if (![tagdic objectForKey:tagNum]) {
                [tagary addObject:[NSDictionary dictionaryWithObjectsAndKeys:tagNum, @"tag", [itm title], @"title",nil]];
                [tagdic setObject:[itm title] forKey:tagNum];
            }
        }
        NSString* debugTtile=[NSString stringWithFormat:@"%@ (%lu)",[itm title],[itm tag]];
        [itm setTitle:debugTtile];
    }
#endif

    
    //STSDownloadModule  replace Save Image to “Downloads”
	if([[NSUserDefaults standardUserDefaults]boolForKey:kpClassifyDownloadFolderBasicEnabled]){
        NSInteger tag;
        
        //Safari 8
        tag=10011;

        NSMenuItem* itm=[menu itemWithTag:tag];
        id dlModule=[STCSafariStandCore mi:@"STSDownloadModule"];
        if (itm && dlModule) {
            [itm setAction:@selector(actCopyImageToDownloadFolderMenu:)];
            [itm setTarget:dlModule];
#ifdef DEBUG_MENUDUMP
            [itm setTitle:@"actCopyImageToDownloadFolderMenu:"];
#endif
        }
    }
    
    
    // 選択文字列を調べる
    BOOL hasSelectedText=NO;
    if (copyTextItem || copyLinkItem) {
        hasSelectedText=YES;
    }
    
    if (wkview && hasSelectedText) {
        // 適当な名前で NSPasteboard 作成
        NSPasteboard* pb=[NSPasteboard pasteboardWithName:kSafariStandPBKey];
        [pb clearContents];
        
        // 書き込ませる
        //NSStringPboardType is deprecated but WKView doesn't handle NSPasteboardTypeString.
        [wkview writeSelectionToPasteboard:pb types:[NSArray arrayWithObject:NSStringPboardType]];
        NSString* selectedText=[[pb stringForType:NSStringPboardType]stand_moderatedStringWithin:0];

        NSUInteger len=[selectedText length];
        if(len>0 && len<1024){//あんまり長いのは除外
            //LOG(@"%@",[pb stringForType:NSPasteboardTypeString]);
            [[STQuickSearchModule si]setupContextMenu:menu forceBottom:(copyLinkItem ? YES:NO)];
        }
        
        //Clip Web Archive
        if(len>0 && [[NSUserDefaults standardUserDefaults]boolForKey:kpShowClipWebArchiveContextMenu]){
            NSMenuItem* itm;
            itm=[[NSMenuItem alloc]initWithTitle:@"Clip Web Archive with Selection"
                                          action:@selector(actWebArchiveSelectionMenu:) keyEquivalent:@""];
            [itm setTarget:self];
            [itm setRepresentedObject:wkview];
            [menu addItem:itm];
        }
    }

    
    if(copyLinkItem){
        id webUserDataWrapper=[copyLinkItem representedObject];
        void* apiObject=[webUserDataWrapper userData]; //struct APIObject
        uint32_t type=0;
        
        if (apiObject) {
            type=WKGetTypeID(apiObject);
        }

        if(type==WKDictionaryGetTypeID()){
            NSInteger idx=[menu indexOfItem:copyLinkItem];
            if([[NSUserDefaults standardUserDefaults]boolForKey:kpShowCopyLinkTagContextMenu]){
                if([[NSUserDefaults standardUserDefaults]boolForKey:kpCopyLinkTagAddTargetBlank]){
                    itm=[[NSMenuItem alloc]initWithTitle:LOCALIZE(@"Copy Link Tag (_blank)") 
                                                  action:@selector(actCopyLinkTagBlankMenu:) keyEquivalent:@""];
                }else{
                    itm=[[NSMenuItem alloc]initWithTitle:LOCALIZE(@"Copy Link Tag") 
                                                  action:@selector(actCopyLinkTagMenu:) keyEquivalent:@""];
                }
                [itm setTarget:self];
                [itm setRepresentedObject:webUserDataWrapper];
                [menu insertItem:itm atIndex:++idx];

                if([[NSUserDefaults standardUserDefaults]boolForKey:kpCopyLinkTagAddTargetBlank]){
                    itm=[[NSMenuItem alloc]initWithTitle:LOCALIZE(@"Copy Link Tag") 
                                                  action:@selector(actCopyLinkTagMenu:) keyEquivalent:@""];
                }else{
                    itm=[[NSMenuItem alloc]initWithTitle:LOCALIZE(@"Copy Link Tag (_blank)") 
                                                  action:@selector(actCopyLinkTagBlankMenu:) keyEquivalent:@""];
                }
                [itm setTarget:self];
                [itm setRepresentedObject:webUserDataWrapper];
                [itm setKeyEquivalentModifierMask:NSAlternateKeyMask];
                [itm setAlternate:YES];
                [menu insertItem:itm atIndex:++idx];
            }
            
            if([[NSUserDefaults standardUserDefaults]boolForKey:kpShowCopyLinkTitleContextMenu]){
                itm=[[NSMenuItem alloc]initWithTitle:LOCALIZE(@"Copy Link Title") action:@selector(actCopyLinkTitleMenu:) keyEquivalent:@""];
                [itm setTarget:self];
                [itm setRepresentedObject:webUserDataWrapper];
                [menu insertItem:itm atIndex:++idx];
                
            }
            
            if([[NSUserDefaults standardUserDefaults]boolForKey:kpShowCopyLinkAndTitleContextMenu]){
                itm=[[NSMenuItem alloc]initWithTitle:LOCALIZE(@"Copy Link and Title") action:@selector(actCopyLinkAndTitleMenu:) keyEquivalent:@""];
                [itm setTarget:self];
                [itm setRepresentedObject:webUserDataWrapper];
                [menu insertItem:itm atIndex:++idx];
                
                itm=[[NSMenuItem alloc]initWithTitle:LOCALIZE(@"Copy Link (space) Title") action:@selector(actCopyLinkAndTitleSpaceMenu:) keyEquivalent:@""];
                [itm setTarget:self];
                [itm setRepresentedObject:webUserDataWrapper];
                [itm setKeyEquivalentModifierMask:NSAlternateKeyMask];
                [itm setAlternate:YES];
                [menu insertItem:itm atIndex:++idx];
            }

#ifdef DEBUG_MENUDUMP
            // WindowPolicy checker
            NSMenu* windowPolicyTestMenu=[self safariWindowPolicyTestMenuWithUserDataWrapper:webUserDataWrapper];
            itm=[[NSMenuItem alloc]initWithTitle:@"WindowPolicyTest" action:nil keyEquivalent:@""];
            [itm setSubmenu:windowPolicyTestMenu];
            [menu insertItem:itm atIndex:++idx];
#endif
        }
        
        //LOG(@"%ud, %ud, %@,%@",type,WKDataGetTypeID(),[copyLinkItem title], NSStringFromSelector([copyLinkItem action]));
    } //if(copyLinkItem)
    
    
    if(copyImageItem){
        if([[NSUserDefaults standardUserDefaults]boolForKey:kpShowGoogleImageSearchContextMenu]){
            NSInteger idx=[menu indexOfItem:copyImageItem];
            itm=[[NSMenuItem alloc]initWithTitle:LOCALIZE(@"Google Image Search") action:@selector(actImageSearchMenu:) keyEquivalent:@""];
            [itm setTarget:self];
            [itm setRepresentedObject:[copyImageItem representedObject]];
            [menu insertItem:itm atIndex:++idx];
        }
    }
    
    //solo image
    if (wkview && [htMIMETypeForWKView(wkview) hasPrefix:@"image/"]) {
        NSMenu* imagePageSubmenu=[self imagePageSubmenu];
        itm=[[NSMenuItem alloc]initWithTitle:@"Image Display" action:nil keyEquivalent:@""];
        [itm setSubmenu:imagePageSubmenu];
        [menu addItem:itm];
        
    }
    
    //SquashContextMenuItem
    if ([[NSUserDefaults standardUserDefaults]boolForKey:kpSquashContextMenuItemEnabled]) {
        NSArray* disabledItems=[[NSUserDefaults standardUserDefaults]arrayForKey:kpSquashContextMenuItemTags];
        for (NSNumber* tag in disabledItems) {
            NSMenuItem* mi=[menu itemWithTag:[tag intValue]];
            if (mi) {
                [menu removeItem:mi];
            }
        }
        //clean up separator
        BOOL prevIsSeparator=YES;
        NSInteger i;
        for (i=[menu numberOfItems]-1; i>=0; --i) {
            NSMenuItem* mi=[menu itemAtIndex:i];
            if ([mi isSeparatorItem]) {
                if(prevIsSeparator || i==0) [menu removeItemAtIndex:i];
                prevIsSeparator=YES;
            }else {
                prevIsSeparator=NO;
            }
        }
    }

}


-(void)actImageSearchMenu:(id)sender
{
    id webUserDataWrapper=[sender representedObject];
    void* apiObject=[webUserDataWrapper userData]; //struct APIObject
    uint32_t type=WKGetTypeID(apiObject);
    if(type==WKDictionaryGetTypeID()){ //8==TypeDictionary
        NSString* urlStr=htWKDictionaryStringForKey(apiObject, @"ImageURL");
        LOG(@"%@",urlStr);
        [[STQuickSearchModule si]sendGoogleImageQuerySeedWithoutAddHistoryWithSearchString:urlStr policy:[STQuickSearchModule tabPolicy]];
    }
}


-(void)actCopyLinkTagMenu:(id)sender
{
    id webUserDataWrapper=[sender representedObject];
    void* apiObject=[webUserDataWrapper userData]; //struct APIObject
    uint32_t type=WKGetTypeID(apiObject);
    if(type==WKDictionaryGetTypeID()){ //8==TypeDictionary
        NSString* linkStr=htWKDictionaryStringForKey(apiObject, @"LinkURL");
        NSString* titleStr=htWKDictionaryStringForKey(apiObject, @"LinkLabel");//or @"LinkTitle"
        if(!linkStr)linkStr=@"";
        if(!titleStr)titleStr=@"";
        
        NSString* format=LOCALIZE(@"LINKTAG");
        NSString* result=[NSString stringWithFormat:format, linkStr, titleStr];
        
        NSPasteboard*pb=[NSPasteboard generalPasteboard];
        [pb clearContents];
        [pb setString:result forType:NSPasteboardTypeString];
    }
}


-(void)actCopyLinkTagBlankMenu:(id)sender
{
    id webUserDataWrapper=[sender representedObject];
    void* apiObject=[webUserDataWrapper userData]; //struct APIObject
    uint32_t type=WKGetTypeID(apiObject);
    if(type==WKDictionaryGetTypeID()){ //8==TypeDictionary
        NSString* linkStr=htWKDictionaryStringForKey(apiObject, @"LinkURL");
        NSString* titleStr=htWKDictionaryStringForKey(apiObject, @"LinkLabel");//or @"LinkTitle"
        if(!linkStr)linkStr=@"";
        if(!titleStr)titleStr=@"";
        
        NSString* format=LOCALIZE(@"LINKTAGBLANK");
        NSString* result=[NSString stringWithFormat:format, linkStr, titleStr];
        
        NSPasteboard*pb=[NSPasteboard generalPasteboard];
        [pb clearContents];
        [pb setString:result forType:NSPasteboardTypeString];
    }
}


-(void)actCopyLinkTitleMenu:(id)sender
{
    id webUserDataWrapper=[sender representedObject];
    void* apiObject=[webUserDataWrapper userData]; //struct APIObject
    uint32_t type=WKGetTypeID(apiObject);
    if(type==WKDictionaryGetTypeID()){ //8==TypeDictionary

        NSString* titleStr=htWKDictionaryStringForKey(apiObject, @"LinkLabel");//or @"LinkTitle"
        if(!titleStr)titleStr=@"";
        
        NSPasteboard*pb=[NSPasteboard generalPasteboard];
        [pb clearContents];
        [pb setString:titleStr forType:NSPasteboardTypeString];
    }
}


-(void)actCopyLinkAndTitleMenu:(id)sender separator:(NSString*)sep
{
    id webUserDataWrapper=[sender representedObject];
    void* apiObject=[webUserDataWrapper userData]; //struct APIObject
    uint32_t type=WKGetTypeID(apiObject);
    if(type==WKDictionaryGetTypeID()){ //8==TypeDictionary
        NSString* linkStr=htWKDictionaryStringForKey(apiObject, @"LinkURL");
        NSString* titleStr=htWKDictionaryStringForKey(apiObject, @"LinkLabel");//or @"LinkTitle"
        if(!linkStr)linkStr=@"";
        if(!titleStr)titleStr=@"";
        NSString* result=[NSString stringWithFormat:@"%@%@%@", titleStr, sep, linkStr];
        
        NSPasteboard*pb=[NSPasteboard generalPasteboard];
        [pb clearContents];
        [pb setString:result forType:NSPasteboardTypeString];
    }
}


-(void)actCopyLinkAndTitleMenu:(id)sender
{
    [self actCopyLinkAndTitleMenu:sender separator:@"\n"];
}


-(void)actCopyLinkAndTitleSpaceMenu:(id)sender
{
    [self actCopyLinkAndTitleMenu:sender separator:@" "];
}


-(void)actWebArchiveSelectionMenu:(id)sender
{
    /*    Class webArchiver=NSClassFromString(@"WebArchiver");
     if(webArchiver){
     WebFrame* frame=[sender representedObject];
     WebArchive *archive = objc_msgSend(webArchiver, @selector(archiveSelectionInFrame:), frame);
     
     if(frame && archive){
     [HTWebClipwinCtl showWindowForWebArchive:archive webFrame:frame info:nil];
     }
     return;
     }
     */
    id wkView=[sender representedObject];
    // NSPasteboard 作成
    NSPasteboard* pb=[NSPasteboard pasteboardWithName:kSafariStandPBKey];
    [pb clearContents];
    // 書き込ませる
    [wkView writeSelectionToPasteboard:pb types:[NSArray arrayWithObject:WebArchivePboardType]];
    NSData* dat=[pb dataForType:WebArchivePboardType];
    WebArchive *archive=nil;
    if (dat) {
        //archive=[[[WebArchive alloc]initWithData:dat]autorelease];
        archive=[[WebArchive alloc]initWithData:dat];
    }
    [pb clearContents];

    if(archive){
        NSString* title=STSafariCurrentTitle();
        NSString* urlStr=STSafariCurrentURLString();
        
        if (!title)title=@"Web Archive";
        if (!urlStr)urlStr=@"";
        NSDictionary* info=[NSDictionary dictionaryWithObjectsAndKeys:title, @"title", urlStr, @"url", nil];
    
        [HTWebClipwinCtl showWindowForWebArchive:archive webFrame:nil info:info];
    }
}


- (id)initWithStand:(id)core
{
    self = [super initWithStand:core];
    if (self) {

        KZRMETHOD_SWIZZLING_WITHBLOCK
        (
         "WKMenuTarget", "setMenuProxy:",
         KZRMethodInspection, call, sel,
         ^(id slf, void *menuProxy)
        {
            call.as_void(slf, sel, menuProxy);
            [self injectToContextMenuProxy:menuProxy];
         });

    }
    return self;
}

- (void)dealloc
{
//    self.squashSheetCtl=nil;
//    [super dealloc];
}


- (void)prefValue:(NSString*)key changed:(id)value
{
    //if([key isEqualToString:])
}


-(NSWindow*)advancedSquashSettingSheet
{
    if (!self.squashSheetCtl) {
        STSquashContextMenuSheetCtl* winCtl=[[STSquashContextMenuSheetCtl alloc]initWithWindowNibName:@"STSquashContextMenuSheetCtl"];
        [winCtl window];
        self.squashSheetCtl=winCtl;
//        [winCtl release];
    }
    return [self.squashSheetCtl window];
}

#pragma mark - image

- (NSMenu*)imagePageSubmenu
{
    NSMenu* menu=[[NSMenu alloc]initWithTitle:@""];
    
    NSMenuItem* itm;
    itm=[menu addItemWithTitle:@"Alignment" action:nil keyEquivalent:@""];
    [itm setEnabled:NO];
    
    itm=[menu addItemWithTitle:@"Align Left" action:@selector(actImagePageAlignment:) keyEquivalent:@""];
    [itm setRepresentedObject:@"0"];
    [itm setTarget:self];
    
    itm=[menu addItemWithTitle:@"Align Center" action:@selector(actImagePageAlignment:) keyEquivalent:@""];
    [itm setRepresentedObject:@"auto"];
    [itm setTarget:self];
    
    [menu addItem:[NSMenuItem separatorItem]];
    itm=[menu addItemWithTitle:@"Background Color" action:nil keyEquivalent:@""];
    [itm setEnabled:NO];
    
    itm=[menu addItemWithTitle:@"White (#FFFFFF)" action:@selector(actImagePageBackgroundColor:) keyEquivalent:@""];
    [itm setRepresentedObject:@"#ffffff"];
    [itm setTarget:self];
    itm=[menu addItemWithTitle:@"Black (#000000)" action:@selector(actImagePageBackgroundColor:) keyEquivalent:@""];
    [itm setRepresentedObject:@"#000000"];
    [itm setTarget:self];
    itm=[menu addItemWithTitle:@"Gray (#666666)" action:@selector(actImagePageBackgroundColor:) keyEquivalent:@""];
    [itm setRepresentedObject:@"#666666"];
    [itm setTarget:self];
    itm=[menu addItemWithTitle:@"Light Gray (#CCCCCC)" action:@selector(actImagePageBackgroundColor:) keyEquivalent:@""];
    [itm setRepresentedObject:@"#cccccc"];
    [itm setTarget:self];
    
    itm=[menu addItemWithTitle:@"Other Color..." action:@selector(actImagePageBackgroundOther:) keyEquivalent:@""];
    [itm setTarget:self];
    
    return menu;
}


- (void)actImagePageAlignment:(NSMenuItem*)sender
{
    NSString* value=[sender representedObject];
    NSString* scpt=[NSString stringWithFormat:@"document.body.childNodes[0].style.margin=\"%@\";", value];
    [STFakeJSCommand doScript:scpt onTarget:nil completionHandler:^(id result) { }];
}


- (void)actImagePageBackgroundColor:(NSMenuItem*)sender
{
    NSString* color=[sender representedObject];
    NSString* scpt=[NSString stringWithFormat:@"document.body.style.background=\"%@\"", color];
    [STFakeJSCommand doScript:scpt onTarget:nil completionHandler:^(id result) { }];
}


- (void)actImagePageBackgroundOther:(NSMenuItem*)sender
{
    NSColorPanel* panel=[NSColorPanel sharedColorPanel];
    
    [panel setTarget:self];
    [panel setAction:@selector(actImagePageBackgroundFromColorPanel:)];
    [panel makeKeyAndOrderFront:self];
}


- (void)actImagePageBackgroundFromColorPanel:(NSColorPanel*)sender
{
    NSColor* color=sender.color;
    NSString* scpt=[NSString stringWithFormat:@"document.body.style.background=\"rgb(%d,%d,%d)\"",
                    (int)(color.redComponent*255.0), (int)(color.greenComponent*255.0), (int)(color.blueComponent*255.0)];
    [STFakeJSCommand doScript:scpt onTarget:nil completionHandler:^(id result) { }];
}


#ifdef DEBUG_MENUDUMP

// WindowPolicy checker
- (NSMenu*)safariWindowPolicyTestMenuWithUserDataWrapper:(id)webUserDataWrapper
{
    NSInteger i;
    NSMenu* menu=[[NSMenu alloc]initWithTitle:@"WindowPolicyTest"];
    for (i=0; i<11; i++) {
        NSString* title=[NSString stringWithFormat:@"WindowPolicy %ld", (long)i];
        NSMenuItem* itm=[[NSMenuItem alloc]initWithTitle:title action:@selector(actWindowPolicyTest:) keyEquivalent:@""];
        [itm setTarget:self];
        [itm setTag:i];
        [itm setRepresentedObject:webUserDataWrapper];
        [menu addItem:itm];
    }
    return menu;
}

- (void)actWindowPolicyTest:(id)sender
{
    id webUserDataWrapper=[sender representedObject];
    void* apiObject=[webUserDataWrapper userData]; //struct APIObject
    uint32_t type=WKGetTypeID(apiObject);
    if(type==WKDictionaryGetTypeID()){ //8==TypeDictionary
        NSString* linkStr=htWKDictionaryStringForKey(apiObject, @"LinkURL");
        NSURL* url=[NSURL URLWithString:linkStr];
        if(url) STSafariGoToURLWithPolicy(url, (int)[sender tag]);
    }
}

#endif

@end
