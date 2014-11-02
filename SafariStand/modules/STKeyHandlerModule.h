//
//  STKeyHandlerModule.h
//  SafariStand

#import <Foundation/Foundation.h>


@interface STKeyHandlerModule : STCModule

- (void)prefValue:(NSString*)key changed:(id)value;

//,.
- (void)setupOneKeyNavigationMenuItem;
- (void)insertOneKeyNavigationMenuItem;
- (void)removeOneKeyNavigationMenuItem;

@end
