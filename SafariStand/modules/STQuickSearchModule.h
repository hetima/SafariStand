//
//  STQuickSearchModule.h
//  SafariStand

#import <Foundation/Foundation.h>
#import "HTQuerySeed.h"

#define kDefaultSeedShortcut @"default"
#define STQSToolbarIdentifier @"com.hetima.SafariStand.QSToolbar"


@interface STQuickSearchModule : STCModule <HTQuerySeedsBinder>

@property(nonatomic,retain)NSMutableArray* querySeeds;
@property(nonatomic,retain)NSArray* defaultQuerySeeds;
@property(nonatomic,retain)NSMutableArray* searchItLaterStrings;
+ (STQuickSearchModule *)si;
+(int)tabPolicy;


-(void)showSearchComplViewForLocationFieldEditor:(id)textView;

-(HTQuerySeed*)querySeedForShortcut:(NSString*)inStr;
-(HTQuerySeed*)querySeedForUUID:(NSString*)uuid;
-(void)sendQuerySeed:(HTQuerySeed*)inSeed withSearchString:(NSString*)inStr policy:(int)policy;
-(void)sendQuerySeedUUID:(NSString*)uuid withSearchString:(NSString*)inStr policy:(int)policy;
-(void)sendGoogleQuerySeedWithSearchString:(NSString*)inStr  policy:(int)policy;
-(void)sendGoogleQuerySeedWithoutAddHistoryWithSearchString:(NSString*)inStr  policy:(int)policy;
-(void)sendGoogleImageQuerySeedWithoutAddHistoryWithSearchString:(NSString*)inStr  policy:(int)policy;
-(void)sendDefaultQuerySeedWithSearchString:(NSString*)inStr  policy:(int)policy;

-(void)setupContextMenu:(NSMenu*)menu;
-(NSMenu*)standardQuickSearchMenuWithSearchString:(NSString*)searchString;
-(NSMenu*)insertQuickSearchMenuItemsToMenu:(NSMenu*)menu withSelector:(SEL)sel target:(id)target;
@end


@interface STQuickSearchModule (DataIo)
-(NSArray*)enabledQuerySeeds;
-(void)saveToStorage;
-(void)loadFromStorage;

-(id)querySeedsRawData;
-(void)loadSearchItLaterStringDictionaries:(NSArray*)ary;
-(void)loadQuerySeedDictionaries:(NSArray*)ary;
-(void)importOldSetting;
@end


@interface STQuickSearchModule (STQuickSearchModule_SearchItLater)
-(NSMutableDictionary*)searchItLaterForString:(NSString*)str;
-(NSMutableDictionary*)existingSearchItLaterForString:(NSString*)str;

-(NSMutableDictionary*)addSearchItLaterString:(NSString*)inStr;
-(void)removeSearchItLaterString:(NSString*)inStr;
@end


@interface STQuickSearchModule (QSToolbar)
- (NSToolbarItem *)quickSearchToolbarItemWillBeInsertedIntoToolbar:(BOOL)flag;
-(void)quickSearchToolbarPopupWithEvent:(NSEvent*)event forView:(NSButton*)view;

@end

@interface STQuickSearchModule (STQuickSearchModule_Completion)
-(void)setupCompletionCtl;
-(HTQuerySeed*)seedForLocationText:(NSString*)inStr;
@end


extern STQuickSearchModule* quickSearchModule;
