//
//  HTQuerySeedEditViewCtl.m
//  SafariStand


#import "SafariStand.h"
#import "HTQuerySeedEditViewCtl.h"
#import "HTQuerySeed.h"
#import "HTArrayController.h"


@implementation HTQuerySeedEditViewCtl
@synthesize querySeedsBinder;
@synthesize addPopupBtn=_addPopupBtn;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.

    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}


-(void)setQuerySeeds:(NSMutableArray *)qss
{
    [querySeedsBinder setQuerySeeds:qss];
}
-(NSMutableArray*)querySeeds
{
    return [querySeedsBinder querySeeds];
}


-(id)defaultObjecOfHTArrayController:(id)aryCtl
{
    if(aryCtl==querySeedsArrayCtl) return [HTQuerySeed querySeed];
    if(aryCtl==postsArrayCtl) return [NSMutableDictionary dictionaryWithObjectsAndKeys:@"key",@"key",@"value",@"val", nil];
    return nil;
}

-(void)setupAddPopup:(NSArray*)defaultItems
{
    NSMenu* menu=[self.addPopupBtn menu];
    for (NSDictionary* dict in defaultItems) {
        NSString* title=[dict objectForKey:@"title"];
        NSMenuItem* mi=[menu addItemWithTitle:title action:@selector(actQuerySeedPresetMenu:) keyEquivalent:@""];
        [mi setRepresentedObject:dict];
        [mi setTarget:self];
    }
}

-(IBAction)actQuerySeedPresetMenu:(id)sender
{
    NSDictionary* dic=[sender representedObject];
    HTQuerySeed* seed=[[HTQuerySeed alloc]initWithDict:dic];
    if (seed) {
        [querySeedsArrayCtl addObject:seed];
    }
}



@end
