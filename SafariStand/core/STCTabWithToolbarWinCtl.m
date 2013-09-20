//
//  STCTabWithToolbarWinCtl.m
//  SafariStand


#import "NSObject+HTAssociatedObject.h"
#import "STCTabWithToolbarWinCtl.h"


@implementation STCTabWithToolbarWinCtl
@synthesize oToolbar, oTabView;
- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
        _identifiers=[[NSMutableArray alloc]initWithCapacity:4];
    }
    return self;
}


- (void)dealloc
{
    [_identifiers release];
    
    [super dealloc];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    id selectedId=[[oTabView selectedTabViewItem]identifier];
    
    [oToolbar setSelectedItemIdentifier:selectedId];
}

-(void)addIdentifier:(NSString*)identifier
{
    [_identifiers addObject:identifier];
}

- (IBAction)actToolbarClick:(id)sender {
    NSString* idn=[sender itemIdentifier];
    [oTabView selectTabViewItemWithIdentifier:idn];
    [oToolbar setSelectedItemIdentifier:idn];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    NSTabViewItem* tab=[oTabView tabViewItemAtIndex:[oTabView indexOfTabViewItemWithIdentifier:itemIdentifier]];
    NSImage* image=[tab htaoValueForKey:@"image"];
    NSString* label=[tab label];

    NSToolbarItem*	result=[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    [result setImage:image];
    [result setLabel:label];
    [result setPaletteLabel:label];
    [result setAction:@selector(actToolbarClick:)];
    [result setTarget:self];
   
   return [result autorelease];
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
    if(icon)[item htaoSetValue:icon forKey:@"image"];
    [tabView addTabViewItem:item];
    [item release];
    
    [toolbar insertItemWithItemIdentifier:identifier atIndex:[[toolbar items]count]];
    
}


@end
