//
//  STBookmarkSeparator.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import "SafariStand.h"
#import "STBookmarkSeparator.h"
#import "STSafariConnect.h"
#import "STConsolePanelModule.h"

#define kSeparatorStr	@"-:-"
#define kSeparatorLength	3

@implementation STBookmarkSeparator


- (id)initWithStand:(id)core
{
    self = [super initWithStand:core];
    if (!self) return nil;
    
    KZRMETHOD_SWIZZLING_(STSafariBookmarksControllerClass(),
                         "addMenuItemForBookmark:withTabPlacementHint:toMenu:",
                         id, call, sel)
    ^id (id slf, id bookmark, void* tabLocation, id menu)
    {
        id returnValue=nil;
        static STBookmarkSeparator* bookmarkSeparator;
        if(!bookmarkSeparator)bookmarkSeparator=[STCSafariStandCore mi:@"STBookmarkSeparator"];
        
        returnValue=[bookmarkSeparator menuItemForBookmarkLeaf:bookmark];
        if(returnValue){
            [menu addItem:returnValue];
            return returnValue;
        }
        
        returnValue=call(slf, sel, bookmark, tabLocation, menu);
        
        return returnValue;
    }_WITHBLOCK;

        //bookmark追加ポップアップメニューに区切り線フォルダを表示しない not works in Safari 8
        //-(id)[NewBookmarksController _addBookmarkFolder:toMenu:]
/*
    KZRMETHOD_SWIZZLING_("NewBookmarksController", "_addBookmarkFolder:toMenu:", id, call, sel)
    ^id (id slf, id bookmark, id menu)
    {
        NSString* title=STSafariWebBookmarkTitle(bookmark);
        if ([title hasPrefix:kSeparatorStr]) {
            return nil;
        }
        
        id result=call(slf, sel, bookmark, menu);
        return result;
    }_WITHBLOCK;
*/
    
    
    //SidebarBookmarkIcon
    KZRMETHOD_ADDING_
    ("BookmarksSidebarTableCellView", "NSTableCellView", "setObjectValue:",
                      void, call_super, sel)
    ^void (NSTableCellView* slf, id value){
        call_super(slf, sel, value);
        if ([[NSUserDefaults standardUserDefaults]boolForKey:kpShowIconOnSidebarBookmarkEnabled]) {
            NSImage* icon=nil;
            if ([value respondsToSelector:@selector(icon)]) {
                icon=objc_msgSend(value, @selector(icon));
            }
            if (icon) {
                NSImageView* imageView=[slf imageView];
                [imageView setImage:icon];
            }
        }
        
    }_WITHBLOCK_ADD;
    
    if ([[NSUserDefaults standardUserDefaults]boolForKey:kpShowIconOnSidebarBookmarkEnabled]) {
        [self updateSidebarBookmarkIcon];
    }
    [self observePrefValue:kpShowIconOnSidebarBookmarkEnabled];
    

    
    return self;
}


- (void)prefValue:(NSString*)key changed:(id)value
{
    if([key isEqualToString:kpShowIconOnSidebarBookmarkEnabled]){
        [self updateSidebarBookmarkIcon];
    }
}


#pragma mark - BookmarkSeparator

//セパレータにする
- (NSMenuItem*)menuItemForBookmarkLeaf:(id)bookmarkLeaf
{
	id returnValue=nil;
    
    int bookmarkType=STSafariWebBookmarkType(bookmarkLeaf);
    
	if(bookmarkType==wbFolder){
		//this is WebBookmarkLeaf
		NSString *menuTitle=nil;
		BOOL	isSeparator=NO;

        NSString*   title=STSafariWebBookmarkTitle(bookmarkLeaf);
        if([title hasPrefix:kSeparatorStr]){
            isSeparator=YES;
            if([title length]==kSeparatorLength)return [NSMenuItem separatorItem];
            else menuTitle=[title substringFromIndex:kSeparatorLength];
            
            if(!menuTitle)return [NSMenuItem separatorItem];
			if([menuTitle length]==1){
				if([menuTitle isEqualToString:@"."]){
					menuTitle=@" ";
				}
			}
            returnValue=[[NSMenuItem alloc]initWithTitle:menuTitle action:@selector(standdummyselector) keyEquivalent:@""];
			//returnValue=[menu addItemWithTitle:menuTitle action:@selector(standdummyselector) keyEquivalent:@""];
			[returnValue setTarget:nil];
			[returnValue setEnabled:NO];
			//[returnValue setRepresentedObject:nil];

		}
	}		
    
	return returnValue;    
}


#pragma mark - SidebarBookmarkIcon

- (void)_recursiveUpdateSidebarBookmarkIcon:(NSView*)v
{

    if([v isKindOfClass:NSClassFromString(@"BookmarksOutlineView")]) {
        NSOutlineView* outlineView=(NSOutlineView*)v;
        [outlineView reloadData];
        return;
    }
    
    for (NSView* sv in [v subviews]) {
        [self _recursiveUpdateSidebarBookmarkIcon:sv];
    }
}


- (void)updateSidebarBookmarkIcon
{
    STSafariEnumerateBrowserWindow(^(NSWindow *window, NSWindowController *winCtl, BOOL *stop) {
        NSView* view=[window contentView];
        [self _recursiveUpdateSidebarBookmarkIcon:view];
    });
    
    STConsolePanelModule* cp=[STCSafariStandCore mi:@"STConsolePanelModule"];
    NSView* view=[cp.bookmarksSidebarViewController view];
    if (view) {
        [self _recursiveUpdateSidebarBookmarkIcon:view];
    }

}

@end
