//
//  STMetadataQueryCtl.h
//  SafariStand


#import <Foundation/Foundation.h>

@protocol STMetadataQueryCtlDelegate;

@interface STMetadataQueryCtl : NSObject<NSMetadataQueryDelegate>

@property(nonatomic,retain) NSString* title;
@property(nonatomic,assign) id delegate;
@property(nonatomic,assign) BOOL isExpanded;

+ (STMetadataQueryCtl*)bookmarksSearchCtl;
+ (STMetadataQueryCtl*)historySearchCtl;

- (id) initWithContentType:(NSString*)type scope:(NSString*)scope;
- (NSUInteger)count;
- (id)objectAtIndex:(int)idx;
- (NSMetadataQuery *)query;
- (void)startMetaDataSearch:(NSString*)inStr searchContent:(BOOL)searchContent;
- (void)stopAndClearMetaDataSearch;
@end


@protocol STMetadataQueryCtlDelegate <NSObject>
@optional
-(void)standMetaDataTreeUpdate:(STMetadataQueryCtl*)ctl;

@end
