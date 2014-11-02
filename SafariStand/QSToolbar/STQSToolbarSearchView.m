//
//  STQSToolbarSearchView.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import "SafariStand.h"
#import "STQSToolbarSearchView.h"
#import "STQuickSearchModule.h"

#define kDefaultSearchButtonWidth 40
#define kSearchButtonMaxWidth 100
#define kSearchButtonMargin 8

@implementation STQSToolbarSearchBtnCell{
    NSSize _titleSize;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSRect drawRect=NSInsetRect(cellFrame, kSearchButtonMargin, 4);

    //NSRectFill(drawRect);
    NSBezierPath* path = [NSBezierPath bezierPathWithRoundedRect:drawRect
                                                         xRadius:3.0
                                                         yRadius:3.0];
    [[NSColor colorWithDeviceWhite:0.9 alpha:1.0] set];
    [path fill];
    [super drawInteriorWithFrame:drawRect inView:controlView];
}


- (NSSize)cellSize
{
    return _titleSize;
}


- (void)setTitle:(NSString *)aString
{
    [super setTitle:aString];
    
/*
    NSDictionary* attrs=[NSDictionary dictionaryWithObjectsAndKeys:
                         NSFontAttributeName, [NSFont systemFontOfSize:9.0],
                         NSForegroundColorAttributeName, [NSColor colorWithDeviceWhite:0.3 alpha:1.0],
                         nil];
*/
    //NSMutableAttributedString* attrStr=[[NSMutableAttributedString alloc]initWithString:aString attributes:attrs];
    NSMutableAttributedString* attrStr=[[self attributedTitle]mutableCopy];

    NSRange range=NSMakeRange(0, [attrStr length]);
    [attrStr addAttribute:NSForegroundColorAttributeName
                      value:[NSColor colorWithDeviceWhite:0.2 alpha:1.0]
                      range:range];
    [attrStr fixAttributesInRange:range];
    
    [self setAttributedTitle:attrStr];
    NSSize siz=[attrStr size];
    //NSSize siz=[[self attributedTitle]size];
    CGFloat width=siz.width+(kSearchButtonMargin*2)+6;
    width=ceil(width);
    if (width>kSearchButtonMaxWidth) {
        width=kSearchButtonMaxWidth;
    }
    _titleSize=NSMakeSize(width, 22);

}


@end


@implementation STQSToolbarSearchCell

- (NSRect)searchTextRectForBounds:(NSRect)rect
{
    //{18,3,w-37,16}
    NSRect result=[super searchTextRectForBounds:rect];
/*
    if ([[self stringValue]length]) {
        CGFloat diff=kDefaultSearchButtonWidth-result.origin.x+7;
        result.size.width-=diff;
        result.origin.x+=diff;
    }
*/

    return result;
}

- (NSRect)searchButtonRectForBounds:(NSRect)rect
{
    //{0,0,25,22}
    NSRect result=[super searchButtonRectForBounds:rect];
    //LOG(@"s=%@",NSStringFromRect(result));
/*    result=NSMakeRect(0, 0, 45, 22);
    if ([[self stringValue]length]) {
        result.size.width=kDefaultSearchButtonWidth;
    }
 
*/
    NSButtonCell* btn=[self searchButtonCell];
    /*
    NSSize siz=[[btn attributedTitle]size];
    CGFloat width=siz.width+(kSearchButtonMargin*2)+8;
    width=ceil(width);
    if (width>kSearchButtonMaxWidth) {
        width=kSearchButtonMaxWidth;
    }*/
    CGFloat width=[btn cellSize].width;
    if (width<22) {
        width=22;
    }
    result=NSMakeRect(0, 0, width, 22);
    return result;
}

@end


@implementation STQSToolbarSearchView



