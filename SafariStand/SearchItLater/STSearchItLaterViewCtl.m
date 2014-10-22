//
//  STSearchItLaterViewCtl.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import "SafariStand.h"
#import "STSearchItLaterViewCtl.h"

#import "STSafariConnect.h"
#import "STQuickSearchModule.h"
#import "HTArrayController.h"


@implementation STSearchItLaterViewCtl

+ (STSearchItLaterViewCtl*)viewCtl
{
    STSearchItLaterViewCtl* result;
    result=[[STSearchItLaterViewCtl alloc]initWithNibName:@"STSearchItLaterViewCtl" bundle:
                           [NSBundle bundleWithIdentifier:kSafariStandBundleID]];
    
    return result;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        LOG(@"STSearchItLaterViewCtl init");
        self.silBinder=[STQuickSearchModule si];
        [[STQuickSearchModule si] addObserver:self
                                   forKeyPath:@"searchItLaterStrings"
                                      options:(NSKeyValueObservingOptionNew)
                                      context:NULL];
    }
    return self;
}


- (void)viewDidLoad
{
    LOG(@"STSearchItLaterView load");
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object 
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqual:@"searchItLaterStrings"]) {
        [self willChangeValueForKey:@"searchItLaterStrings"];
        [self didChangeValueForKey:@"searchItLaterStrings"];
    }else{
        /*[super observeValueForKeyPath:keyPath
                         ofObject:object 
                           change:change 
                          context:context];*/
    }
}


- (void)dealloc
{
    [[STQuickSearchModule si] removeObserver:self forKeyPath:@"searchItLaterStrings"];
    LOG(@"STSearchItLaterViewCtl dealloc");
}


- (void)setSearchItLaterStrings:(NSMutableArray *)sil
{
    [self.silBinder setSearchItLaterStrings:sil];
}


- (NSMutableArray*)searchItLaterStrings
{
    return [self.silBinder searchItLaterStrings];
}


-(NSMenu*)menuForTableView:(NSTableView*)tableView index:(NSInteger)row
{
    NSMutableDictionary* itm=[self safeArrangedObjectAtIndex:row];
    if(itm){
        id m;
        NSMenu* actMenu=[[NSMenu alloc]initWithTitle:@""];
        
        [[STQuickSearchModule si]insertQuickSearchMenuItemsToMenu:actMenu withSelector:@selector(actQuickSearchMenuItem:) target:self onTop:YES];
        if([actMenu numberOfItems]>0){
            NSString* label=[NSString stringWithFormat:@"Search \"%@\"", [itm objectForKey:@"val"]];
            m=[[NSMenuItem alloc]initWithTitle:label action:nil keyEquivalent:@""];
            [actMenu insertItem:m atIndex:0];
            [actMenu addItem:[NSMenuItem separatorItem]];
        }
        
        m=[actMenu addItemWithTitle:LOCALIZE(@"Copy") action:@selector(copy:) keyEquivalent:@""];
        [m setTarget:tableView];
        m=[actMenu addItemWithTitle:LOCALIZE(@"Delete") action:@selector(delete:) keyEquivalent:@""];
        [m setTarget:tableView];
        
        return actMenu;
    }
    
    return nil;
}


- (IBAction)actQuickSearchMenuItem:(id)sender
{
    id seed=[sender representedObject];
    NSMutableDictionary* itm=[self safeArrangedObjectAtIndex:[self.silArrayCtl selectionIndex]];
    if(itm){
        NSString* selectedText=[itm objectForKey:@"val"];
        if([selectedText length]){
            [[STQuickSearchModule si]sendQuerySeed:seed withSearchString:selectedText
                            policy:[STQuickSearchModule tabPolicy]];
        }
    }
}


- (void)copy:(NSTableView*)sender
{
    NSMutableDictionary* itm=[self safeArrangedObjectAtIndex:[sender selectedRow]];
    if(itm){
        NSPasteboard*pb=[NSPasteboard generalPasteboard];
        [pb clearContents];
        [pb setString:[itm objectForKey:@"val"] forType:NSStringPboardType];
    }

}


- (IBAction)delete:(id)sender
{
    NSInteger idx=[sender selectedRow];
    NSMutableDictionary* itm=[self safeArrangedObjectAtIndex:idx];
    if(itm){
        [self.silArrayCtl removeObjectAtArrangedObjectIndex:idx];
    }
    //[oTreeController remove:sender];
}


- (IBAction)paste:(id)sender
{
    NSPasteboard*pb=[NSPasteboard generalPasteboard];
    NSString* str=[[pb stringForType:NSStringPboardType]htModeratedStringWithin:1024];

    if([str length]){
        id dic=[[STQuickSearchModule si]searchItLaterForString:str];
        [self.silArrayCtl setSelectedObjects:[NSArray arrayWithObject:dic]];
    }
}


- (id)safeArrangedObjectAtIndex:(NSInteger)idx
{
    NSArray* arrangedObjects=[self.silArrayCtl arrangedObjects];
    if(idx<0||[arrangedObjects count]<=idx)return nil;
    
    return[arrangedObjects objectAtIndex:idx];
}

@end




@implementation STSearchItLaterTableView

- (void)dealloc
{

}


- (IBAction)copy:(id)sender
{
    [(STSearchItLaterViewCtl*)[self delegate]copy:self];
}


- (IBAction)delete:(id)sender
{
    [(STSearchItLaterViewCtl*)[self delegate]delete:self];
}


- (IBAction)paste:(id)sender
{
    [(STSearchItLaterViewCtl*)[self delegate]paste:self];
}


- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if( [menuItem action] == @selector(cut:) ||
       [menuItem action] == @selector(copy:) ||
       [menuItem action] == @selector(delete:) )
    {
        return  [self numberOfSelectedRows] != 0;
    }
    
    if([menuItem action] == @selector(selectAll:)){
        return NO;
    }
    
    if([menuItem action] == @selector(paste:)){
        NSPasteboard*pb=[NSPasteboard generalPasteboard];
        return [pb canReadItemWithDataConformingToTypes:[NSArray arrayWithObject:NSPasteboardTypeString]];
    }
    return  YES;
}


- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	NSInteger row = [self rowAtPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]];

	NSMenu* menu=[(STSearchItLaterViewCtl*)[self delegate]menuForTableView:self index:row];
    if(menu){
        
        [self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    }
    return menu;
}


@end
