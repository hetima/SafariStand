//
//  HTArrayController.h
//  SafriStand


@import AppKit;


@interface HTArrayController : NSArrayController {
    IBOutlet id delegate;
    IBOutlet NSTableView* oTableView;
    IBOutlet NSCollectionView* oCollectionView;
    NSString*   _pasteboardType;
}

- (void)add:(id)sender;
- (id)delegate;

@end
