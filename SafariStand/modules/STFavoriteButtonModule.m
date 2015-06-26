//
//  STFavoriteButtonModule.m
//  SafariStand


#import "SafariStand.h"
#import "STFavoriteButtonModule.h"

/*
 ・FavoriteButton の layer の compositingFilter のせいでアイコン画像の描画がおかしくなる。
 ・compositingFilter を削除するとタイトル文字列の描画が薄くなる（タイトル文字列の色は controlTextColor だと思われる）。
 ・タイトル文字列の色を変えるとマウスオーバー時に反転しなくなる。
 ・マウスオーバー時文字色を適宜変更する必要がある。
 */


#define kFavoriteButtonLeftMargin 16
#define kFavoriteButtonImageLeftMargin 4
#define kSeparatorStr	@"-:-"

@implementation STFavoriteButtonModule {
    NSMutableDictionary* _iconPool;
    NSString* _iconDirectory;
    NSMutableArray* _hideTitleUUIDs;
    
    NSDictionary* _normalAttr;
    NSDictionary* _selectedAttr;
}


- (id)initWithStand:(id)core
{
    self = [super initWithStand:core];
    if (!self) return nil;
    
    
    _iconPool=[[NSMutableDictionary alloc]init];
    _iconDirectory=[STCSafariStandCore standLibraryPath:@"FavoriteButtonIcons"];
    
    [self loadHideTitleUUIDs];

    NSMutableParagraphStyle *style=[[NSMutableParagraphStyle alloc]init];
    [style setAlignment:NSRightTextAlignment];
    
    _normalAttr=@{NSFontAttributeName: [NSFont systemFontOfSize:11.0f],
                  NSForegroundColorAttributeName: [NSColor labelColor],
                  NSParagraphStyleAttributeName: style,
                  };
    
    _selectedAttr=@{NSFontAttributeName: [NSFont systemFontOfSize:11.0f],
                    NSForegroundColorAttributeName: [NSColor whiteColor],
                    NSParagraphStyleAttributeName: style,
                    };
    
    //add icon layer
    KZRMETHOD_SWIZZLING_("FavoriteButton", "setBookmark:", void, call, sel)
    ^(NSButton* slf, id arg1)
    {
        NSString* uuid=STSafariWebBookmarkUUID(arg1);
        NSImage* image=[self imageForUUID:uuid];
        if (image) {
            [self setIcon:image toButton:slf];
        }
        
        call(slf, sel, arg1);
        
        [self favoriteButton:slf didSetBookmark:arg1];
        

    }_WITHBLOCK;

    //text color
    KZRMETHOD_ADDING_("FavoriteButton", "RolloverTrackingButton", "mouseEnteredOrExited:", void, call_super, sel)
    ^(NSButton* slf, BOOL arg1)
    {
        call_super(slf, sel, arg1);

        if (![self favoriteButtonShouldHideTitle:slf]) {
            NSAttributedString *attrString=nil;
            if (arg1) {
                attrString=[self attributedSelectedTitle:[slf title]];
            }else{
                attrString=[self attributedTitle:[slf title]];
            }
            
            [slf setAttributedTitle:attrString];
        }
        
    }_WITHBLOCK_ADD;
    
    //context menu
    KZRMETHOD_SWIZZLING_("FavoriteButton", "menu", id, call, sel)
    ^id (NSButton* slf)
    {
        NSMenu* result=call(slf, sel);
        [self setupContextMenu:result forButton:slf];
        
        return result;
        
    }_WITHBLOCK;
    
    //button width
    KZRMETHOD_ADDING_("FavoriteButtonCell", "NSCell", "cellSize", NSSize, call_super, sel)
    ^NSSize (NSCell* slf){
        NSSize result=call_super(slf, sel);
        NSButton* btn=(NSButton*)[slf controlView];
        result.width=[self adjustCellWith:result.width forButton:btn];
        
        return result;
        
    }_WITHBLOCK_ADD;
    
    
    
    //Separator: drag can move window
    KZRMETHOD_ADDING_("FavoriteButton", "NSView", "mouseDownCanMoveWindow", BOOL, call_super, sel)
    ^BOOL (NSButton* slf){
        BOOL result=NO; //call_super(slf, sel);
        
        //separator
        if ([self isSeparatorButton:slf label:nil]) {
            if ([NSEvent modifierFlags] & (NSCommandKeyMask|NSAlternateKeyMask)) {
                return NO;
            }
            return YES;
        }
        return result;

    }_WITHBLOCK_ADD;
    
    KZRMETHOD_SWIZZLING_("FavoriteButton", "canDragHorizontally:fromMouseDown:", BOOL, call, sel)
    ^BOOL(id slf, BOOL arg1, id arg2)
    {
        if ([self isSeparatorButton:slf label:nil]) {
            if ([NSEvent modifierFlags] & (NSCommandKeyMask|NSAlternateKeyMask)) {
                return YES;
            }
            return NO;
        }
        BOOL result=call(slf, sel, arg1, arg2);
        return result;
    }_WITHBLOCK;
    
    //Separator: disable rename by long click
    KZRMETHOD_SWIZZLING_("FavoriteButton", "_didRecognizeLongPressGesture:", void, call, sel)
    ^(id slf, id arg1)
    {
        if ([self isSeparatorButton:slf label:nil]) {
            return;
        }
        
        call(slf, sel, arg1);
        
    }_WITHBLOCK;
    
    //Separator: disable drop into folder
    KZRMETHOD_SWIZZLING_("FavoriteButton", "_canAcceptDroppedBookmarkAtPoint:", BOOL, call, sel)
    ^BOOL(id slf, struct CGPoint arg1)
    {
        if ([self isSeparatorButton:slf label:nil]) {
            return NO;
        }
        BOOL result=call(slf, sel, arg1);
        return result;
    }_WITHBLOCK;

    //Separator: dont show contents menu
    KZRMETHOD_SWIZZLING_("FavoriteButton", "hasContentsMenu", BOOL, call, sel)
    ^BOOL(id slf)
    {
        if ([self isSeparatorButton:slf label:nil]) {
            return NO;
        }
        BOOL result=call(slf, sel);
        return result;
    }_WITHBLOCK;


    //デフォルトの NSCenterTextAlignment に変わってしまうのを防止
    //setAttributedTitle で paragraphStyle も変えているのでこれは不要
/*
    KZRMETHOD_ADDING_("FavoriteButtonCell", "NSCell", "setAlignment:", void, call_super, sel)
    ^ (NSCell* slf, NSTextAlignment arg1){
        call_super(slf, sel, NSRightTextAlignment);
        
    }_WITHBLOCK_ADD;
*/
    

    //compositingFilter に @"plusD" が設定されるとアイコン描画が変になる
    KZRMETHOD_SWIZZLING_("CALayer", "setCompositingFilter:", void, call, sel)
    ^(CALayer* slf, id  compositingFilter)
    {
        if ([[[slf delegate]className]isEqualToString:@"FavoriteButton"]) {
            compositingFilter=nil;
        }
        
        call(slf, sel, compositingFilter);
        
    }_WITHBLOCK;
    
    
    [self refreshFavoritesBarViews];
    
    return self;
}


