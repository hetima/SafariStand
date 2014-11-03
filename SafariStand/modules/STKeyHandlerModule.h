//
//  STKeyHandlerModule.h
//  SafariStand

@import AppKit;


@interface STKeyHandlerModule : STCModule

- (void)prefValue:(NSString*)key changed:(id)value;

//,.
- (void)setupOneKeyNavigationMenuItem;
- (void)insertOneKeyNavigationMenuItem;
- (void)removeOneKeyNavigationMenuItem;

@end
