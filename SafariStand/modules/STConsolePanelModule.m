//
//  STConsolePanelModule.m
//  SafariStand


#import "SafariStand.h"
#import "STConsolePanelModule.h"


@implementation STConsolePanelModule {
    
    STConsolePanelCtl* _winCtl;
    NSMutableArray* _viewCtlPool;
}


-(id)initWithStand:(STCSafariStandCore*)core
{
    self = [super initWithStand:core];
    if (self) {
        //[self observePrefValue:];
        _winCtl=nil;
        _viewCtlPool=[[NSMutableArray alloc]initWithCapacity:8];
        
        NSMenuItem* itm=[[NSMenuItem alloc]initWithTitle:@"Console Panel" action:@selector(actShowConsolePanel:) keyEquivalent:@"k"];
        [itm setKeyEquivalentModifierMask:NSCommandKeyMask|NSAlternateKeyMask];
        [itm setTarget:self];
        [itm setTag:kMenuItemTagConsolePanel];
        [core addItemToStandMenu:itm];
    }
    return self;
}


- (void)dealloc
{

}


- (void)prefValue:(NSString*)key changed:(id)value
{
    //if([key isEqualToString:])
}


- (IBAction)actShowConsolePanel:(id)sender
{
    [self showConsolePanelAndSelectTab:nil];
}



- (void)showConsolePanelAndSelectTab:(NSString*)identifier
{
    if(!_winCtl){
        _winCtl=[[STConsolePanelCtl alloc]initWithWindowNibName:@"STConsolePanel"];
        _winCtl.window.titleVisibility=NSWindowTitleHidden;
        _winCtl.window.titlebarAppearsTransparent=YES;
        [[STCSafariStandCore si]sendMessage:@selector(stMessageConsolePanelLoaded:) toAllModule:self];
    }
    NSInteger tabToSelect=NSNotFound;
    if ([identifier length]>0) {
        tabToSelect=[_winCtl.oTabView indexOfTabViewItemWithIdentifier:identifier];
    }

    if (tabToSelect!=NSNotFound) {
        [_winCtl.oTabView selectTabViewItemAtIndex:tabToSelect];
    }else{
        identifier=[[_winCtl.oTabView selectedTabViewItem]identifier];
        
        if ([identifier length]<=0){
            [_winCtl.oTabView selectFirstTabViewItem:nil];
            identifier=[[_winCtl.oTabView selectedTabViewItem]identifier];
        }

    }
    
    [_winCtl.oToolbar setSelectedItemIdentifier:identifier];
    
    [_winCtl showWindow:self];
    
}


- (void)addViewController:(NSViewController*)viewCtl withIdentifier:(NSString*)identifier title:(NSString*)title icon:(NSImage*)icon
{
    [_viewCtlPool addObject:viewCtl];
    NSView *view=viewCtl.view;
    [self addPane:view withIdentifier:identifier title:title icon:icon];
}


- (void)addPane:(NSView*)view withIdentifier:(NSString*)identifier title:(NSString*)title icon:(NSImage*)icon
{
    [_winCtl addPane:view withIdentifier:identifier title:title icon:icon];
}


@end


@implementation STConsolePanelCtl


- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        
    }
    return self;
}


- (void)addPane:(NSView*)view withIdentifier:(NSString*)identifier title:(NSString*)title icon:(NSImage*)icon
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
    
    [toolbar insertItemWithItemIdentifier:identifier atIndex:[[toolbar items]count]-1];
    
}

@end