- (void)dealloc
{
    
}


- (void)prefValue:(NSString*)key changed:(id)value
{
    //if([key isEqualToString:])
}

- (void)refreshFavoritesBarViews
{
    STSafariEnumerateBrowserWindow(^(NSWindow *window, NSWindowController *winCtl, BOOL *stop) {
        if ([winCtl respondsToSelector:@selector(favoritesBarView)]) {
            id favoritesBarView=((id(*)(id, SEL, ...))objc_msgSend)(winCtl, @selector(favoritesBarView));
            
            if ([favoritesBarView respondsToSelector:@selector(refreshButtons)]) {
                ((void(*)(id, SEL, ...))objc_msgSend)(favoritesBarView, @selector(refreshButtons));
            }
        }
    });
}


- (NSAttributedString*)attributedTitle:(NSString*)title
{
    NSAttributedString *attrString = [[NSAttributedString alloc]initWithString:title attributes:_normalAttr];
    return attrString;
}

- (NSAttributedString*)attributedSelectedTitle:(NSString*)title
{
    NSAttributedString *attrString = [[NSAttributedString alloc]initWithString:title attributes:_selectedAttr];
    return attrString;
}


- (BOOL)isSeparatorButton:(id)button label:(NSString**)outLabel
{
    if (outLabel) {
        *outLabel=nil;
    }
    if (![button respondsToSelector:@selector(bookmark)]) {
        return NO;
    }
    id bookmark=((id(*)(id, SEL, ...))objc_msgSend)(button, @selector(bookmark));
    int bookmarkType=STSafariWebBookmarkType(bookmark);
    if(bookmarkType==wbFolder){
        NSString* title=STSafariWebBookmarkTitle(bookmark);
        if([title hasPrefix:kSeparatorStr]){
            if (outLabel) {
                if([title length]>[kSeparatorStr length]){
                    *outLabel=[title substringFromIndex:[kSeparatorStr length]];
                }
            }
            return YES;
        }
    }
    return NO;
}


