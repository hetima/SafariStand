//
//  NSFileManager+SafariStand.h
//  SafariStand


#import <Foundation/Foundation.h>

@interface NSFileManager (SafariStand)

- (SEL)stand_selectorForPathWithUniqueFilenameForPath;
- (NSString*)stand_pathWithUniqueFilenameForPath:(NSString*)path;

@end
