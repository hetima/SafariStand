//
//  STActionMessageModule.h
//  SafariStand


@import AppKit;


@interface STActionMessageModule : STCModule

- (NSMenuItem*)menuItemForBookmarkLeaf:(id)bookmarkLeaf;
- (BOOL)handleBookmakBarAction:(NSString*)url;

@end
