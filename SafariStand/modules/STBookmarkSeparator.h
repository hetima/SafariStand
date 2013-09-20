//
//  STBookmarkSeparator.h
//  SafariStand



#import <Foundation/Foundation.h>


@interface STBookmarkSeparator : STCModule {
@private
    IMP orig_addMenuItemForBookmark;
}
@property(readonly)IMP orig_addMenuItemForBookmark;


-(NSMenuItem*)menuItemForBookmarkLeaf:(id)bookmarkLeaf;
@end
