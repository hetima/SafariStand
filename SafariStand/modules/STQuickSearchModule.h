//
//  STQuickSearchModule.h
//  SafariStand

#import <Foundation/Foundation.h>
#import "HTQuerySeed.h"

#define kDefaultSeedShortcut @"default"
#define STQSToolbarIdentifier @"com.hetima.SafariStand.QSToolbar"

@class STConsolePanelModule;

@interface STQuickSearchModule : STCModule <HTQuerySeedsBinder>

@property(nonatomic,retain) NSMutableArray* querySeeds;
@property(nonatomic,retain) NSArray* defaultQuerySeeds;
@property(nonatomic,retain) NSMutableArray* searchItLaterStrings;

+ (STQuickSearchModule *)si;
+ (int)tabPolicy;


-(void)showSearchComplViewForLocationFieldEditor:(id)textView;

- (HTQuerySeed*)querySeedForShortcut:(NSString*)inStr;
- (HTQuerySeed*)querySeedForUUID:(NSString*)uuid;
- (void)sendQuerySeed:(HTQuerySeed*)inSeed withSearchString:(NSString*)inStr policy:(int)policy;
- (void)sendQuerySeedUUID:(NSString*)uuid withSearchString:(NSString*)inStr policy:(int)policy;
- (void)sendGoogleQuerySeedWithSearchString:(NSString*)inStr  policy:(int)policy;
- (void)sendGoogleQuerySeedWithoutAddHistoryWithSearchString:(NSString*)inStr  policy:(int)policy;
- (void)sendGoogleImageQuerySeedWithoutAddHistoryWithSearchString:(NSString*)inStr  policy:(int)policy;
- (void)sendDefaultQuerySeedWithSearchString:(NSString*)inStr  policy:(int)policy;

- (void)setupContextMenu:(NSMenu*)menu forceBottom:(BOOL)forceBottom;
- (NSMenu*)standardQuickSearchMenuWithSearchString:(NSString*)searchString;
- (NSInteger)insertQuickSearchMenuItemsToMenu:(NSMenu*)menu withSelector:(SEL)sel target:(id)target onTop:(BOOL)onTop;
@end


@interface STQuickSearchModule (DataIo)
- (NSArray*)enabledQuerySeeds;
- (void)saveToStorage;
- (void)loadFromStorage;

- (id)querySeedsRawData;
- (void)loadSearchItLaterStringDictionaries:(NSArray*)ary;
- (void)loadQuerySeedDictionaries:(NSArray*)ary;
- (void)importOldSetting;
@end


@interface STQuickSearchModule (STQuickSearchModule_SearchItLater)
- (NSMutableDictionary*)searchItLaterForString:(NSString*)str;
- (NSMutableDictionary*)existingSearchItLaterForString:(NSString*)str;

- (NSMutableDictionary*)addSearchItLaterString:(NSString*)inStr;
- (void)removeSearchItLaterString:(NSString*)inStr;
- (void)installSearchItLaterViewToConsolePanel;
@end


@interface STQuickSearchModule (QSToolbar)
- (NSToolbarItem *)quickSearchToolbarItemWillBeInsertedIntoToolbar:(BOOL)flag;
- (void)quickSearchToolbarPopupWithEvent:(NSEvent*)event forView:(NSButton*)view;

@end

@interface STQuickSearchModule (STQuickSearchModule_Completion)
- (void)setupCompletionCtl;
- (NSDictionary*)seedInfoForLocationText:(NSString*)inStr;

@end


extern STQuickSearchModule* quickSearchModule;

