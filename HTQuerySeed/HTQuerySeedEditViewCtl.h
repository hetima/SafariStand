//
//  HTQuerySeedEditViewCtl.h
//  SafariStand


@import AppKit;

@class HTArrayController;

@interface HTQuerySeedEditViewCtl : NSViewController {
    IBOutlet HTArrayController *querySeedsArrayCtl;
    IBOutlet HTArrayController *postsArrayCtl;
}

@property (nonatomic, assign) id querySeedsBinder;
@property (nonatomic, assign) IBOutlet NSPopUpButton* addPopupBtn;

-(void)setupAddPopup:(NSArray*)defaultItems;

@end
