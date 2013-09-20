//
//  STSearchItLaterWinCtl.h
//  SafariStand


#import <Cocoa/Cocoa.h>


@class HTArrayController;
@interface STSearchItLaterWinCtl : NSWindowController {
    id silBinder;
    
    IBOutlet HTArrayController *silArrayCtl;
}
@property(nonatomic,assign)id silBinder;

+ (void)showSearchItLaterWindow;

-(id)safeArrangedObjectAtIndex:(NSInteger)idx;
@end




@interface STSearchItLaterTableView : NSTableView {
    
    
    
}

@end
