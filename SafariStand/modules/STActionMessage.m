//
//  STActionMessage.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import "SafariStand.h"
#import "STActionMessage.h"
#import "STSafariConnect.h"

#define kActionMessageScheme	@"action_message:"
#define kActionMessagePrefix	@"action_message"
@implementation STActionMessage


static STActionMessage* actionMessageModule;


static id (*origAM_addMenuItemForBookmark)(id, SEL, ...);
static id STAM_addMenuItemForBookmark_with(id self, SEL _cmd, id bookmark, void* tabLocation, id menu)
{
	id returnValue=nil;

    returnValue=[actionMessageModule menuItemForBookmarkLeaf:bookmark];
    if(returnValue){
        [menu addItem:returnValue];
        return returnValue;
    }
    
	return origAM_addMenuItemForBookmark(self, _cmd, bookmark, tabLocation, menu);
}

//BookmarkBarをクリックしたとき
static void (*orig_goToBookmark)(id, SEL);
static void ST_FavoriteButton_goToBookmark(id self, SEL _cmd)
{
	BOOL	hackHandled=NO;
	if([[NSUserDefaults standardUserDefaults]boolForKey:kpActionMessageEnabled] && [self respondsToSelector:@selector(bookmark)]){
		id	bookmark=objc_msgSend(self,@selector(bookmark));
		if(bookmark){
			NSString	*url=STWebBookmarkURLString(bookmark);
			hackHandled=[actionMessageModule handleBookmakBarAction:url];
		}
	}
	//横取りしてなかったら元を呼ぶ
	if(!hackHandled)
		orig_goToBookmark(self,_cmd);
}

-(id)initWithStand:(id)core
{
    self = [super initWithStand:core];
    if (self) {
        actionMessageModule=self;
        origAM_addMenuItemForBookmark = (id(*)(id, SEL, ...))RMF(
                                    NSClassFromString(@"BookmarksControllerObjC"),
                                    @selector(addMenuItemForBookmark:withTabPlacementHint:toMenu:),
                                    STAM_addMenuItemForBookmark_with);

        orig_goToBookmark = (void (*)(id, SEL))RMF(NSClassFromString(@"FavoriteButton"),
                                    @selector(_goToBookmark), ST_FavoriteButton_goToBookmark);

    }
    return self;
}


-(NSMenuItem*)menuItemForBookmarkLeaf:(id)bookmarkLeaf
{
	id returnValue=nil;
    
    int bookmarkType=STWebBookmarkType(bookmarkLeaf);
	if(bookmarkType==wbBookmark){
		//this is WebBookmarkLeaf
        NSString *url=STWebBookmarkURLString(bookmarkLeaf);
        
        if([url hasPrefix:kActionMessageScheme]){
            NSString*   menuTitle=STWebBookmarkTitle(bookmarkLeaf);

            returnValue=[[NSMenuItem alloc]initWithTitle:menuTitle action:@selector(actHandleBookmakItem:) keyEquivalent:@""];
			[returnValue setTarget:self];
			[returnValue setEnabled:YES];
            [returnValue setRepresentedObject:url];
		}
	}		
    
	return returnValue;    
}


-(void)handleActionMessage:(NSArray*)messages
{
    NSString* action=[[messages objectAtIndex:1]stringByAppendingString:@":"];
    SEL	selector=NSSelectorFromString(action);
    if(selector){
        [NSApp sendAction:selector to:nil from:self];
    }
}

//001 BookmakBar_Action
-(BOOL)handleBookmakBarAction:(NSString*)url
{
    if(![[NSUserDefaults standardUserDefaults]boolForKey:kpActionMessageEnabled])return NO;
    
	//foundRange.location==0;    unsigned int length
    NSArray* ary=[url componentsSeparatedByString:@":"];
    if([ary count]<=1) return NO;
    
	if([[ary objectAtIndex:0]isEqualToString:kActionMessagePrefix]){
        [self handleActionMessage:ary];
		return YES;
	}
	return NO;
}


//001 BookmakBar_Action
//ブックマークバーのクリック、ブックマークメニュー選択 IBAction
-(void)actHandleBookmakItem:(id)sender
{
    id url=nil;
    if([sender isKindOfClass:[NSString class]]){
        url=sender;
    }else{
        url=[sender representedObject];
    }
    if(url){
        [self handleBookmakBarAction:url];
    }
}


@end
