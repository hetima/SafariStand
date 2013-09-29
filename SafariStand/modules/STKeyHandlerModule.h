//
//  STKeyHandlerModule.h
//  SafariStand

#import <Foundation/Foundation.h>


@interface STKeyHandlerModule : STCModule {
    NSMenuItem* oneKeyNavigationMenuItem;
    
}
- (void)prefValue:(NSString*)key changed:(id)value;

//,.
-(void)setupOneKeyNavigationMenuItem;
-(void)insertOneKeyNavigationMenuItem;
-(void)removeOneKeyNavigationMenuItem;
@end
