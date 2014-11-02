//
//  STActionMessageModule.h
//  SafariStand


#import <Foundation/Foundation.h>


@interface STActionMessageModule : STCModule

- (NSMenuItem*)menuItemForBookmarkLeaf:(id)bookmarkLeaf;
- (BOOL)handleBookmakBarAction:(NSString*)url;

@end
