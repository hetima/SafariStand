//
//  STQSToolbarBaseView.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import "STQSToolbarBaseView.h"
#import "STQSToolbarSearchView.h"

@implementation STQSToolbarBaseView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
}

- (id)initWithQuickSearch:(STQuickSearchModule*)qs
{
    self = [super initWithFrame:NSMakeRect(0,0, kSTQSToolbarBaseWidth, 25)];
    if (self) {
        id view=[[STQSToolbarSearchView alloc] initWithFrame:NSMakeRect(0, 2, kSTQSToolbarBaseWidth, 22)];
        self.rightView=view;
        [self addSubview:view];
    }
    return self;
}

- (void)dealloc
{

}

@end

