//
//  STQSToolbarSearchView.h
//  SafariStand
//

#import <Cocoa/Cocoa.h>

@class HTQuerySeed;

@interface STQSToolbarSearchView : NSSearchField <NSTextFieldDelegate>
@property (nonatomic,retain) NSButtonCell* originalSearchBtn;
@property(nonatomic, retain) HTQuerySeed* currentQS;

@end

@interface STQSToolbarSearchCell : NSSearchFieldCell

@end

@interface STQSToolbarSearchBtnCell : NSButtonCell


@end

