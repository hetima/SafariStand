//
//  NSString+HTUtil.m
//  SafariStand

#if __has_feature(objc_arc)
#error This file must be compiled with -fno-objc_arc
#endif


#import "NSString+HTUtil.h"


@implementation NSString (NSString_HTUtil)

+(NSString*)HTUUIDStringWithFormat:(NSString*)ptn
{
    // Create CFUUID
    CFUUIDRef   uuid=CFUUIDCreate(NULL);
    CFStringRef uuidStrRef=CFUUIDCreateString(NULL, uuid);
    
    NSString* result=[[NSString alloc]initWithFormat:ptn, uuidStrRef];

    CFRelease(uuid);
    CFRelease(uuidStrRef);
    
    return [result autorelease];
    
}

-(NSString*)htEscapeWithEncoding:(NSStringEncoding)enco{
    
    //return [self stringByAddingPercentEscapesUsingEncoding:enco];
    return [((NSString*)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                (CFStringRef)self,
                                                                NULL,
                                                                (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                CFStringConvertNSStringEncodingToEncoding(enco))) autorelease];
}


-(NSArray*)htArrayWithStandardSeparation{
    if ([self length]==0)return nil;
    NSArray* ary=[self componentsSeparatedByString:@","];
                  //componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" ,"]];
    NSMutableArray* result=[NSMutableArray arrayWithCapacity:[ary count]];
    
    for (NSString* str in ary) {
        str=[str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([str length]>0) {
            [result addObject:str];
        }
    }
    return result;
}

-(NSString*)htModeratedStringWithin:(NSInteger)max{
    NSString* result=nil;
    if ([self length]<1024*8) {
        NSArray* tmpAry=[[self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsSeparatedByString:@"\n"];
        if([tmpAry count]>0){
            result=[tmpAry objectAtIndex:0];
            result=[result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (max>0 && [result length]>max) {
                result=nil;
            }
        }
    }
    
    return result;
}

+ (NSString *)htFileSizeStringFromSize:(uint64_t)siz
{
    double floatSize = siz;
    if (siz<1023)
        return([NSString stringWithFormat:@"%lli byte",siz]);
    floatSize = floatSize / 1024;
    if (floatSize<1023)
        return([NSString stringWithFormat:@"%1.1f KB",floatSize]);
    floatSize = floatSize / 1024;
    if (floatSize<1023)
        return([NSString stringWithFormat:@"%1.1f MB",floatSize]);
    floatSize = floatSize / 1024;
    
    return([NSString stringWithFormat:@"%1.1f GB",floatSize]);
}

+ (NSString *)htVerboseFileSizeStringFromSize:(uint64_t)siz
{
    NSString* shortStr=[NSString htFileSizeStringFromSize:siz];
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [formatter setGroupingSeparator:@","];
    [formatter setGroupingSize:3];
    NSString* longStr=[formatter stringFromNumber:[NSNumber numberWithUnsignedLongLong:siz]];
    [formatter release];
    
    NSString* result=[NSString stringWithFormat:@"%@ (%@ bytes)",shortStr,longStr];
    return result;
}

@end




@implementation HTFileSizeStringTransformer

- (id)transformedValue:(id)value
{
    uint64_t size=[value unsignedLongLongValue];
    NSString *result=[NSString htFileSizeStringFromSize:size];
    return result;
}

@end

@implementation HTVerboseFileSizeStringTransformer

- (id)transformedValue:(id)value
{
    uint64_t size=[value unsignedLongLongValue];
    NSString *result=[NSString htVerboseFileSizeStringFromSize:size];
    return result;
}

@end

