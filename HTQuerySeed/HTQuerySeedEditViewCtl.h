//
//  HTQuerySeedEditViewCtl.h
//  SafariStand


#import <Cocoa/Cocoa.h>

@class HTArrayController;
@interface HTQuerySeedEditViewCtl : NSViewController {
//    NSMutableArray* querySeeds;
    id querySeedsBinder;
    IBOutlet HTArrayController *querySeedsArrayCtl;
    IBOutlet HTArrayController *postsArrayCtl;

    
}
@property(nonatomic,assign)id querySeedsBinder;
@property(nonatomic,assign)IBOutlet NSPopUpButton* addPopupBtn;

-(void)setupAddPopup:(NSArray*)defaultItems;
@end
