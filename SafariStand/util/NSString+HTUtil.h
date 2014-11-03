//
//  NSString+HTUtil.h
//  SafariStand


@import Foundation;


@interface NSString (SafariStand_HTUtil)
+ (NSString*)stand_UUIDStringWithFormat:(NSString*)ptn;
- (NSString*)stand_scapeWithEncoding:(NSStringEncoding)enco;
- (NSArray*)stand_arrayWithStandardSeparation;
- (NSString*)stand_moderatedStringWithin:(NSInteger)max;
+ (NSString*)stand_fileSizeStringFromSize:(uint64_t)siz;
+ (NSString*)stand_verboseFileSizeStringFromSize:(uint64_t)siz;
- (NSURL*)stand_httpOrFileURL;
@end

@interface HTFileSizeStringTransformer : NSValueTransformer
@end

@interface HTVerboseFileSizeStringTransformer : NSValueTransformer
@end
