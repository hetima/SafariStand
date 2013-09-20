//
//  NSObject+HTAssociatedObject.h
//  SafariStand


#import <Foundation/Foundation.h>


@interface NSObject (HTAssociatedObject)
- (void)htaoSetValue:(id)value forKey:(id)key;
- (id)htaoValueForKey:(id)key;
- (NSMutableDictionary*)htaoDictionary;
@end