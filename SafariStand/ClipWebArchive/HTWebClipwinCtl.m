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

@implementation HTWebClipwinCtl


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
        
        WKFrameGetWebArchive_b(frameRef, ^(WKDataRef archiveData, WKErrorRef error){
            if (archiveData) {
                NSDictionary* dic=info;
                NSData* data=htNSDataFromWKData(archiveData);
                WebArchive* arc=[[WebArchive alloc]initWithData:data];
                
                [HTWebClipwinCtl showWindowForWebArchive:arc webFrame:nil info:dic];
                
                //WKRelease(archiveData);
            }
        });
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
    [oWebView setUIDelegate:nil];
	[[NSNotificationCenter defaultCenter]removeObserver:self 
    name:WebViewDidChangeNotification object:oWebView];

}

- (void)toggleBottomDiscloseViewDisplay:(BOOL)display
{
// www.mactech.com/articles/mactech/Vol.16/16.09/DrawersandDisclosure/index.html
   NSWindow *win = [self window];
   NSRect winFrame = [win frame];

// we'll need to know the size of both boxes in this case:
   NSRect topFrame = [oMainView frame];
   NSRect bottomFrame = [oBottomDiscloseView frame];

// get the original settings for reestablishing later:
   NSInteger topMask = [oMainView autoresizingMask];
   NSInteger bottomMask = [oBottomDiscloseView autoresizingMask];
   
// toggle the state
   NSInteger stateToSet = 1 - [oDisclosureButton tag];
   
   [win disableFlushWindow];

// set the boxes to not automatically resize when the window resizes:
   [oMainView setAutoresizingMask:NSViewNotSizable];
   [oBottomDiscloseView setAutoresizingMask:NSViewNotSizable];

   // if the button's state is 1, then stateToSet == 0, collapse it:
   if (stateToSet == 0) {
       // adjust the desired height and origin of the window:
        winFrame.size.height -= NSHeight(bottomFrame);
        winFrame.origin.y += NSHeight(bottomFrame);
	    // adjust the origin of the bottom box well below the window:
        bottomFrame.origin.y = -NSHeight(bottomFrame);
		// begin the top box at the bottom of the window
        topFrame.origin.y = 0.0;
   } else {
	   // stack the boxes one on top of the other:
       bottomFrame.origin.y = 0.0;
       topFrame.origin.y = NSHeight(bottomFrame);

       // adjust the desired height and origin of the window:
       winFrame.size.height += NSHeight(bottomFrame);
       winFrame.origin.y -= NSHeight(bottomFrame);
   }

   // adjust locations of the boxes:
   [oMainView setFrame:topFrame];
   [oBottomDiscloseView setFrame:bottomFrame];

   // change the state of the button to reflect new arrangement:
   [oDisclosureButton setState:stateToSet];
   [oDisclosureButton setTag:stateToSet];

  // resize the window and display:
   [win setFrame:winFrame display:display];

   // reset the boxes to their original autosize masks:
   [oMainView setAutoresizingMask:topMask];
   [oBottomDiscloseView setAutoresizingMask:bottomMask];

   [win enableFlushWindow];

}

- (void)awakeFromNib
{

    //toolbar
    NSToolbar* tb=[[NSToolbar alloc]initWithIdentifier:@"Stand_WebClip_Toolbar"];
    [tb setDelegate:self];
    [tb setAllowsUserCustomization:YES];
    [tb setAutosavesConfiguration: YES];
    [tb setDisplayMode:NSToolbarDisplayModeDefault];
    [[self window]setToolbar:tb];


    //bottomview
    [oDisclosureButton setTag:1];
    [self toggleBottomDiscloseViewDisplay:NO];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES);
    
    //popup
    [oDirPopUp setupWithIdentifier:@"HTWebClipwin" preset:paths];
	[[super window] setFrameAutosaveName:@"Stand_WebClipWin"];

    [oFileNameFld setStringValue:_defaultTitle];

    //webview
    [oWebView setUIDelegate:self];
    if(_webArchive){
        [[oWebView mainFrame]loadArchive:_webArchive];
    }else{
        [[oWebView mainFrame]loadHTMLString:@"<html><body></body></html>" baseURL:nil];
    }
    
    if(_filePath){
        [[self window]setTitleWithRepresentedFilename:[self filePath]];
    }


	//observe edit
	[[NSNotificationCenter defaultCenter]addObserver:self
	 selector:@selector(noteWebViewDidChange:)
	 name:WebViewDidChangeNotification object:oWebView];

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
        [oFileNameFld setEnabled:NO];
        [oDirPopUp setEnabled:NO];
    }
}






-(BOOL)writeToFile:(NSString *)filePath
{
    //WebArchive* arc=[[[oWebView mainFrame]dataSource]webArchive];
    WebArchive* arc=[[[oWebView windowScriptObject]evaluateWebScript:@"document"]webArchive];
    BOOL result=[[arc data]writeToFile:filePath atomically:YES];

    //HTClearFileQuarantineState(filePath);

    
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
    
    NSString* fileName=[oFileNameFld stringValue];
    NSString* dirPath=[oDirPopUp selectedFilePath];
    fileName=(NSString*)objc_msgSend(fileName, @selector(_web_filenameByFixingIllegalCharacters));
    if([fileName length]>0 && dirPath){
        filePath=[[dirPath stringByAppendingPathComponent:fileName]stringByAppendingPathExtension:@"webarchive"];
        filePath=objc_msgSend([NSFileManager defaultManager],@selector(_web_pathWithUniqueFilenameForPath:), filePath);
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


-(IBAction)actToggleBottomDiscloseViewDisplay:(id)sender
{
[self performSelector:@selector(toggleBottomDiscloseViewDisplay:) 
			withObject:0 afterDelay:0.01];
//    [self toggleBottomDiscloseViewDisplay:NO];
}

-(IBAction)actToggleEditable:(id)sender
{
    if([oWebView respondsToSelector:@selector(setEditable:)]){
        BOOL value=![oWebView isEditable];
        [oWebView setEditable:value];
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
    [self insertMemo:[oMemoTextView string]];
}

-(IBAction)actClearMemo:(id)sender
{
    [self insertMemo:nil];
}

- (BOOL)insertContentHeaderToggle:(BOOL)toggle
{
//kClipContentHeaderID
    BOOL result=NO;
    WebScriptObject* so=[oWebView windowScriptObject];
    DOMHTMLDocument* doc=[so evaluateWebScript:@"document"];
    
    DOMNode* head=[doc getElementById:@"safaristand-clip-header"];
    if(!head || [head isKindOfClass:[WebUndefined class]]){
        NSCalendarDate* date=[NSCalendarDate calendarDate];
        NSString*   dateStr=[date descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:%S"];
        NSString* tmplPath=[[[NSBundle bundleForClass:[self class]]resourcePath]
                    stringByAppendingPathComponent:@"clip_header.html"];
        //NSMutableString* headStr=[NSMutableString stringWithContentsOfFile:tmplPath];
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
    WebScriptObject* so=[oWebView windowScriptObject];
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

}



#pragma mark -


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
        [item setAction:@selector(actToggleBottomDiscloseViewDisplay:)];
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



#pragma mark -
#pragma mark ----- UIDelegate
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
#pragma mark -
#pragma mark ----- MenuDelegate

- (void)actRemoveElementConextMenu:(id)sender{
    
    DOMNode* node=[sender representedObject];
    if(node){
        [[node parentNode]removeChild:node];
        
    }

}




@end
