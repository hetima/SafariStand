//
//  STSToolbarModule.h
//  SafariStand


#import <Foundation/Foundation.h>


@interface STSToolbarModule : STCModule {
    NSMutableDictionary* _toolbarItemClasses; //key=itemIdentifier, obj=object
    NSMutableArray* _toolbarIdentifiers;
}

- (NSToolbarItem *)_toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag;
- (NSArray*)toolbarIdentifiers;


-(void)registerToolbarIdentifier:(NSString*)identifier module:(id)obj;
-(id)toolBarItem:(NSString*)identifier label:(NSString*)label view:(NSView*)view;
-(id)simpleToolBarItem:(NSString*)identifier label:(NSString*)label action:(SEL)action iconName:(NSImage*)iconImage;

@end
