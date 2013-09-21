//
//  STSContextMenuModule.m
//  SafariStand

#if __has_feature(objc_arc)
#error This file must be compiled with -fno-objc_arc
#endif

#import "SafariStand.h"
#import "STSContextMenuModule.h"
#import "STQuickSearch.h"
#import <WebKit/WebKit.h>
#import "HTWebKit2Adapter.h"
#import "HTWebClipwinCtl.h"

#import "SquashContextMenuSheetCtl.h"


//#define DEBUG_MENUDUMP 0

@implementation STSContextMenuModule
@synthesize squashSheetCtl=_squashSheetCtl;

static STSContextMenuModule* contextMenuModule;


IMP orig_setMenuProxy;
// オリジナルの setMenuProxy: と差し替えるメソッド
void ST_setMenuProxy(id self, SEL _cmd, void *menuProxy)
{
    // オリジナルのメソッドを呼んでやる
    orig_setMenuProxy(self, _cmd, menuProxy);
    
    // menuProxy は WebContextMenuProxyMac クラスのポインタ
    // 16バイト目に NSPopUpButtonCell * へのポインタが格納されている
    NSPopUpButtonCell *cell = *(NSPopUpButtonCell **)((void **)menuProxy + 2);
    
    // cell から menu を取得
    // プラグインや機能拡張によって追加されたメニュー項目も含む、画面に表示する直前の状態のメニューが取り出せる
    NSMenu *menu = [cell menu];
    NSMenuItem* itm;
#ifdef DEBUG  

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
            NSNumber *tagNum=[NSNumber numberWithInt:[itm tag]];
            if (![tagdic objectForKey:tagNum]) {
                [tagary addObject:[NSDictionary dictionaryWithObjectsAndKeys:tagNum, @"tag", [itm title], @"title",nil]];
                [tagdic setObject:[itm title] forKey:tagNum];
            }
        }
        NSString* debugTtile=[NSString stringWithFormat:@"%@ (%lu)",[itm title],[itm tag]];
        [itm setTitle:debugTtile];
    }
#endif

