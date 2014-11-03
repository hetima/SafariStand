//
//  STSToolbarModule.h
//  SafariStand


@import AppKit;


@interface STSToolbarModule : STCModule

- (NSToolbarItem *)_toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag;
- (NSArray*)toolbarIdentifiers;


- (void)registerToolbarIdentifier:(NSString*)identifier module:(id)obj;
- (id)toolBarItem:(NSString*)identifier label:(NSString*)label view:(NSView*)view;
- (id)simpleToolBarItem:(NSString*)identifier label:(NSString*)label action:(SEL)action iconImage:(NSImage*)iconImage;

@end
