//
//  STTabStockerModule.h
//  SafariStand


@import AppKit;


@interface STTabStockerModule : STCModule <NSMenuDelegate>
@property (nonatomic, strong) NSMutableArray* closedTabs;
@property (nonatomic) NSInteger max;

@end

@interface STBrowserTabPersistentStateProxy : NSObject
@property (readonly) NSString* label;
@property (nonatomic, strong) id browserTabPersistentState;
@property (nonatomic, strong) NSDate* date;
@property (nonatomic, strong) NSImage* icon;

- (instancetype)initWithBrowserTabPersistentState:(id)state;
@end