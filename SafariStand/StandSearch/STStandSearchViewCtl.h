//
//  STStandSearchViewCtl.h
//  SafariStand



#import <Cocoa/Cocoa.h>

enum{
    SSModeHistorySearch=0,
    SSModeBookmarksSearch=1
};


@class STMetadataQueryCtl;
@interface STStandSearchViewCtl : NSViewController{

    STMetadataQueryCtl* bookmarksSearch;
    STMetadataQueryCtl* historySearch;
    NSTextField *searchField;
    NSOutlineView *oOutline;
    
    NSString* lastFindString;
    NSProgressIndicator *oIndicator;
    NSTextField *oStatusView;
    NSSegmentedControl *oSearchTypeSegment;
    NSMenu *oBMContextMenu;
    
    NSInteger mode;
}

@property(nonatomic,retain)STMetadataQueryCtl* bookmarksSearch;
@property(nonatomic,retain)STMetadataQueryCtl* historySearch;
@property(nonatomic,retain)NSString* lastFindString;
@property (assign) IBOutlet NSTextField *searchField;
@property (assign) IBOutlet NSOutlineView *oOutline;
@property (assign) IBOutlet NSProgressIndicator *oIndicator;
@property (assign) IBOutlet NSTextField *oStatusView;
@property (assign) IBOutlet NSSegmentedControl *oSearchTypeSegment;
@property (assign) IBOutlet NSMenu *oBMContextMenu;

+(STStandSearchViewCtl*)viewCtl;

- (IBAction)actSearchTypeSegment:(id)sender;
- (IBAction)actDoSearch:(id)sender;
- (IBAction)actJump:(id)sender;
- (IBAction)actJumpFromContextMenu:(id)sender;
- (IBAction)actCopyFromTable:(id)sender;

-(void)focusToOutlineView;
-(void)focusToSearchField;

-(id)selectedItem;
-(NSString*)selectedURLStringNeedsEncode:(BOOL)needEncode;
-(void)updateStatusViewForceShowCount:(BOOL)isCountMode;

@end

@interface STStandSearchOutlineView : NSOutlineView
{
    
}
- (id)selectedObject;

@end


@interface STStandSearchView : NSView{
    STStandSearchViewCtl *ctl;
}
@property (nonatomic, retain) STStandSearchViewCtl *ctl;

@end
