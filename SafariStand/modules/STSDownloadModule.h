//
//  STSDownloadModule.h
//  SafariStand


#import <Foundation/Foundation.h>


@interface STSDownloadModule : STCModule

@property(nonatomic,retain)NSMutableArray* advancedFilters;
@property(nonatomic,retain)NSString* basicExp;
-(NSWindow*)advancedSettingSheet;

-(NSString*)filteredExpressionForFileName:(NSString*)fileName url:(id)url;

-(void)saveToStorage;
-(void)loadFromStorage;

@end
