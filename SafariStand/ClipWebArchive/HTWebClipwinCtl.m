//
//  HTWebClipwinCtl.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import "SafariStand.h"

#import "HTWebClipwinCtl.h"
#import "HTUtils.h"
#import "HTFilePresetPopUpButton.h"
#import "HTDOMElementHierarchyMenuItem.h"
#import "HTWebKit2Adapter.h"
#import "HTWindowControllerRetainer.h"
#import "NSFileManager+SafariStand.h"

/*
info=NSDictionary
node=>DOMNode
url=>urlStr
title=>title
*/

@implementation HTWebClipWin

- (void) dealloc
{

}

@end

@implementation HTWebClipwinCtl {
    
    WebArchive* _webArchive;
    NSString* _defaultTitle;
    NSString* _urlStr;
    NSString* _filePath;
}

void showWindowForFrontmostWKViewGetWebArchive(WKDataRef archiveData, WKErrorRef error, void* info)
{
    if (archiveData) {
        NSDictionary* dic=(__bridge NSDictionary*)info;
        NSData* data=htNSDataFromWKData(archiveData);
        WebArchive* arc=[[WebArchive alloc]initWithData:data];

        [HTWebClipwinCtl showWindowForWebArchive:arc webFrame:nil info:dic];

        //WKRelease(archiveData);
    }
    if (info) {
        CFRelease(info);
    }
}

+ (void)showUntitledWindow
{
    //create
    NSDictionary* info=[NSDictionary dictionaryWithObjectsAndKeys:@"New Archive", @"title", nil];
    HTWebClipwinCtl*  winCtl=[[HTWebClipwinCtl alloc]initWithWebArchive:nil webFrame:nil info:info];
    if(winCtl){
        [winCtl showWindow:nil];
    }
}

+ (void)showWindowForCurrentWKView
{
    id wkView=STSafariCurrentWKView();
    if (!wkView) {
        return;
    }
    
    NSString* title=STSafariCurrentTitle();
    NSString* urlStr=STSafariCurrentURLString();

    NSDictionary* info=({
        if (!title) title=@"";
        if (!urlStr) urlStr=@"";
        
        @{@"title":title, @"url":urlStr};
    });

    WKPageRef pageRef=htWKPageRefForWKView(wkView);
    if (pageRef) {
        WKFrameRef frameRef=WKPageGetMainFrame(pageRef);
        WKFrameGetWebArchive(frameRef, showWindowForFrontmostWKViewGetWebArchive, (void*)CFBridgingRetain(info));

    }
}

+ (void)showWindowForWebArchive:(WebArchive*)arc webFrame:(WebFrame*)webFrame info:(NSDictionary*)info
{
    //create
    HTWebClipwinCtl*  winCtl=[[HTWebClipwinCtl alloc]initWithWebArchive:arc webFrame:webFrame info:info];
    if(winCtl){
        [winCtl showWindow:nil];
    }            

}


- (id)initWithWebArchive:(WebArchive*)arc webFrame:(WebFrame*)webFrame info:(NSDictionary*)info
{
    
    self = [self initWithWindowNibName:@"HTWebClipWin"];
    if (self) {
        _filePath=nil;
        _webArchive=arc;
        if(info){
            _defaultTitle=[info objectForKey:@"title"];
            _urlStr=[info objectForKey:@"url"];
        }else{
            _defaultTitle=nil;
            _urlStr=nil;
        }

        if(!_urlStr)_urlStr=@"";
        if(!_defaultTitle)_defaultTitle=_urlStr;
        //URL=[[arc mainResource]URL]
    }
    return self;
}

- (void)windowWillClose:(NSNotification *)aNotification
{
    [self.oWebView setUIDelegate:nil];
	[[NSNotificationCenter defaultCenter]removeObserver:self 
    name:WebViewDidChangeNotification object:self.oWebView];

}


