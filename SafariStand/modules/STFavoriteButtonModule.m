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
        
        if ([self favoriteButtonShouldHideTitle:slf]) {
            [slf setTitle:@" "];
        }else{
            NSAttributedString *attrString = [self attributedTitle:[slf title]];
            [slf setAttributedTitle:attrString];
        }

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
        STFavBtnIconLayer* layer=[STFavBtnIconLayer installedIconLayerInView:[slf controlView]];
        if ([layer contents]) {
            id btn=[slf controlView];
            if ([self favoriteButtonShouldHideTitle:btn]) {
                result.width=16+kFavoriteButtonImageLeftMargin+kFavoriteButtonImageLeftMargin;
            }else{
                result.width+=kFavoriteButtonLeftMargin;
            }
        }
        return result;
        
    }_WITHBLOCK_ADD;
    
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
    
    NSMenuItem* itm;
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    itm=[menu addItemWithTitle:@"Set Icon From Favicon" action:@selector(actUseIconFromBookmark:) keyEquivalent:@""];
    [itm setTarget:self];
    [itm setRepresentedObject:button];
    NSImage* image=STSafariWebBookmarkIcon(bookmark);
    if (image) {
        [itm setImage:image];
    }
    
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