+ (void)load
{
//    [self setCellClass:[STQSToolbarSearchCell class]];
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) return nil;
    
    
    [self setAutoresizesSubviews:YES];
    self.originalSearchBtn=[[self cell]searchButtonCell];
    
    STQSToolbarSearchBtnCell* btnCell=[[STQSToolbarSearchBtnCell alloc]init];
    [btnCell setBezelStyle:NSRoundRectBezelStyle];
    [btnCell setBordered:NO];
    [btnCell setLineBreakMode:NSLineBreakByTruncatingTail];
    [btnCell setFont:[NSFont systemFontOfSize:10.0]];
    [btnCell setFocusRingType:NSFocusRingTypeNone];
    [[self cell] setSearchButtonCell:btnCell];
    [btnCell setAction:@selector(actToolbarSearchBtnClick:)];
    [btnCell setTarget:self];
    
    
    [[self cell]setScrollable:YES];
    //[self setFont:[NSFont systemFontOfSize:12.0]];
    
    //reset title
    [self setCurrentSeed:nil];
    
    [self setDelegate:self];
    //[self setAction:@selector(actToolbarSearch:)];
    [[self cell]setSendsSearchStringImmediately:NO];
    
    
    return self;
}


- (void)setCurrentSeed:(HTQuerySeed *)newQS
{
    if (newQS && self.currentQS==newQS) {
        return;
    }

    self.currentQS=newQS;
    NSString* cellTitle=[self.currentQS title];
    if (![cellTitle length]) {
        cellTitle=@"QS";
    }
    
    [[[self cell]searchButtonCell]setTitle:cellTitle];
    //[self layoutCurrentEditor];
    
    //[[self window]makeFirstResponder:nil];
    //[[self window]makeFirstResponder:self];
    
}


- (IBAction)actToolbarSearch:(id)sender
{
    HTQuerySeed* seed=self.currentQS;
    NSString* searchText=[self stringValue];
    if (![searchText length]) {
        return;
    }
    if(seed){
        [quickSearchModule sendQuerySeed:seed withSearchString:searchText  policy:STSafariWindowPolicyFromCurrentEvent()];
    }else{
        [quickSearchModule sendDefaultQuerySeedWithSearchString:searchText  policy:STSafariWindowPolicyFromCurrentEvent()];
    }

    //[[self window]makeFirstResponder:nil];
    
}


- (IBAction)actToolbarSearchBtnClick:(id)sender
{
    //reset to default
    self.currentQS=nil;
}


- (void)textDidChange:(NSNotification *)aNotification
{
    [super textDidChange:aNotification];
    NSString* inStr=[self stringValue];
    NSString* searchStr=nil;
    
    if ([inStr isEqualToString:@"  "]) {
        //reset seed
        [self setStringValue:@""];
        [self setCurrentSeed:nil];
        return;
    }
    

    HTQuerySeed* seed=nil;
    NSDictionary* seedInfo=[quickSearchModule seedInfoForLocationText:inStr];
    if (seedInfo) {
        seed=seedInfo[@"seed"];
        searchStr=seedInfo[@"searchStr"];
    }
    
    //LOG(@"%@/%@", [self stringValue], seed.title);
    if(seed){
        if (!searchStr) {
            searchStr=@"";
        }
        [self setCurrentSeed:seed];
        [self setStringValue:searchStr];
        

    }else{
        //if prev set
    }
    
}


- (BOOL)performKeyEquivalent:(NSEvent *)theEvent
{
	if([theEvent type]==NSKeyDown){
        //		NSLog(@"keyCode=%d",[theEvent keyCode]);
        if([theEvent keyCode]==36 || [theEvent keyCode]==76){	//ret,enter
            [self actToolbarSearch:self];
			return YES;
		}
	}
	return [super performKeyEquivalent:theEvent];
}


- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command
{
    if(command==@selector(insertNewline:)||command==@selector(insertNewlineIgnoringFieldEditor:)){	//return,enter
		[self actToolbarSearch:self];
        return YES;
	}else if(command==@selector(performKeyEquivalent:)){	//return,enter
		NSEvent *theEvent=[NSApp currentEvent];
		if([theEvent type]==NSKeyDown){
			if([theEvent keyCode]==36 || [theEvent keyCode]==76){	//ret,enter
				[self actToolbarSearch:self];
				return YES;
			}
		}
	}else if(command==@selector(deleteBackward:)){
        if (textView.string.length==0) {
            [self setCurrentSeed:nil];
        }
        
    }
    return NO;
}


@end
