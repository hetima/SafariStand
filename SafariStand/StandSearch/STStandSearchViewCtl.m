//
//  STStandSearchViewCtl.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import "SafariStand.h"
#import "STStandSearchViewCtl.h"
#import "STMetadataQueryCtl.h"



@implementation STStandSearchViewCtl {
    NSInteger mode;
}


//(1,0) > addSubview : view retained(n,2) > reverseOwnership(n+1==1,n-1==1)
+(STStandSearchViewCtl*)viewCtl
{
    
    STStandSearchViewCtl* result=[[STStandSearchViewCtl alloc]initWithNibName:@"STStandSearchViewCtl" bundle:
               [NSBundle bundleWithIdentifier:kSafariStandBundleID] ];

    
    return result;
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        ((STStandSearchView*)[self view]).ctl=nil;
        
        mode=SSModeHistorySearch;
    }
    return self;
}


-(void)awakeFromNib
{
    [self.oStatusView setStringValue:@""];
    
    self.bookmarksSearch=[STMetadataQueryCtl bookmarksSearchCtl];
    self.bookmarksSearch.delegate=self;
    self.bookmarksSearch.isExpanded=YES;
    self.historySearch=[STMetadataQueryCtl historySearchCtl];
    self.historySearch.delegate=self;
    self.historySearch.isExpanded=YES;
    
    
    [self.oSearchTypeSegment setImage:STSafariBundleHistoryImage() forSegment:SSModeHistorySearch];
    [self.oSearchTypeSegment setImage:STSafariBundleBookmarkImage() forSegment:SSModeBookmarksSearch];
    [self.oSearchTypeSegment setSelected:YES forSegment:mode];

    [self.oOutline reloadData];

}


- (void)dealloc
{

}



-(void)standMetaDataTreeUpdate:(STMetadataQueryCtl*)ctl
{
	BOOL running=NO;
	id query=[self.bookmarksSearch query];
	if([query isStarted] && ![query isStopped])running=YES;
	query=[self.historySearch query];
	if([query isStarted] && ![query isStopped])running=YES;
	
	if(running==NO){
        [self.oIndicator stopAnimation:nil];
        
    }
    
    if ((ctl==self.historySearch && mode==SSModeHistorySearch)||(ctl==self.bookmarksSearch && mode==SSModeBookmarksSearch)) {
        [self.oOutline reloadData];

    }

    [self updateStatusViewForceShowCount:YES];
    
}
- (void)clearSearch
{
	NSString* emptyStr=@"";
	self.lastFindString=emptyStr;

	[self.historySearch stopAndClearMetaDataSearch];
	[self.bookmarksSearch stopAndClearMetaDataSearch];
    
	[self.oIndicator stopAnimation:nil];

	[self.oOutline reloadData];
    [self updateStatusViewForceShowCount:YES];
}

- (void)startMetaDataSearch:(NSString*)inStr
{
    
	if([inStr length]>0 && ![inStr isEqualToString:self.lastFindString]){
		self.lastFindString=inStr;
		
		BOOL _searchContent=YES;
		[self.historySearch startMetaDataSearch:inStr searchContent:_searchContent];
		[self.bookmarksSearch startMetaDataSearch:inStr searchContent:_searchContent];
        
		[self.oIndicator startAnimation:nil];
	}
}


-(void)updateStatusViewForceShowCount:(BOOL)isCountMode
{
    
	NSString *url=[self selectedURLStringNeedsEncode:NO];
    
	if([url length]>0){
		[self.oStatusView setStringValue:url];
	}else{
		NSString	*statStr=@"";
        NSInteger	bmResult=[self.bookmarksSearch count];
        NSInteger	hisResult=[self.historySearch count];
        statStr=[NSString stringWithFormat:@"%ld Histories / %ld Bookmarks", hisResult, bmResult ];
		[self.oStatusView setStringValue:statStr];

	}
}

