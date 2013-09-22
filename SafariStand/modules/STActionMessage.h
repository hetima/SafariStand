//
//  STActionMessage.h
//  SafariStand


#import <Foundation/Foundation.h>


@interface STActionMessage : STCModule

-(NSMenuItem*)menuItemForBookmarkLeaf:(id)bookmarkLeaf;
-(BOOL)handleBookmakBarAction:(NSString*)url;

@end
