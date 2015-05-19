//
//  HTQuerySeedEditViewCtl.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import "SafariStand.h"
#import "HTQuerySeedEditViewCtl.h"
#import "HTQuerySeed.h"
#import "HTArrayController.h"


@implementation HTQuerySeedEditViewCtl

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (!self) return nil;
    
    
    return self;
}


- (void)dealloc
{

}


- (void)setQuerySeeds:(NSMutableArray *)qss
{
    [self.querySeedsBinder setQuerySeeds:qss];
}


-(NSMutableArray*)querySeeds
{
    return [self.querySeedsBinder querySeeds];
}


- (id)defaultObjecOfHTArrayController:(id)aryCtl
{
    if(aryCtl==querySeedsArrayCtl) return [HTQuerySeed querySeed];
    if(aryCtl==postsArrayCtl) return [NSMutableDictionary dictionaryWithObjectsAndKeys:@"key",@"key",@"value",@"val", nil];
    return nil;
}


- (IBAction)actQuerySeedPresetMenu:(id)sender
{
    NSDictionary* dic=[sender representedObject];
    HTQuerySeed* seed=[[HTQuerySeed alloc]initWithDict:dic];
    if (seed) {
        [querySeedsArrayCtl addObject:seed];
    }
}


- (void)menuNeedsUpdate:(NSMenu*)menu
{
    NSMenuItem* defauntMenuItem=[menu itemWithTag:1];
    if (![defauntMenuItem hasSubmenu]) {
        NSMenu* subMenu=[[NSMenu alloc]initWithTitle:@""];
        for (NSDictionary* dict in _defaultItems) {
            NSString* title=[dict objectForKey:@"title"];
            NSMenuItem* mi=[subMenu addItemWithTitle:title action:@selector(actQuerySeedPresetMenu:) keyEquivalent:@""];
            [mi setRepresentedObject:dict];
            [mi setTarget:self];
        }
        if ([subMenu numberOfItems]==0) {
            NSMenuItem* mi=[subMenu addItemWithTitle:@"Not Found" action:nil keyEquivalent:@""];
            [mi setEnabled:NO];
        }
        [defauntMenuItem setSubmenu:subMenu];
    }
    
    
    NSMenuItem* recentMenuItem=[menu itemWithTag:2];
    if ([recentMenuItem hasSubmenu]) {
        [recentMenuItem setSubmenu:nil];
    }
    NSArray* recentItems=STSafariQuickWebsiteSearchItems();
    NSMenu* subMenu=[[NSMenu alloc]initWithTitle:@""];
    for (NSDictionary* dict in recentItems) {
        NSString* title=[dict objectForKey:@"title"];
        NSMenuItem* mi=[subMenu addItemWithTitle:title action:@selector(actQuerySeedPresetMenu:) keyEquivalent:@""];
        [mi setRepresentedObject:dict];
        [mi setTarget:self];
    }
    if ([subMenu numberOfItems]==0) {
        NSMenuItem* mi=[subMenu addItemWithTitle:@"Not Found" action:nil keyEquivalent:@""];
        [mi setEnabled:NO];
    }
    [recentMenuItem setSubmenu:subMenu];
}

@end
