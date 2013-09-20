//
//  NSString+HTUtil.h
//  SafariStand


#import <Foundation/Foundation.h>


@interface NSString (NSString_HTUtil)
+(NSString*)HTUUIDStringWithFormat:(NSString*)ptn;
-(NSString*)htEscapeWithEncoding:(NSStringEncoding)enco;
-(NSArray*)htArrayWithStandardSeparation;
-(NSString*)htModeratedStringWithin:(NSInteger)max;
+ (NSString *)htFileSizeStringFromSize:(uint64_t)siz;
+ (NSString *)htVerboseFileSizeStringFromSize:(uint64_t)siz;

@end

@interface HTFileSizeStringTransformer : NSValueTransformer
@end

@interface HTVerboseFileSizeStringTransformer : NSValueTransformer
@end
