//
//  STConsolePanelModule.m
//  SafariStand


#import "SafariStand.h"
#import "STConsolePanelModule.h"


@implementation STConsolePanelModule {
    
    STConsolePanelCtl* _winCtl;
}


-(id)initWithStand:(STCSafariStandCore*)core
{
    self = [super initWithStand:core];
    if (self) {
        //[self observePrefValue:];
        _winCtl=nil;
        
        NSMenuItem* itm=[[NSMenuItem alloc]initWithTitle:@"Console Panel" action:@selector(actShowConsolePanel:) keyEquivalent:@"k"];
        [itm setKeyEquivalentModifierMask:NSCommandKeyMask|NSAlternateKeyMask];
        [itm setTarget:self];
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


-(IBAction)actShowConsolePanel:(id)sender
{
    if(!_winCtl){
        _winCtl=[[STConsolePanelCtl alloc]initWithWindowNibName:@"STConsolePanel"];
        _winCtl.window.titleVisibility=NSWindowTitleHidden;;
        [[STCSafariStandCore si]sendMessage:@selector(stMessageConsolePanelLoaded:) toAllModule:self];
    }
    [_winCtl showWindow:self];
}


-(void)addPane:(NSView*)view withIdentifier:(NSString*)identifier title:(NSString*)title icon:(NSImage*)icon
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


@end