- (void)awakeFromNib
{

    //toolbar
    [[self window]setToolbar:({
        NSToolbar* toolbar=[[NSToolbar alloc]initWithIdentifier:@"Stand_WebClip_Toolbar"];
        [toolbar setDelegate:self];
        [toolbar setAllowsUserCustomization:YES];
        [toolbar setAutosavesConfiguration: YES];
        [toolbar setDisplayMode:NSToolbarDisplayModeDefault];
        toolbar;
    })];


    //popup
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES);
    [self.oDirPopUp setupWithIdentifier:@"HTWebClipwin" preset:paths];
	[[super window] setFrameAutosaveName:@"Stand_WebClipWin"];

    [self.oFileNameFld setStringValue:_defaultTitle];

    //webview
    [self.oWebView setUIDelegate:self];
    if(_webArchive){
        [[self.oWebView mainFrame]loadArchive:_webArchive];
    }else{
        [[self.oWebView mainFrame]loadHTMLString:@"<html><body></body></html>" baseURL:nil];
    }
    
    if(_filePath){
        [[self window]setTitleWithRepresentedFilename:[self filePath]];
    }


	//observe edit
	[[NSNotificationCenter defaultCenter]addObserver:self
	 selector:@selector(noteWebViewDidChange:)
	 name:WebViewDidChangeNotification object:self.oWebView];

}

- (void)windowDidLoad
{
    [[HTWindowControllerRetainer si]addWindowController:self];
    [super windowDidLoad];
}

-(void)noteWebViewDidChange:(NSNotification*)note
{
    if([[self window]representedFilename]){
    
        [self setDocumentEdited:YES];
    }
}


#pragma mark -

- (NSString *)filePath
{
    return [_filePath copy];
}

- (void)setFilePath:(NSString *)value
{
    if (_filePath != value) {
        _filePath = [value copy];
        
        [[self window]setTitleWithRepresentedFilename:[self filePath]];
        [self.oFileNameFld setEnabled:NO];
        [self.oDirPopUp setEnabled:NO];
    }
}



-(BOOL)writeToFile:(NSString *)filePath
{
    //WebArchive* arc=[[[self.oWebView mainFrame]dataSource]webArchive];
    WebArchive* arc=[[[self.oWebView windowScriptObject]evaluateWebScript:@"document"]webArchive];
    BOOL result=[[arc data]writeToFile:filePath atomically:YES];

    if(result) HTClearFileQuarantineState(filePath);

    [self setDocumentEdited:NO];

    return result;
}

-(void)saveToDisk
{
    NSString* filePath=[self filePath];
    if(filePath){
        [self writeToFile:filePath];
        
        return;
    }
    
    NSString* fileName=[self.oFileNameFld stringValue];
    NSString* dirPath=[self.oDirPopUp selectedFilePath];
    fileName=(NSString*)objc_msgSend(fileName, @selector(_web_filenameByFixingIllegalCharacters));
    if([fileName length]>0 && dirPath){
        filePath=[[dirPath stringByAppendingPathComponent:fileName]stringByAppendingPathExtension:@"webarchive"];
        filePath=[[NSFileManager defaultManager]stand_pathWithUniqueFilenameForPath:filePath];
        if([self writeToFile:filePath]){
            [self setFilePath:filePath];
        }
    }
}

//from mainmenu
- (IBAction)saveDocumentTo:(id)sender
{
    [self saveToDisk];
}

-(IBAction)actSave:(id)sender
{
    [self saveToDisk];
}

-(IBAction)actSaveAndClose:(id)sender
{
    [self saveToDisk];
    [[self window]performClose:self];
}


-(IBAction)actEditMemo:(id)sender
{
    if (self.oMemoPopover.isShown) {
        [self.oMemoPopover performClose:nil];
        return;
    }
    
    NSView* relativeView=nil;
    NSRect relativeRect=NSZeroRect;
/*
    NSToolbar* tb=self.window.toolbar;
    if ([tb isVisible]) {
        NSArray *itms=[tb visibleItems];
        for (NSToolbarItem* itm in itms) {
            if([[itm itemIdentifier]isEqualToString:@"clip_memo"]){
                relativeView=[itm view];
                //NSButton だと思った？　残念 (null) でした！
                break;
            }
        }
    }
*/
    if (!relativeView) {
        relativeView=self.oWebView;
        relativeRect=[relativeView bounds];
        relativeRect.origin.y=NSMaxY(relativeRect)-20;
        relativeRect.size.height=20;
    }
    
    [self.oMemoPopover showRelativeToRect:relativeRect ofView:relativeView preferredEdge:CGRectMinYEdge];
    
}

-(IBAction)actToggleEditable:(id)sender
{
    if([self.oWebView respondsToSelector:@selector(setEditable:)]){
        BOOL value=![self.oWebView isEditable];
        [self.oWebView setEditable:value];
        if([sender respondsToSelector:@selector(setTitle:)]){
            if(value){
                [sender setTitle:@"End Edit"];
            }else{
                [sender setTitle:@"Make Editable"];
            }
        }
    }
}