- (void)favoriteButton:(NSButton*)button didSetBookmark:(id)bookmark
{
    //separator
    NSString* label;
    if ([self isSeparatorButton:button label:&label]) {
        [button setToolTip:nil];
        [button setEnabled:NO];
        [self removeIconFromButton:button]; //保険
        
        if ([[button cell] respondsToSelector:@selector(setIndicator:)]) {
            ((void(*)(id, SEL, ...))objc_msgSend)([button cell], @selector(setIndicator:), 0);
        }
        /*
        if ([label length] && [label doubleValue]==0.0f) {
            NSAttributedString *attrString = [self attributedTitle:label];
            [button setAttributedTitle:attrString];
        }else{
            [button setTitle:@" "];
        }
        */
        [button setTitle:@" "];

    } else if ([self favoriteButtonShouldHideTitle:button]) {
        if (STSafariWebBookmarkType(bookmark)==wbFolder) {
            [button setToolTip:[button title]];
        }else{
            [button setToolTip:[NSString stringWithFormat:@"%@\n%@", [button title], [button toolTip]]];
        }
        [button setTitle:@" "];
    } else {
        NSAttributedString *attrString = [self attributedTitle:[button title]];
        [button setAttributedTitle:attrString];
    }
}

- (CGFloat)adjustCellWith:(CGFloat)width forButton:(NSButton*)btn
{
    CGFloat result=width;
    
    if (![btn respondsToSelector:@selector(bookmark)]) {
        return width;
    }
    
    //separator
    NSString* label;
    if ([self isSeparatorButton:btn label:&label]) {
        result=[label doubleValue];
        if (result<=0.0f) { //0 or text
            result=16;
        } else if (result<8.0f) {
            result=8.0f;
        }else if (result>9999.0f) {
            result=9999.0f;
        }
        return result;
    }

    
    //icon
    STFavBtnIconLayer* layer=[STFavBtnIconLayer installedIconLayerInView:btn];
    if ([layer contents]) {
        if ([self favoriteButtonShouldHideTitle:btn]) {
            result=16+kFavoriteButtonImageLeftMargin+kFavoriteButtonImageLeftMargin;
        }else{
            result=width+kFavoriteButtonLeftMargin;
        }
    }
    
    return result;
}


- (void)setIcon:(NSImage*)img toButton:(NSButton*)btn
{
    STFavBtnIconLayer* layer=[STFavBtnIconLayer installedIconLayerInView:btn];
    if (img) {
        if (!layer) {
            layer=[STFavBtnIconLayer layer];
            [[btn layer]addSublayer:layer];
        }
        layer.frame=NSMakeRect(kFavoriteButtonImageLeftMargin, 0, 16, 16);
        [[btn cell]setAlignment:NSRightTextAlignment];
    }
    
    [layer setContents:img];
}


- (void)removeIconFromButton:(id)btn
{
    STFavBtnIconLayer* layer=[STFavBtnIconLayer installedIconLayerInView:btn];
    if (layer) {
        [layer removeFromSuperlayer];
    }
}


