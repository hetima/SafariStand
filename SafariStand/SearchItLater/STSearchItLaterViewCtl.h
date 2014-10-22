//
//  STSearchItLaterViewCtl.h
//  SafariStand


#import <Cocoa/Cocoa.h>


@class HTArrayController;

@interface STSearchItLaterViewCtl : NSViewController

@property(nonatomic, assign)id silBinder;
@property(nonatomic, strong)IBOutlet HTArrayController *silArrayCtl;

+ (STSearchItLaterViewCtl*)viewCtl;

-(id)safeArrangedObjectAtIndex:(NSInteger)idx;
@end



@interface STSearchItLaterTableView : NSTableView

@end
