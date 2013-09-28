//
//  HTQuerySeed.h
//  SafariStand


#import <Foundation/Foundation.h>


@interface HTQuerySeed : NSObject

@property(nonatomic,retain)NSString* title;
@property(nonatomic,retain)NSString* baseUrl;
@property(nonatomic,retain)NSString* shortcut;
@property(nonatomic,retain)NSString* method;
@property(nonatomic,retain)NSNumber* encoding;
@property(nonatomic,retain)NSNumber* use;
@property(nonatomic,retain)NSString* referrer;
@property(nonatomic,retain)NSMutableArray* posts;
@property(nonatomic,retain)NSString* uuid;

+ (id)querySeed;
- (id)initWithDict:(NSDictionary*)dic;

-(NSDictionary*)dictionaryData;

-(NSURLRequest*)requestWithLocationString:(NSString*)inStr;
-(NSURLRequest*)requestWithSearchString:(NSString*)inStr;

@end


@protocol HTQuerySeedsBinder <NSObject>

-(NSMutableArray*)querySeeds;
-(void)setQuerySeeds:(NSMutableArray*)ary;
-(void)addQuerySeed:(HTQuerySeed*)qs;

@end


@interface HTMethodIsNotPOSTValueTransformer : NSValueTransformer {
}
@end