- (BOOL)favoriteButtonShouldHideTitle:(id)favBtn
{
    NSString* label;
    if([self isSeparatorButton:favBtn label:&label]) {
        /*
         if ([label length] && [label doubleValue]==0.0f) {
            return NO;
        }
        */
        return YES;
    }
    
    if (![favBtn respondsToSelector:@selector(bookmark)]) {
        return NO;
    }
    id bookmark=((id(*)(id, SEL, ...))objc_msgSend)(favBtn, @selector(bookmark));
    
    
    NSString* uuid=STSafariWebBookmarkUUID(bookmark);
    if ([_hideTitleUUIDs containsObject:uuid] && [self imageForUUID:uuid]) {
        return YES;
    }
    
    return NO;
}

#pragma mark - menu action

- (void)setupContextMenu:(NSMenu*)menu forButton:(id)button
{
    if (![button respondsToSelector:@selector(bookmark)]) {
        return;
    }
    id bookmark=((id(*)(id, SEL, ...))objc_msgSend)(button, @selector(bookmark));
    NSString* uuid=STSafariWebBookmarkUUID(bookmark);
    
    BOOL hasIcon;
    if ([self imageForUUID:uuid]) {
        hasIcon=YES;
    }else{
        hasIcon=NO;
    }
    
    if([self isSeparatorButton:button label:nil]){
        return;
    }
    
    NSMenuItem* itm;
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    itm=[menu addItemWithTitle:@"Set Icon From Favicon" action:@selector(actUseIconFromBookmark:) keyEquivalent:@""];
    [itm setTarget:self];
    [itm setRepresentedObject:button];
    NSImage* image=STSafariWebBookmarkIcon(bookmark); //maybe not loaded
    if (image) {
        [itm setImage:image];
    }
    
    //retry
    __weak NSMenuItem* witm=itm;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [witm setImage:STSafariWebBookmarkIcon(bookmark)];
    });
    
    itm=[menu addItemWithTitle:@"Set Icon From Clipboard" action:@selector(actUseIconFromClipboard:) keyEquivalent:@""];
    if ([[NSPasteboard generalPasteboard]canReadItemWithDataConformingToTypes:@[@"public.image"]]) {
        [itm setTarget:self];
        [itm setRepresentedObject:button];
    }else{
        [itm setEnabled:NO];
    }
    
    [menu addItem:[NSMenuItem separatorItem]];

    itm=[menu addItemWithTitle:@"Hide Title" action:@selector(actHideTitle:) keyEquivalent:@""];
    if ([_hideTitleUUIDs containsObject:uuid]) {
        [itm setState:NSOnState];
    }
    if (hasIcon) {
        [itm setTarget:self];
        [itm setRepresentedObject:button];
    }else{
        [itm setEnabled:NO];
    }
    
    itm=[menu addItemWithTitle:@"Remove Icon" action:@selector(actRemoveIcon:) keyEquivalent:@""];
    if (hasIcon) {
        [itm setTarget:self];
        [itm setRepresentedObject:button];
    }else{
        [itm setEnabled:NO];
    }

}


- (void)actRemoveIcon:(NSMenuItem*)sender
{
    id favBtn=[sender representedObject];
    if (![favBtn respondsToSelector:@selector(bookmark)]) {
        return;
    }
    id bookmark=((id(*)(id, SEL, ...))objc_msgSend)(favBtn, @selector(bookmark));
    NSString* uuid=STSafariWebBookmarkUUID(bookmark);
    [self registerImage:nil forUUID:uuid];
    [self removeIconFromButton:favBtn];
    [_hideTitleUUIDs removeObject:uuid];


    [self refreshFavoritesBarViews];
}


- (void)actUseIconFromBookmark:(NSMenuItem*)sender
{
    id favBtn=[sender representedObject];
    if (![favBtn respondsToSelector:@selector(bookmark)]) {
        return;
    }
    id bookmark=((id(*)(id, SEL, ...))objc_msgSend)(favBtn, @selector(bookmark));
    NSString* uuid=STSafariWebBookmarkUUID(bookmark);
    
    // うまく取れないことがある
    NSImage* icon=STSafariWebBookmarkIcon(bookmark);
    if (icon) {
        [self registerImage:icon forUUID:uuid];
        [self setIcon:icon toButton:favBtn];
        [self refreshFavoritesBarViews];
    }
}


