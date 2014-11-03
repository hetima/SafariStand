//
//  NSFileManager+SafariStand.h
//  SafariStand


@import Foundation;

@interface NSFileManager (SafariStand)

- (SEL)stand_selectorForPathWithUniqueFilenameForPath;
- (NSString*)stand_pathWithUniqueFilenameForPath:(NSString*)path;

@end
