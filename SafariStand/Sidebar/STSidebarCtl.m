//
//  STSidebarCtl.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif


#import "STSidebarCtl.h"

@interface STSidebarCtl ()

@end

@implementation STSidebarCtl

+(STSidebarCtl*)viewCtl
{
    
    STSidebarCtl* result=[[STSidebarCtl alloc]initWithNibName:@"STSidebarCtl" bundle:
                                     [NSBundle bundleWithIdentifier:kSafariStandBundleID]];
    
    return result;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc
{
    LOG(@"STSidebarCtl d");
}

@end


@implementation STSidebarFrameView

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSFrameRectWithWidth([self bounds], 8.0);
}


- (void)dealloc
{
    LOG(@"STSidebarFrameView d");
}

@end