#endif
    
    //STSDownloadModule
	if([[NSUserDefaults standardUserDefaults]boolForKey:kpClassifyDownloadFolderBasicEnabled]){
        NSMenuItem* itm=[menu itemWithTag:10009];
        id dlModule=[STCSafariStandCore mi:@"STSDownloadModule"];
        if (itm && dlModule) {
            [itm setAction:@selector(actCopyImageToDownloadFolderMenu:)];
            [itm setTarget:dlModule];
        }
    }
    
    
    // 選択文字列を調べる
    // WKView を取得。menuProxy の 24バイト目
    id wkview = *(id *)((void **)menuProxy + 3);

    // 適当な名前で NSPasteboard 作成
    NSPasteboard* pb=[NSPasteboard pasteboardWithName:kSafariStandPBKey];
    [pb clearContents];
    // 書き込ませる
    [wkview writeSelectionToPasteboard:pb types:[NSArray arrayWithObject:NSStringPboardType]];
    NSString* selectedText=[[pb stringForType:NSStringPboardType]htModeratedStringWithin:0];
    NSUInteger len=[selectedText length];
    if(len>0 && len<1024){//あんまり長いのは除外
        //LOG(@"%@",[pb stringForType:NSStringPboardType]);
        [[STQuickSearch si]setupContextMenu:menu];
    }
    
    //Clip Web Archive
    
    if(len>0 && [[NSUserDefaults standardUserDefaults]boolForKey:kpShowClipWebArchiveContextMenu]){
        NSMenuItem* itm;
        itm=[[NSMenuItem alloc]initWithTitle:@"Clip Web Archive with Selection"
                                      action:@selector(actWebArchiveSelectionMenu:) keyEquivalent:@""];
        [itm setTarget:contextMenuModule];
        [itm setRepresentedObject:wkview];
        [menu addItem:itm];
        [itm release];
    }

    
    NSMenuItem* copyLinkItem=[menu itemWithTag:3]; //3 == copy link
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
                [itm setTarget:contextMenuModule];
                [itm setRepresentedObject:webUserDataWrapper];
                [menu insertItem:itm atIndex:++idx];
                [itm release];

                if([[NSUserDefaults standardUserDefaults]boolForKey:kpCopyLinkTagAddTargetBlank]){
                    itm=[[NSMenuItem alloc]initWithTitle:LOCALIZE(@"Copy Link Tag") 
                                                  action:@selector(actCopyLinkTagMenu:) keyEquivalent:@""];
                }else{
                    itm=[[NSMenuItem alloc]initWithTitle:LOCALIZE(@"Copy Link Tag (_blank)") 
                                                  action:@selector(actCopyLinkTagBlankMenu:) keyEquivalent:@""];
                }
                [itm setTarget:contextMenuModule];
                [itm setRepresentedObject:webUserDataWrapper];
                [itm setKeyEquivalentModifierMask:NSAlternateKeyMask];
                [itm setAlternate:YES];
                [menu insertItem:itm atIndex:++idx];
                [itm release];
            
            }
            
            if([[NSUserDefaults standardUserDefaults]boolForKey:kpShowCopyLinkTitleContextMenu]){
                itm=[[NSMenuItem alloc]initWithTitle:LOCALIZE(@"Copy Link Title") action:@selector(actCopyLinkTitleMenu:) keyEquivalent:@""];
                [itm setTarget:contextMenuModule];
                [itm setRepresentedObject:webUserDataWrapper];
                [menu insertItem:itm atIndex:++idx];
                [itm release];
                
            }
            if([[NSUserDefaults standardUserDefaults]boolForKey:kpShowCopyLinkAndTitleContextMenu]){
                itm=[[NSMenuItem alloc]initWithTitle:LOCALIZE(@"Copy Link and Title") action:@selector(actCopyLinkAndTitleMenu:) keyEquivalent:@""];
                [itm setTarget:contextMenuModule];
                [itm setRepresentedObject:webUserDataWrapper];
                [menu insertItem:itm atIndex:++idx];
                [itm release];
                
                itm=[[NSMenuItem alloc]initWithTitle:LOCALIZE(@"Copy Link (space) Title") action:@selector(actCopyLinkAndTitleSpaceMenu:) keyEquivalent:@""];
                [itm setTarget:contextMenuModule];
                [itm setRepresentedObject:webUserDataWrapper];
                [itm setKeyEquivalentModifierMask:NSAlternateKeyMask];
                [itm setAlternate:YES];
                [menu insertItem:itm atIndex:++idx];
                [itm release];
                
            }
        }
        
        //LOG(@"%ud, %ud, %@,%@",type,WKDataGetTypeID(),[copyLinkItem title], NSStringFromSelector([copyLinkItem action]));
    } //if(copyLinkItem)
    
    
    NSMenuItem* copyImageItem=[menu itemWithTag:6]; //6 == copy link
    if(copyImageItem){
        if([[NSUserDefaults standardUserDefaults]boolForKey:kpShowGoogleImageSearchContextMenu]){
            NSInteger idx=[menu indexOfItem:copyImageItem];
            itm=[[NSMenuItem alloc]initWithTitle:LOCALIZE(@"Google Image Search") action:@selector(actImageSearchMenu:) keyEquivalent:@""];
            [itm setTarget:contextMenuModule];
            [itm setRepresentedObject:[copyImageItem representedObject]];
            [menu insertItem:itm atIndex:++idx];
            [itm release];
        }
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



-(void)actImageSearchMenu:(id)sender{
    id webUserDataWrapper=[sender representedObject];
    void* apiObject=[webUserDataWrapper userData]; //struct APIObject
    uint32_t type=WKGetTypeID(apiObject);
    if(type==WKDictionaryGetTypeID()){ //8==TypeDictionary
        NSString* urlStr=htWKDictionaryStringForKey(apiObject, @"ImageURL");
        LOG(@"%@",urlStr);
        [[STQuickSearch si]sendGoogleImageQuerySeedWithoutAddHistoryWithSearchString:urlStr policy:[STQuickSearch tabPolicy]];
    }
}

-(void)actCopyLinkTagMenu:(id)sender{
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
        [pb setString:result forType:NSStringPboardType];
    }
}
-(void)actCopyLinkTagBlankMenu:(id)sender{
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
        [pb setString:result forType:NSStringPboardType];
    }
}

-(void)actCopyLinkTitleMenu:(id)sender{
    id webUserDataWrapper=[sender representedObject];
    void* apiObject=[webUserDataWrapper userData]; //struct APIObject
    uint32_t type=WKGetTypeID(apiObject);
    if(type==WKDictionaryGetTypeID()){ //8==TypeDictionary

        NSString* titleStr=htWKDictionaryStringForKey(apiObject, @"LinkLabel");//or @"LinkTitle"
        if(!titleStr)titleStr=@"";
        
        NSPasteboard*pb=[NSPasteboard generalPasteboard];
        [pb clearContents];
        [pb setString:titleStr forType:NSStringPboardType];
    }
}

-(void)actCopyLinkAndTitleMenu:(id)sender separator:(NSString*)sep{
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
        [pb setString:result forType:NSStringPboardType];
    }
}

-(void)actCopyLinkAndTitleMenu:(id)sender{
    [self actCopyLinkAndTitleMenu:sender separator:@"\n"];
}
-(void)actCopyLinkAndTitleSpaceMenu:(id)sender{
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
        archive=[[[WebArchive alloc]initWithData:dat]autorelease];
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
        contextMenuModule=self;

        orig_setMenuProxy = RMF(NSClassFromString(@"WKMenuTarget"),
                                     @selector(setMenuProxy:), ST_setMenuProxy);

    }
    return self;
}

- (void)dealloc
{
    self.squashSheetCtl=nil;
    [super dealloc];
}

- (void)prefValue:(NSString*)key changed:(id)value
{
    //if([key isEqualToString:])
}

-(NSWindow*)advancedSquashSettingSheet
{
    if (!self.squashSheetCtl) {
        SquashContextMenuSheetCtl* winCtl=[[SquashContextMenuSheetCtl alloc]initWithWindowNibName:@"SquashContextMenuSheetCtl"];
        [winCtl window];
        self.squashSheetCtl=winCtl;
        [winCtl release];
    }
    return [self.squashSheetCtl window];
}


@end
