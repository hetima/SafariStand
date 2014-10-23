//
//  NSObject+HTAssociatedObject.h
//  SafariStand


#import <Foundation/Foundation.h>


@interface NSObject (HTAssociatedObject)
- (void)htao_setValue:(id)value forKey:(id)key;
- (id)htao_valueForKey:(id)key;
- (NSMutableDictionary*)htao_dictionary;
@end