-(IBAction)actInsertContentHeader:(id)sender
{
    BOOL result=[self insertContentHeaderToggle:YES];
    
    if([sender respondsToSelector:@selector(setTitle:)]){
        if(result){
            [sender setTitle:@"Remove Header"];
        }else{
            [sender setTitle:@"Insert Header"];
        }
    }
    if(_filePath)[self setDocumentEdited:YES];

}


-(IBAction)actInsertMemo:(id)sender
{
    [self insertMemo:[self.oMemoTextView string]];
}

-(IBAction)actClearMemo:(id)sender
{
    [self.oMemoTextView setString:@""];
    [self insertMemo:nil];
}

- (BOOL)insertContentHeaderToggle:(BOOL)toggle
{
//kClipContentHeaderID
    BOOL result=NO;
    WebScriptObject* so=[self.oWebView windowScriptObject];
    DOMHTMLDocument* doc=[so evaluateWebScript:@"document"];
    
    DOMNode* head=[doc getElementById:@"safaristand-clip-header"];
    if(!head || [head isKindOfClass:[WebUndefined class]]){
        NSString*   dateStr=HTStringFromDateWithFormat([NSDate date], @"%Y-%m-%d %H:%M:%S");
        NSString* tmplPath=[[[NSBundle bundleForClass:[self class]]resourcePath]
                    stringByAppendingPathComponent:@"clip_header.html"];

        NSMutableString* headStr=[NSMutableString stringWithContentsOfFile:tmplPath encoding:NSUTF8StringEncoding error:nil];
        [headStr replaceOccurrencesOfString:@"{{{title}}}"   withString:_defaultTitle 
                    options:0 range:NSMakeRange(0, [headStr length])];
        [headStr replaceOccurrencesOfString:@"{{{date}}}"   withString:dateStr 
                    options:0 range:NSMakeRange(0, [headStr length])];
        [headStr replaceOccurrencesOfString:@"{{{url}}}"   withString:_urlStr
                    options:0 range:NSMakeRange(0, [headStr length])];
        
        id outer=[doc createElement:@"div"];
        [outer setInnerHTML:headStr];
        id body=[doc body];
        [body insertBefore:[outer firstChild] refChild:[body firstChild]];
        result=YES;
    }else if(toggle){
        [[head parentNode]removeChild:head];
        head=nil;
    }


    return result;

}

- (void)insertMemo:(NSString*)memo
{
//kClipContentHeaderID
    WebScriptObject* so=[self.oWebView windowScriptObject];
    DOMHTMLDocument* doc=[so evaluateWebScript:@"document"];

    NSMutableString* headStr=nil;
    
    if([memo length]>0){
        NSString* tmplPath=[[[NSBundle bundleForClass:[self class]]resourcePath]
                    stringByAppendingPathComponent:@"clip_memo.html"];
        headStr=[NSMutableString stringWithContentsOfFile:tmplPath encoding:NSUTF8StringEncoding error:nil];
        [headStr replaceOccurrencesOfString:@"{{{memo}}}"   withString:memo 
                    options:0 range:NSMakeRange(0, [headStr length])];
    }
    
    DOMNode* elem=[doc getElementById:@"safaristand-clip-memo"];
    if(elem && ![elem isKindOfClass:[WebUndefined class]]){
        [[elem parentNode] removeChild:elem];
    }
    
    if(headStr){
        [self insertContentHeaderToggle:NO];
    
        id outer=[doc createElement:@"div"];
        [outer setInnerHTML:headStr];
        id body=[doc getElementById:@"safaristand-clip-header"];
        if(body && [body respondsToSelector:@selector(appendChild:)])[body appendChild:[outer firstChild]];
    }
    
    if(_filePath)[self setDocumentEdited:YES];
    
    if (self.oMemoPopover.isShown) {
        [self.oMemoPopover performClose:nil];
        return;
    }
}



#pragma mark - - toolbar


- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    return [NSArray arrayWithObjects : @"clip_header", @"clip_memo", @"clip_edit", @"clip_save", @"clip_savec",
            NSToolbarSeparatorItemIdentifier, NSToolbarSpaceItemIdentifier, 
            NSToolbarFlexibleSpaceItemIdentifier, NSToolbarCustomizeToolbarItemIdentifier, nil];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
    return [NSArray arrayWithObjects : @"clip_header", @"clip_memo", @"clip_edit", NSToolbarSeparatorItemIdentifier, @"clip_save", nil];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    if(![itemIdentifier hasPrefix:@"clip_"]) return nil;
    
    static NSImage* clipHeaderIcon;
    static NSImage* clipEditIcon;
    static NSImage* clipSaveIcon;
    static NSImage* clipMemoIcon;
    static NSImage* clipSavecIcon;
    NSString* labelStr=nil;
    NSImage* icon=nil;
    NSToolbarItem*  item=[[NSToolbarItem alloc]initWithItemIdentifier:itemIdentifier];
    
    [item setTarget:self];
    if([itemIdentifier isEqualToString:@"clip_header"]){
        if(clipHeaderIcon==nil){
            NSBundle*   myBundle=[NSBundle bundleForClass:[self class]];
            NSString* tmpStr=[myBundle pathForResource:@"clip_header" ofType:@"tiff"];
            clipHeaderIcon=[[NSImage alloc] initWithContentsOfFile:tmpStr];
        }
        icon=clipHeaderIcon;
        labelStr=@"Header";
        [item setAction:@selector(actInsertContentHeader:)];
    }else if([itemIdentifier isEqualToString:@"clip_edit"]){
        if(clipEditIcon==nil){
            NSBundle*   myBundle=[NSBundle bundleForClass:[self class]];
            NSString* tmpStr=[myBundle pathForResource:@"clip_edit" ofType:@"tiff"];
            clipEditIcon=[[NSImage alloc] initWithContentsOfFile:tmpStr];
        }
        icon=clipEditIcon;
        labelStr=@"Edit";
        [item setAction:@selector(actToggleEditable:)];
    }else if([itemIdentifier isEqualToString:@"clip_memo"]){
        if(clipMemoIcon==nil){
            NSBundle*   myBundle=[NSBundle bundleForClass:[self class]];
            NSString* tmpStr=[myBundle pathForResource:@"clip_memo" ofType:@"tiff"];
            clipMemoIcon=[[NSImage alloc] initWithContentsOfFile:tmpStr];
        }
        icon=clipMemoIcon;
        labelStr=@"Memo";
        [item setAction:@selector(actEditMemo:)];
    }else if([itemIdentifier isEqualToString:@"clip_savec"]){
        if(clipSavecIcon==nil){
            NSBundle*   myBundle=[NSBundle bundleForClass:[self class]];
            NSString* tmpStr=[myBundle pathForResource:@"clip_savec" ofType:@"tiff"];
            clipSavecIcon=[[NSImage alloc] initWithContentsOfFile:tmpStr];
        }
        icon=clipSavecIcon;
        labelStr=@"Save & Close";
        [item setAction:@selector(actSaveAndClose:)];
    }else if([itemIdentifier isEqualToString:@"clip_save"]){
        if(clipSaveIcon==nil){
            //NSBundle*   myBundle=[NSBundle bundleForClass:[self class]];
            //NSString* tmpStr=[myBundle pathForResource:@"clip_edit" ofType:@"tiff"];
            clipSaveIcon=[[NSWorkspace sharedWorkspace]iconForFileType:@"webarchive"];
        }
        icon=clipSaveIcon;
        labelStr=@"Save";
        [item setAction:@selector(actSave:)];
    }
    
    if(labelStr){
        [item setLabel:labelStr];
        [item setPaletteLabel:labelStr];
    }
    if(icon){
        [item setImage:icon];
    }
    return item;

}



#pragma mark - - UIDelegate

- (void)webView:(WebView *)sender setStatusText:(NSString *)text
{


}

- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems
{
    NSMutableArray* result;
    if([sender isEditable]){
        result=[NSMutableArray arrayWithArray:defaultMenuItems];

    }else{
        result=[NSMutableArray array];
    }
    //result=defaultMenuItems;
    WebFrame*  elementWebFrame=[element objectForKey:WebElementFrameKey];
    id dom=[element objectForKey:WebElementDOMNodeKey];
    if(dom && elementWebFrame){
        NSMenuItem* myMenuItem=HTDOMHTMLElementHierarchyMenuItemRetained(dom, @"Remove Element",
                                     @selector(actRemoveElementConextMenu:), self, NO);
        if(myMenuItem){
            [result addObject:myMenuItem];
            
        }
    }
    return result;
}

#pragma mark - - MenuDelegate

- (void)actRemoveElementConextMenu:(id)sender
{
    DOMNode* node=[sender representedObject];
    if(node){
        [[node parentNode]removeChild:node];
    }
}




@end