#pragma mark -------- TextField Delegate
//TextFieldにフォーカスが当たったままでTebleの操作などをするため

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command
{
	//LOG(@"%@",NSStringFromSelector(command));
    
	if(command==@selector(moveUp:)){	//↑
		NSUInteger row=[self.oOutline selectedRow];
		if(row==-1)row=[self.oOutline numberOfRows]-1;
		else	--row;
		[self.oOutline selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
		[self.oOutline scrollRowToVisible:row];
        
	}else if(command==@selector(moveDown:)){	//↓
		NSUInteger row=[self.oOutline selectedRow];
		if(row==-1)row=0;
		else	++row;
		if([self.oOutline numberOfRows]>row){
			[self.oOutline selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
			[self.oOutline scrollRowToVisible:row];
		}
        
	}else if(command==@selector(insertTab:)){
		[self focusToOutlineView];
	}else if(command==@selector(insertNewline:)){	//return,enter
		[self actJump:self];
        
	}else if(command==@selector(performKeyEquivalent:)){	//return,enter
		NSEvent *theEvent=[NSApp currentEvent];
        
		if([theEvent type]==NSKeyDown){
            //			NSLog(@"keyCode=%d",[theEvent keyCode]);
			if([theEvent keyCode]==36 || [theEvent keyCode]==76){	//ret,enter
				[self actJump:self];
				return YES;
			}
			return NO;
		}
	}else if(command==@selector(insertNewlineIgnoringFieldEditor:)){
        [self actJump:self];
        return YES;
        
	}else if(command==@selector(scrollToBeginningOfDocument:)){
		[self.oOutline selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
		[self.oOutline scrollRowToVisible:0];
	}else if(command==@selector(scrollPageDown:)){
		return YES;
	}else if(command==@selector(scrollPageUp:)){
	}else if(command==@selector(cancel:)||command==@selector(complete:)){	//esc
		if([[control stringValue]isEqualToString:@""]){
			//[[super window]orderOut:self];
		}else{
			[control setStringValue:@""];
		}
	}else if(command==@selector(cancelOperation:)){	//esc
        
        
	}else{
		return NO;
	}
	
	return YES;
}

//インクリメンタルサーチ
- (void)controlTextDidChange:(NSNotification *)aNotification
{
    
	//これまでの予約をキャンセル
	[NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(actDoSearch:) object:self];
    
	//新しい予約を入れる
	[self performSelector:@selector(actDoSearch:) withObject:self afterDelay:0.3];
    
}



-(void)focusToOutlineView
{
	[[self.oOutline window] makeFirstResponder:self.oOutline];
}

-(void)focusToSearchField
{
	[self.searchField selectText:self];
}


#pragma mark -
#pragma mark ---- outlineView Delegate ----
- (void)outlineViewItemDidExpand:(NSNotification *)notification
{
	id item=[[notification userInfo]objectForKey:@"NSObject"];
	if([item respondsToSelector:@selector(setIsExpanded:)]){
		[item setIsExpanded:YES];
	}
}

- (void)outlineViewItemDidCollapse:(NSNotification *)notification
{
	id item=[[notification userInfo]objectForKey:@"NSObject"];
	if([item respondsToSelector:@selector(setIsExpanded:)]){
		[item setIsExpanded:NO];
	}
}

//item object
- (id)outlineView:(NSOutlineView*)outlineView child:(int)index ofItem:(id)item
{
    if(self.oOutline != outlineView)return nil;
    if(item==nil){
        if(mode==SSModeBookmarksSearch)return [self.bookmarksSearch objectAtIndex:index];
        else return [self.historySearch objectAtIndex:index];
    }

    return nil;
}

// isItemExpandable
- (BOOL)outlineView:(NSOutlineView*)outlineView isItemExpandable:(id)item
{
    //if(oOutline!=outlineView)return NO;
    //if(item==historySearch || item==bookmarksSearch)return YES;
    return NO;
}

// item count
- (NSInteger)outlineView:(NSOutlineView*)outlineView numberOfChildrenOfItem:(id)item
{
    if(self.oOutline!=outlineView)return 0;

    if(item==nil){
        if(mode==SSModeBookmarksSearch)return [self.bookmarksSearch count];
        else return [self.historySearch count];
    }

    return 0;
}

// item value
- (id)outlineView:(NSOutlineView*)outlineView objectValueForTableColumn:(NSTableColumn*)column byItem:(id)item
{
    if(self.oOutline!=outlineView)return nil;
    
    id  identifier=[column identifier];
    
    if([identifier isEqualToString:@"t"]){
        //return [item valueForKey:(id)kMDItemFSName];
        return [item valueForAttribute:(id)kMDItemDisplayName];
    }else if([identifier isEqualToString:@"u"]){
        //return [item valueForKey:(id)kMDItemPath];
        return [item valueForAttribute:(id)kMDItemURL];//kMDItemURL
    }

    return nil;
}


- (void)outlineViewSelectionDidChange:(NSNotification *)aNotification
{
	[self updateStatusViewForceShowCount:NO];
}

- (NSMenu*)menuForOutlineView:(id)outlineView
{
	if(outlineView==self.oOutline){
		return self.oBMContextMenu;
	}
	return nil;
}


#pragma mark -

- (IBAction)actJump:(id)sender
{
	if(sender==self.oOutline || sender==self){
		NSString* urlStr=[self selectedURLStringNeedsEncode:YES];
        if([urlStr length]>0){
            NSURL* url=[NSURL URLWithString:urlStr];
            if(urlStr){
                STSafariGoToURLWithPolicy(url, STSafariWindowPolicyFromCurrentEvent());
            }
        }

	}
}


- (IBAction)actDoSearch:(id)sender
{
	//これまでの予約をキャンセル
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(actDoSearch:) object:self];

    NSString* str=[self.searchField stringValue];
	if([str length]==0){
		[self clearSearch];
	}else{
		[self startMetaDataSearch:str];
	}
}


-(id)selectedItem
{
    NSInteger idx=[self.oOutline selectedRow];
	if(idx>=0){
		return [self.oOutline itemAtRow:idx];
	}
	return nil;

}

-(NSString*)selectedURLStringNeedsEncode:(BOOL)needEncode
{
    NSString *url=nil;
	id item=[self selectedItem];
	if(item){
        url=[item valueForAttribute:(id)kMDItemURL];
        if(needEncode && [url length]>0){
        }

	}
	return url;
}


- (IBAction)actSearchTypeSegment:(id)sender
{
    mode=[self.oSearchTypeSegment selectedSegment];
	[self.oOutline reloadData];
    [self.oOutline deselectAll:self];
    [self.oOutline scrollToBeginningOfDocument:self];
}

- (IBAction)actCopyFromTable:(id)sender;
{
    NSString *url=[self selectedURLStringNeedsEncode:YES];
    if([url length]>0){
        NSPasteboard *pb=[NSPasteboard generalPasteboard];
        [pb clearContents];
        [pb setString:url forType:NSStringPboardType];
    }
}

- (IBAction)actJumpFromContextMenu:(id)sender
{

    NSString *URLStr=[self selectedURLStringNeedsEncode:YES];
    if([URLStr length]>0){
        NSInteger policy=[sender tag];
        STSafariGoToURLWithPolicy([NSURL URLWithString:URLStr], (int)policy);
    }
}

@end




@implementation STStandSearchOutlineView

- (id)selectedObject
{
	NSInteger idx=[self selectedRow];
	if(idx>=0){
		return [self itemAtRow:idx];
	}
	return nil;
}

- (void)awakeFromNib
{
	[self setDoubleAction:@selector(tableDoubleClicked)];
}

- (void)dealloc
{

}

- (void)tableDoubleClicked{
	if([[self delegate]respondsToSelector:@selector(actJump:)])
		[((STStandSearchViewCtl*)[self delegate])actJump:self];
}

- (void)keyDown:(NSEvent *)theEvent
{
	if([theEvent type]==NSKeyDown){
        //		NSLog(@"keyCode=%d",[theEvent keyCode]);
		if([theEvent keyCode]==36 || [theEvent keyCode]==76){	//ret,enter
			if([[self delegate]respondsToSelector:@selector(actJump:)])
				[((STStandSearchViewCtl*)[self delegate])actJump:self];
			return;
		}
	}
	[super keyDown:theEvent];
}

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent
{
	if([theEvent type]==NSKeyDown){
        //		NSLog(@"keyCode=%d",[theEvent keyCode]);
		if([theEvent keyCode]==36 || [theEvent keyCode]==76){	//ret,enter
			if([[self delegate]respondsToSelector:@selector(actJump:)])
				[((STStandSearchViewCtl*)[self delegate])actJump:self];
			
			return YES;
		}
	}
	return [super performKeyEquivalent:theEvent];
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	NSInteger row = [self rowAtPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]];
	if(![self isRowSelected:row])[self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
	if(row>=0){
		id delegateMenu=nil;
		//delegate
		if([[self delegate]respondsToSelector:@selector(menuForOutlineView:)]){
			delegateMenu=objc_msgSend([self delegate], @selector(menuForOutlineView:), self);
		}
		if(delegateMenu) return delegateMenu;
		return [self menu];
	}else{
		return nil;
	}
}

- (IBAction)copy:(id)sender
{
	if([[self delegate]respondsToSelector:@selector(actCopyFromTable:)]){
		objc_msgSend([self delegate], @selector(actCopyFromTable:), self);
	}
}

@end



@implementation STStandSearchView
@synthesize ctl;


- (void)dealloc {

}



@end