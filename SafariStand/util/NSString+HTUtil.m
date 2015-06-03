//
//  NSString+HTUtil.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif


#import "NSString+HTUtil.h"


@implementation NSString (NSString_HTUtil)

+ (NSString*)stand_UUIDStringWithFormat:(NSString*)ptn
{
    // Create CFUUID
    CFUUIDRef   uuid=CFUUIDCreate(NULL);
    CFStringRef uuidStrRef=CFUUIDCreateString(NULL, uuid);
    
    NSString* result=[[NSString alloc]initWithFormat:ptn, uuidStrRef];

    CFRelease(uuid);
    CFRelease(uuidStrRef);
    
    return result;
    
}


- (NSString*)stand_scapeWithEncoding:(NSStringEncoding)enco
{
    CFStringRef cfString=CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                            (CFStringRef)self,
                                                            NULL,
                                                            (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                            CFStringConvertNSStringEncodingToEncoding(enco));
    NSString *result = CFBridgingRelease(cfString);
    return result;
}


- (NSArray*)stand_arrayWithStandardSeparation
{
    if ([self length]==0)return nil;
    NSArray* ary=[self componentsSeparatedByString:@","];
                  //componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" ,"]];
    NSMutableArray* result=[NSMutableArray arrayWithCapacity:[ary count]];
    
    for (NSString* str in ary) {
        NSString* trim=[str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([trim length]>0) {
            [result addObject:trim];
        }
    }
    return result;
}


- (NSString*)stand_moderatedStringWithin:(NSInteger)max
{
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


+ (NSString *)stand_fileSizeStringFromSize:(uint64_t)siz
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


+ (NSString *)stand_verboseFileSizeStringFromSize:(uint64_t)siz
{
    NSString* shortStr=[NSString stand_fileSizeStringFromSize:siz];
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [formatter setGroupingSeparator:@","];
    [formatter setGroupingSize:3];
    NSString* longStr=[formatter stringFromNumber:[NSNumber numberWithUnsignedLongLong:siz]];
    
    NSString* result=[NSString stringWithFormat:@"%@ (%@ bytes)",shortStr,longStr];
    return result;
}

+ (NSString *)stand_timeStringFromSecs:(NSInteger)secs
{
    long h=secs/(60*60);
    secs-=(h*60*60);
    long min=secs/60;
    long sec=secs%60;
    
    if (h>0) {
        return([NSString stringWithFormat:@"%lih%lim", h, min]);
    }else if (min>0) {
        return([NSString stringWithFormat:@"%lim%lis", min, sec]);
    }

    return([NSString stringWithFormat:@"%lis", sec]);
}

- (NSURL*)stand_httpOrFileURL
{
    NSURL* result=[NSURL URLWithString:self];
    NSString* scheme=[result scheme];
    if ([scheme isEqualToString:@"http"]||[scheme isEqualToString:@"https"]||[scheme isEqualToString:@"file"]) {
        return result;
    }
    
    return nil;
}


- (NSString*)stand_revisionFromVersionString
{
    NSString* revision=nil;
    NSArray* revisionArray=[self componentsSeparatedByString:@"."];
    
    if ([revisionArray count]>1) {
        revision=[NSString stringWithFormat:@"%@.%@", revisionArray[0], revisionArray[1]];
    }else if ([revisionArray count]==1){
        revision=[NSString stringWithFormat:@"%@.0", revisionArray[0]];
    }
    
    return revision;

}

@end




@implementation HTFileSizeStringTransformer

- (id)transformedValue:(id)value
{
    uint64_t size=[value unsignedLongLongValue];
    NSString *result=[NSString stand_fileSizeStringFromSize:size];
    return result;
}

@end



@implementation HTVerboseFileSizeStringTransformer

- (id)transformedValue:(id)value
{
    uint64_t size=[value unsignedLongLongValue];
    NSString *result=[NSString stand_verboseFileSizeStringFromSize:size];
    return result;
}

@end

