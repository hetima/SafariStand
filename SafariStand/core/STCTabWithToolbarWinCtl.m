//
//  STCTabWithToolbarWinCtl.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import "NSObject+HTAssociatedObject.h"
#import "STCTabWithToolbarWinCtl.h"


@implementation STCTabWithToolbarWinCtl


- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (!self) return nil;
    
    _identifiers=[[NSMutableArray alloc]initWithCapacity:4];

    return self;
}


- (void)windowDidLoad
{
    [super windowDidLoad];
    id selectedId=[[self.oTabView selectedTabViewItem]identifier];
    
    [self.oToolbar setSelectedItemIdentifier:selectedId];
}

-(void)addIdentifier:(NSString*)identifier
{
    [_identifiers addObject:identifier];
}

- (IBAction)actToolbarClick:(id)sender
{
    NSString* idn=[sender itemIdentifier];
    [self.oTabView selectTabViewItemWithIdentifier:idn];
    [self.oToolbar setSelectedItemIdentifier:idn];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    NSTabViewItem* tab=[self.oTabView tabViewItemAtIndex:[self.oTabView indexOfTabViewItemWithIdentifier:itemIdentifier]];
    NSImage* image=[tab htao_valueForKey:@"image"];
    NSString* label=[tab label];

    NSToolbarItem*	result=[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    [result setToolTip:label];
    [result setImage:image];
    [result setLabel:label];
    [result setPaletteLabel:label];
    [result setAction:@selector(actToolbarClick:)];
    [result setTarget:self];
   
   return result;
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
    return _identifiers;
}


-(void)addPane:(NSView*)view withIdentifier:(NSString*)identifier title:(NSString*)title icon:(NSImage*)icon
{
    [self window];
    [self addIdentifier:identifier];
    NSTabView* tabView=[self oTabView];
    NSToolbar* toolbar=[self oToolbar];
    
    NSTabViewItem* item=[[NSTabViewItem alloc]initWithIdentifier:identifier];
    [item setView:view];
    [item setLabel:title];
    if(icon)[item htao_setValue:icon forKey:@"image"];
    [tabView addTabViewItem:item];

    [toolbar insertItemWithItemIdentifier:identifier atIndex:[[toolbar items]count]];
    
}


@end
