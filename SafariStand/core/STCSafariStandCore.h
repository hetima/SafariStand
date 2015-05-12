//
//  STCSafariStandCore.h
//  SafariStand


@import AppKit;


@interface STCSafariStandCore : NSObject


@property(nonatomic,readonly)NSMenu *standMenu;

@property(nonatomic, strong, readonly) NSString* safariRevision;
@property(nonatomic,retain) NSString* currentVersionString;
@property(nonatomic,retain) NSString* latestVersionString;
@property(nonatomic,assign) BOOL missMatchAlertShown;
@property(nonatomic, strong, readonly) NSUserDefaults* userDefaults;

+ (STCSafariStandCore *)si;
+ (id)mi:(NSString*)moduleClassName;
+ (NSString *)standLibraryPath:(NSString*)subPath;
+ (NSUserDefaults *)ud;

- (void)startup;

- (id)registerModule:(NSString*)aClassName;
- (id)moduleForClassName:(NSString*)name;
- (void)sendMessage:(SEL)selector toAllModule:(id)sender;


- (void)setupStandMenu;
- (void)addItemToStandMenu:(NSMenuItem*)itm;

@end



@interface STCSafariStandCore (STCSafariStandCore_Toolbar)

- (void)registerToolbarIdentifier:(NSString*)identifier module:(id)obj;

@end


@interface STCSafariStandCore (STCSafariStandCore_Pref)
- (id)objectForKey:(NSString*)key;
- (BOOL)boolForKey:(NSString*)key;
- (BOOL)boolForKey:(NSString*)key  defaultValue:(BOOL)inValue;
- (id)mutableObjectForKey:(NSString*)key;
- (void)setObject:(id)value forKey:(NSString*)key;
- (void)setBool:(BOOL)value forKey:(NSString*)key;
- (BOOL)synchronize;

- (id)makeMutablePlistCopy:(id)plist;
- (NSMutableArray*)makeMutableArrayCopy:(NSArray*)array;
- (NSMutableDictionary*)makeMutableDictionaryCopy:(NSDictionary*)dict;


@end

