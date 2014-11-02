//
//  HTWindowControllerRetainer.m
//  SafariStand


#import "HTWindowControllerRetainer.h"

@implementation HTWindowControllerRetainer

static HTWindowControllerRetainer *sharedInstance;

+ (HTWindowControllerRetainer *)si
{
    
    if (sharedInstance == nil){
        sharedInstance = [[HTWindowControllerRetainer alloc]init];
    }
    
    return sharedInstance;
}

- (void)addWindowController:(NSWindowController*)winCtl
{

    if([self.windowControllers indexOfObjectIdenticalTo:winCtl]!=NSNotFound){
        return;
    }
    
    //observe close
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(windowWillClose:) name:NSWindowWillCloseNotification object:[winCtl window]];
    [self.windowControllers addObject:winCtl];

}

- (id)init
{
    self = [super init];
    if (!self) return nil;
    
    
    self.windowControllers=[[NSMutableArray alloc]init];
    
    
    return self;
}


- (void)windowWillClose:(NSNotification *)aNotification
{
    NSMutableArray* ctls=self.windowControllers;

    for (NSWindowController *winCtl in ctls) {
        if (winCtl.window==[aNotification object]) {
            //remove from list
            [[NSNotificationCenter defaultCenter]removeObserver:self name:NSWindowWillCloseNotification object:[aNotification object]];
            [self.windowControllers removeObjectIdenticalTo:winCtl];
            break;
        }
    }
}

@end
