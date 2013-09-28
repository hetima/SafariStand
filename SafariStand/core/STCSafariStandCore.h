//
//  STCSafariStandCore.h
//  SafariStand


#import <Foundation/Foundation.h>

#define kSafariStandPrefDomain @"com.hetima.SafariStand"

@interface STCSafariStandCore : NSObject

@property(nonatomic,readonly)NSMenu *standMenu;

@property(nonatomic,retain)NSString* revision;
@property (nonatomic,retain)NSString* currentVersionString;
@property (nonatomic,retain)NSString* latestVersionString;
@property (nonatomic,assign)BOOL missMatchAlertShown;

+ (STCSafariStandCore *)si;
+ (id)mi:(NSString*)moduleClassName;

-(void)startup;

-(id)registerModule:(NSString*)aClassName;
-(id)moduleForClassName:(NSString*)name;
-(void)sendMessage:(SEL)selector toAllModule:(id)sender;


-(void)setupStandMenu;
-(void)addItemToStandMenu:(NSMenuItem*)itm;


@end



@interface STCSafariStandCore (STCSafariStandCore_Toolbar)

-(void)registerToolbarIdentifier:(NSString*)identifier module:(id)obj;
@end


@interface STCSafariStandCore (STCSafariStandCore_Pref)
- (id)objectForKey:(NSString*)key;
- (BOOL)boolForKey:(NSString*)key;
- (BOOL)boolForKey:(NSString*)key  defaultValue:(BOOL)inValue;
- (id)mutableObjectForKey:(NSString*)key;
- (void)setObject:(id)value forKey:(NSString*)key;
- (void)setBool:(BOOL)value forKey:(NSString*)key;
- (BOOL)synchronize;

-(id)makeMutablePlistCopy:(id)plist;
-(NSMutableArray*)makeMutableArrayCopy:(NSArray*)array;
-(NSMutableDictionary*)makeMutableDictionaryCopy:(NSDictionary*)dict;


@end

