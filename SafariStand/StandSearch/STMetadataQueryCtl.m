//
//  STMetadataQueryCtl.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import "SafariStand.h"
#import "STMetadataQueryCtl.h"

/*
 com.apple.safari.bookmark, com.apple.safari.history
 kMDItemDisplayName
 kMDItemURL
 
 com.apple.web-internet-location
 kMDItemDisplayName
 */


@implementation STMetadataQueryCtl {
    NSMetadataQuery* _query;
	NSPredicate*	_typeFilter;
}

+(STMetadataQueryCtl*)bookmarksSearchCtl
{
    NSString *path=[[NSHomeDirectory() stringByStandardizingPath]stringByAppendingPathComponent:
                    @"/Library/Caches/Metadata/Safari/Bookmarks"];
    STMetadataQueryCtl*ctl=[[STMetadataQueryCtl alloc]initWithContentType:@"com.apple.safari.bookmark" scope:path];
    ctl.title=@"Bookmark";
    return ctl;
}

+(STMetadataQueryCtl*)historySearchCtl
{
    NSString *path=[[NSHomeDirectory() stringByStandardizingPath]stringByAppendingPathComponent:
                    @"/Library/Caches/Metadata/Safari/History"];
    STMetadataQueryCtl*ctl=[[STMetadataQueryCtl alloc]initWithContentType:@"com.apple.safari.history" scope:path];
    ctl.title=@"History";
    return ctl;
}

- (void)dealloc
{
    LOG(@"query dealloc");
	[[NSNotificationCenter defaultCenter]removeObserver:self];
	[_query stopQuery];
}

- (id) initWithContentType:(NSString*)type scope:(NSString*)scope
{
	self = [super init];
	if (self != nil) {

		NSString*	fmt=[NSString stringWithFormat:@"(kMDItemContentType == '%@')", type];
		_typeFilter = [NSPredicate predicateWithFormat:fmt];
		_query = [[NSMetadataQuery alloc] init];
        if (!scope) {
            scope=NSMetadataQueryUserHomeScope;
        }
        
		[[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(queryNote:) name:nil object:_query];
		[_query setSearchScopes:[NSArray arrayWithObject:scope]];
		[_query setSortDescriptors:[NSArray arrayWithObject:
                        [[NSSortDescriptor alloc] initWithKey:(id)kMDItemContentModificationDate ascending:NO] ]];
		[_query setGroupingAttributes:nil];
		[_query setValueListAttributes:[NSArray arrayWithObjects:(id)kMDItemDisplayName, (id)kMDItemURL, nil]];
		//[_query setValueListAttributes:nil];
		[_query setDelegate:self];
        
	}
	return self;
}

- (NSUInteger)count
{
	return [_query resultCount];
}

- (id)objectAtIndex:(int)idx
{
	if([_query resultCount] > idx){
		return [_query resultAtIndex:idx];
	}
	return nil;
}

- (id)valueForAttribute:(NSString *)key
{
	if([key isEqualToString:(NSString*)kMDItemDisplayName]){
        NSUInteger	count=[self count];
        NSString* fmt;
        if(count==0){
            return self.title;
        }else if(count >= 10000){
            fmt=@"%@ ( over 10000 results )";
        }else{
            fmt=@"%@ ( %d results )";
        }
        return [NSString stringWithFormat:fmt, self.title, count ];
	}
	return @"";
}

- (NSMetadataQuery *)query
{
    return _query;
}



#pragma mark - search

- (void)startMetaDataSearch:(NSString*)inStr searchContent:(BOOL)searchContent
{		
	[_query stopQuery]; 
	//NSString* _searchKey=[NSString stringWithString:inStr];
    
    NSArray* words=[inStr componentsSeparatedByString:@" "];
    NSMutableArray* wordPeris=[NSMutableArray arrayWithCapacity:[words count]+2];
    [wordPeris addObject:_typeFilter];
    for (NSString* oneWord in words) {
        if ([oneWord length]) {
            NSString* word=[@"*" stringByAppendingString:[oneWord stringByAppendingString:@"*"]];
            //NSPredicate* p=[NSPredicate predicateWithFormat:@"((kMDItemDisplayName like[cd] %@) || (kMDItemURL like[cd] %@) || (kMDItemTextContent like[cd] %@))", word, word, word];
            //NSPredicate* p=[NSPredicate predicateWithFormat:@"((kMDItemDisplayName like[cdw] %@) || (kMDItemURL like[cdw] %@) || (kMDItemTextContent like[cdw] %@))", word, word, word];
            NSPredicate* p=[NSPredicate predicateWithFormat:@"((kMDItemDisplayName like[cd] %@) || (kMDItemURL like[cd] %@))", word, word];

            if(p) [wordPeris addObject:p];
        }
    }
    NSPredicate* excludePeri=[NSPredicate predicateWithFormat:@"!(kMDItemURL BEGINSWITH \"s\")"];
    [wordPeris addObject:excludePeri];
    NSPredicate *predicateToRun=[NSCompoundPredicate andPredicateWithSubpredicates:wordPeris];
    
	[_query setPredicate:predicateToRun];           
	[_query startQuery]; 
    
}


- (void)stopAndClearMetaDataSearch
{
    if (_query) {
		//clean up
		[[NSNotificationCenter defaultCenter]removeObserver:self name:nil object:_query];
		[_query stopQuery];
    }
    
	//make new
	NSMetadataQuery* newQuery = [[NSMetadataQuery alloc] init];
	if (newQuery) {
        
		//make new
		[[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(queryNote:) name:nil object:newQuery];
		[newQuery setSearchScopes:[_query searchScopes]];
		[newQuery setSortDescriptors:[_query sortDescriptors]];
		[newQuery setValueListAttributes:[_query valueListAttributes]];
		[newQuery setDelegate:self];
        
		//set
		_query=newQuery;
	}
	
}

- (void)_clearMDTree
{
	[self.delegate standMetaDataTreeUpdate:self];
}

- (void)_updateMDTree
{
	[self.delegate standMetaDataTreeUpdate:self];    
}

- (void)queryNote:(NSNotification *)note
{
    if ([[note name] isEqualToString:NSMetadataQueryDidStartGatheringNotification]) {
        
		[self _clearMDTree];
        
    } else if ([[note name] isEqualToString:NSMetadataQueryDidFinishGatheringNotification]) {
		[_query disableUpdates];
		[_query stopQuery];
		[self _updateMDTree];
		[_query enableUpdates];
    } else if ([[note name] isEqualToString:NSMetadataQueryGatheringProgressNotification]) {
		[_query disableUpdates];
		if([_query resultCount]>9999){
			[_query stopQuery];
			[self _updateMDTree];
		}
		[self _updateMDTree];
		[_query enableUpdates];
        
    } else if ([[note name] isEqualToString:NSMetadataQueryDidUpdateNotification]) {

		[self _updateMDTree];
        
    }
}

@end
