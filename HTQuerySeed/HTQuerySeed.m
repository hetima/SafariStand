//
//  HTQuerySeed.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import "HTQuerySeed.h"
#import "NSString+HTUtil.h"

@implementation HTQuerySeed

+ (id)querySeed
{
    NSDictionary* dict=[NSDictionary dictionaryWithObjectsAndKeys:
                        @"NewSearch",@"title",
                        @"http://",@"baseUrl",
                        @"",@"shortcut",
                        @"GET",@"method",
                        [NSNumber numberWithBool:YES],@"use",
                        [NSNumber numberWithUnsignedInteger:NSUTF8StringEncoding],@"encoding",
                        
                        [NSString stand_UUIDStringWithFormat:@"%@"],@"uuid",
                        nil];
    
    HTQuerySeed* qs=[[HTQuerySeed alloc]initWithDict:dict];
    
    return qs;
}

- (id)initWithDict:(NSDictionary*)dic
{
    self = [super init];
    if (!self) return nil;
    
    
    self.title=[dic objectForKey:@"title"];
    self.baseUrl=[dic objectForKey:@"baseUrl"];
    self.shortcut=[dic objectForKey:@"shortcut"];
    self.encoding=[dic objectForKey:@"encoding"];
    self.method=[dic objectForKey:@"method"]; if(!_method)self.method=@"GET";
    self.posts=[[dic objectForKey:@"posts"]mutableCopy]; if(!_posts)self.posts=[NSMutableArray array];
    self.use=[dic objectForKey:@"use"]; if(!_use)self.use=[NSNumber numberWithBool:YES];
    self.uuid=[dic objectForKey:@"uuid"]; if(!_uuid)self.uuid=[NSString stand_UUIDStringWithFormat:@"%@"];
    self.referrer=[dic objectForKey:@"referrer"]; if(!_referrer)self.referrer=@"";
    
    
    return self;
}

- (NSDictionary*)dictionaryData
{
    if(!_title)self.title=@"";
    if(!_baseUrl)self.baseUrl=@"";
    if(!_shortcut)self.shortcut=@"";
    if(!_method)self.method=@"GET";
    if(!_encoding)self.encoding=[NSNumber numberWithUnsignedInteger:NSUTF8StringEncoding];
    if(!_posts)self.posts=[NSMutableArray array];
    if(!_use)self.use=[NSNumber numberWithBool:YES];
    if(!_referrer)self.referrer=@"";
    if(!_uuid)self.uuid=[NSString stand_UUIDStringWithFormat:@"%@"];
    NSDictionary* result=[NSDictionary dictionaryWithObjectsAndKeys:
                          _title, @"title",
                          _baseUrl, @"baseUrl",
                          _shortcut, @"shortcut",
                          _encoding, @"encoding",
                          _method, @"method",
                          _posts, @"posts",
                          _use, @"use",
                          _referrer, @"referrer",
                          _uuid, @"uuid",
                          nil];

    return result;
}


- (void)dealloc
{

}


- (BOOL)shouldHiddenPostEdit
{
    if([self.method isEqualToString:@"POST"])return NO;
    return YES;
}


- (NSURLRequest*)requestWithLocationString:(NSString*)inStr
{
    NSString* serachStr=nil;
    
    NSRange aRange=[inStr rangeOfString:@" "];
    if(aRange.length>0 && [inStr length]>aRange.location+1){
        serachStr=[inStr substringFromIndex:aRange.location+1];
    }
    return [self requestWithSearchString:serachStr];
}


- (NSURLRequest*)requestWithSearchString:(NSString*)inStr
{
    if([self.baseUrl hasPrefix:@"quicksearch:"])return nil;
    NSStringEncoding enco=[self.encoding integerValue];
    inStr=[inStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    inStr=[inStr stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    //inStr=[inStr stand_scapeWithEncoding:enco];
    
    NSString* inStrEscaped;
    if([self.baseUrl length]>6 && [self.baseUrl rangeOfString:@":/"].location!=NSNotFound){
        inStrEscaped=[inStr stand_scapeWithEncoding:enco];
    }else{
        inStrEscaped=inStr;
    }
    
    NSString* urlStr=[self.baseUrl stringByReplacingOccurrencesOfString:@"%s" withString:inStrEscaped];
    NSURL* url=[NSURL URLWithString:urlStr];
    
    NSMutableURLRequest* req=[NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:self.method];
    
    if(self.referrer && [self.referrer hasPrefix:@"http:/"]){
        [req setValue:self.referrer forHTTPHeaderField:@"Referer"];
    }

    if([self.method isEqualToString:@"POST"]){
        NSMutableString* bodyStr=[NSMutableString string];
        for (NSDictionary* one in self.posts) {
            NSString* k=[one objectForKey:@"key"];
            NSString* v=[one objectForKey:@"val"];
            if(!k || [k length]<=0 || [k hasPrefix:@"="])continue;
            [bodyStr appendString:k];
            [bodyStr appendString:@"="];
            if(v){
                v=[[v stringByReplacingOccurrencesOfString:@"%s" withString:inStr]stand_scapeWithEncoding:enco];
                if(v)[bodyStr appendString:v];
            }
            [bodyStr appendString:@"&"];
        }
        if([bodyStr length]>2){
            [bodyStr deleteCharactersInRange:NSMakeRange([bodyStr length]-1, 1)];
            [req setHTTPBody:[bodyStr dataUsingEncoding:enco allowLossyConversion:YES]];
        }
    }
    return req;
}


@end


@implementation HTMethodIsNotPOSTValueTransformer

- (id)transformedValue:(id)value
{
    if([value isEqual:@"POST"])return [NSNumber numberWithBool:NO];
    return [NSNumber numberWithBool:YES];


}

@end
