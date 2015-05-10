//
//  STCModule.h
//  SafariStand



@import Foundation;


@interface STCModule : NSObject

+ (BOOL)canRegisterModule;

- (id)initWithStand:(id)core;

- (void)prefValue:(NSString*)key changed:(id)value;
- (void)observePrefValue:(NSString*)key;
- (void)observeSafariPrefValue:(NSString*)key;

- (void)modulesDidFinishLoading:(id)core;
@end