- (void)actUseIconFromClipboard:(NSMenuItem*)sender
{
    id favBtn=[sender representedObject];
    if (![favBtn respondsToSelector:@selector(bookmark)]) {
        return;
    }
    id bookmark=((id(*)(id, SEL, ...))objc_msgSend)(favBtn, @selector(bookmark));
    NSString* uuid=STSafariWebBookmarkUUID(bookmark);
    
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    NSArray* items=[pb readObjectsForClasses:@[[NSImage class]] options:@{}];
    NSImage* icon=[items firstObject];
    if (icon) {
        if (icon.size.width > 32.0) {
            icon=HTThumbnailImage(icon, 32.0);
        }
        
        [self registerImage:icon forUUID:uuid];
        [self setIcon:icon toButton:favBtn];
        [self refreshFavoritesBarViews];
    }
}


- (void)actHideTitle:(NSMenuItem*)sender
{
    id favBtn=[sender representedObject];
    if (![favBtn respondsToSelector:@selector(bookmark)]) {
        return;
    }
    id bookmark=((id(*)(id, SEL, ...))objc_msgSend)(favBtn, @selector(bookmark));
    NSString* uuid=STSafariWebBookmarkUUID(bookmark);
    
    if ([_hideTitleUUIDs containsObject:uuid]) {
        [_hideTitleUUIDs removeObject:uuid];
    }else{
        [_hideTitleUUIDs addObject:uuid];
    }
    
    [self saveHideTitleUUIDs];
    [self refreshFavoritesBarViews];
}

#pragma mark - file

- (void)loadHideTitleUUIDs
{
    NSString* path=[_iconDirectory stringByAppendingPathComponent:@"HideTitleUUIDs.plist"];
    if ([[NSFileManager defaultManager]fileExistsAtPath:path]) {
        _hideTitleUUIDs=[[NSMutableArray alloc]initWithContentsOfFile:path];
    }else{
        _hideTitleUUIDs=[[NSMutableArray alloc]init];
    }
}

- (void)saveHideTitleUUIDs
{
    NSString* path=[_iconDirectory stringByAppendingPathComponent:@"HideTitleUUIDs.plist"];
    [_hideTitleUUIDs writeToFile:path atomically:YES];
}


- (void)registerImage:(NSImage*)image forUUID:(NSString*)uuid
{
    if (!uuid || [uuid length]<=0) {
        return;
    }
    
    NSString* path=[self pathForUUID:uuid];
    
    if (!image) {
        [_iconPool setObject:[NSNull null] forKey:uuid];
        if ([[NSFileManager defaultManager]fileExistsAtPath:path]) {
            [[NSFileManager defaultManager]removeItemAtPath:path error:nil];
        }
        return;
    }else{
        CGImageRef imgRef = [image CGImageForProposedRect:NULL context:nil hints:nil];
        NSBitmapImageRep *newRep = [[NSBitmapImageRep alloc] initWithCGImage:imgRef];
        NSData *pngData = [newRep representationUsingType:NSPNGFileType properties:nil];
        [pngData writeToFile:path atomically:YES];

        [_iconPool setObject:image forKey:uuid];
    }
}


- (NSImage*)imageForUUID:(NSString*)uuid
{
    if (!uuid || [uuid length]<=0) {
        return nil;
    }
    
    NSImage* result=[_iconPool objectForKey:uuid];
    if (result) {
        return [result isKindOfClass:[NSImage class]]?result:nil;
    }else{
        NSString* path=[self pathForUUID:uuid];
        if ([[NSFileManager defaultManager]fileExistsAtPath:path]) {
            result=[[NSImage alloc]initWithContentsOfFile:path];
            [result setTemplate:YES];//
        }
        if (result) {
            [_iconPool setObject:result forKey:uuid];
        }else{
            [_iconPool setObject:[NSNull null] forKey:uuid];
        }
    }
    
    return result;
}


- (NSString*)pathForUUID:(NSString*)title
{
    title=[title stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
    return [[_iconDirectory stringByAppendingPathComponent:title]stringByAppendingPathExtension:@"png"];
}


@end



@implementation STFavBtnIconLayer

+ (id)installedIconLayerInView:(NSView*)view
{
    NSArray* sublayers=view.layer.sublayers;
    for (CALayer* layer in sublayers) {
        if ([layer isKindOfClass:[self class]]) {
            return layer;
        }
    }
    return nil;
}

@end

