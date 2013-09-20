//
//  STActionMessage.h
//  SafariStand


#import <Foundation/Foundation.h>


@interface STActionMessage : STCModule {
@private
    IMP orig_addMenuItemForBookmark;
    IMP orig_goToBookmark;
}
@property(readonly) IMP orig_addMenuItemForBookmark,orig_goToBookmark;

-(NSMenuItem*)menuItemForBookmarkLeaf:(id)bookmarkLeaf;
-(BOOL)handleBookmakBarAction:(NSString*)url;

@end
