//
//  HTQuerySeed.m
//  SafariStand

#if __has_feature(objc_arc)
#error This file must be compiled with -fno-objc_arc
#endif

#import "HTQuerySeed.h"
#import "NSString+HTUtil.h"

@implementation HTQuerySeed
@synthesize title,baseUrl,shortcut,encoding,method,posts,use,uuid,referrer;

+(id)querySeed
{
    NSDictionary* dict=[NSDictionary dictionaryWithObjectsAndKeys:
                        @"NewSearch",@"title",
                        @"http://",@"baseUrl",
                        @"",@"shortcut",
                        @"GET",@"method",
                        [NSNumber numberWithBool:YES],@"use",
                        [NSNumber numberWithUnsignedInteger:NSUTF8StringEncoding],@"encoding",
                        
                        [NSString HTUUIDStringWithFormat:@"%@"],@"uuid",
                        nil];
    
    HTQuerySeed* qs=[[[HTQuerySeed alloc]initWithDict:dict]autorelease];
    
    return qs;
}

- (id)initWithDict:(NSDictionary*)dic
{
    self = [super init];
    if (self) {
        // Initialization code here.
        self.title=[dic objectForKey:@"title"];
        self.baseUrl=[dic objectForKey:@"baseUrl"];
        self.shortcut=[dic objectForKey:@"shortcut"];
        self.encoding=[dic objectForKey:@"encoding"];
        self.method=[dic objectForKey:@"method"]; if(!method)self.method=@"GET";
        self.posts=[[dic objectForKey:@"posts"]mutableCopy]; if(!posts)self.posts=[NSMutableArray array];
        self.use=[dic objectForKey:@"use"]; if(!use)self.use=[NSNumber numberWithBool:YES];
        self.uuid=[dic objectForKey:@"uuid"]; if(!uuid)self.uuid=[NSString HTUUIDStringWithFormat:@"%@"];
        self.referrer=[dic objectForKey:@"referrer"]; if(!referrer)self.referrer=@"";
    }
    
    return self;
}

-(NSDictionary*)dictionaryData
{
    if(!title)self.title=@"";
    if(!baseUrl)self.baseUrl=@"";
    if(!shortcut)self.shortcut=@"";
    if(!method)self.method=@"GET";
    if(!encoding)self.encoding=[NSNumber numberWithUnsignedInteger:NSUTF8StringEncoding];
    if(!posts)self.posts=[NSMutableArray array];
    if(!use)self.use=[NSNumber numberWithBool:YES];
    if(!referrer)self.referrer=@"";
    if(!uuid)self.uuid=[NSString HTUUIDStringWithFormat:@"%@"];
    NSDictionary* result=[NSDictionary dictionaryWithObjectsAndKeys:
                          title,@"title",
                          baseUrl,@"baseUrl",
                          shortcut,@"shortcut",
                          encoding,@"encoding",
                          method,@"method",
                          posts,@"posts",
                          use,@"use",
                          referrer,@"referrer",
                          uuid,@"uuid",
                          nil];

    return result;
}

- (void)dealloc
{
    [super dealloc];
}

-(BOOL)shouldHiddenPostEdit
{
    if([self.method isEqualToString:@"POST"])return NO;
    return YES;
}

-(NSURLRequest*)requestWithLocationString:(NSString*)inStr{
    NSString* serachStr=nil;
    
    NSRange aRange=[inStr rangeOfString:@" "];
    if(aRange.length>0 && [inStr length]>aRange.location+1){
        serachStr=[inStr substringFromIndex:aRange.location+1];
    }
    return [self requestWithSearchString:serachStr];
}

-(NSURLRequest*)requestWithSearchString:(NSString*)inStr{
    if([self.baseUrl hasPrefix:@"quicksearch:"])return nil;
    NSStringEncoding enco=[self.encoding integerValue];
    inStr=[inStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    inStr=[inStr stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    //inStr=[inStr htEscapeWithEncoding:enco];
    
    NSString* inStrEscaped;
    if([self.baseUrl length]>6 && [self.baseUrl rangeOfString:@":/"].location!=NSNotFound){
        inStrEscaped=[inStr htEscapeWithEncoding:enco];
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
                v=[[v stringByReplacingOccurrencesOfString:@"%s" withString:inStr]htEscapeWithEncoding:enco];
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
