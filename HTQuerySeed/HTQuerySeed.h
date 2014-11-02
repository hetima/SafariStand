//
//  HTQuerySeed.h
//  SafariStand


#import <Foundation/Foundation.h>


@interface HTQuerySeed : NSObject

@property(nonatomic, strong) NSString* title;
@property(nonatomic, strong) NSString* baseUrl;
@property(nonatomic, strong) NSString* shortcut;
@property(nonatomic, strong) NSString* method;
@property(nonatomic, strong) NSNumber* encoding;
@property(nonatomic, strong) NSNumber* use;
@property(nonatomic, strong) NSString* referrer;
@property(nonatomic, strong) NSMutableArray* posts;
@property(nonatomic, strong) NSString* uuid;

+ (id)querySeed;
- (id)initWithDict:(NSDictionary*)dic;

- (NSDictionary*)dictionaryData;

- (NSURLRequest*)requestWithLocationString:(NSString*)inStr;
- (NSURLRequest*)requestWithSearchString:(NSString*)inStr;

@end


@protocol HTQuerySeedsBinder <NSObject>

- (NSMutableArray*)querySeeds;
- (void)setQuerySeeds:(NSMutableArray*)ary;
- (void)addQuerySeed:(HTQuerySeed*)qs;

@end


@interface HTMethodIsNotPOSTValueTransformer : NSValueTransformer

@end

