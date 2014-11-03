//
//  STSearchItLaterViewCtl.h
//  SafariStand


@import AppKit;


@class HTArrayController;

@interface STSearchItLaterViewCtl : NSViewController

@property (nonatomic, assign) id silBinder;
@property (nonatomic, strong) IBOutlet HTArrayController *silArrayCtl;

+ (STSearchItLaterViewCtl*)viewCtl;

- (id)safeArrangedObjectAtIndex:(NSInteger)idx;
@end



@interface STSearchItLaterTableView : NSTableView

@end
