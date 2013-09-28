//
//  STStandSearchViewCtl.h
//  SafariStand



#import <Cocoa/Cocoa.h>

enum{
    SSModeHistorySearch=0,
    SSModeBookmarksSearch=1
};


@class STMetadataQueryCtl;
@interface STStandSearchViewCtl : NSViewController

@property (nonatomic,retain) STMetadataQueryCtl* bookmarksSearch;
@property (nonatomic,retain) STMetadataQueryCtl* historySearch;
@property (nonatomic,retain) NSString* lastFindString;

@property (nonatomic, weak) IBOutlet NSTextField *searchField;
@property (nonatomic, weak) IBOutlet NSOutlineView *oOutline;
@property (nonatomic, weak) IBOutlet NSProgressIndicator *oIndicator;
@property (nonatomic, weak) IBOutlet NSTextField *oStatusView;
@property (nonatomic, weak) IBOutlet NSSegmentedControl *oSearchTypeSegment;
@property (nonatomic, weak) IBOutlet NSMenu *oBMContextMenu;

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
