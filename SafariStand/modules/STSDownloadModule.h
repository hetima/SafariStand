//
//  STSDownloadModule.h
//  SafariStand


#import <Foundation/Foundation.h>


@interface STSDownloadModule : STCModule

@property(nonatomic, strong) NSMutableArray* advancedFilters;
@property(nonatomic, strong) NSString* basicExp;

- (NSWindow*)advancedSettingSheet;

- (NSString*)filteredExpressionForFileName:(NSString*)fileName url:(id)url;

- (void)saveToStorage;
- (void)loadFromStorage;

@end
