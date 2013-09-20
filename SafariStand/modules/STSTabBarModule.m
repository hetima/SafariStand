//
//  STSTabBarModule.m
//  SafariStand


#import <mach/mach_time.h>
#import "SafariStand.h"
#import "STSTabBarModule.h"


@implementation STSTabBarModule
//typedef double (*msg64)(id, SEL,...);



//タブバー幅変更
static IMP orig_getButtonWidth;
static void ST_getButtonWidth(id self, SEL _cmd, double *w, unsigned long long* leftover, char *isClipping, unsigned long long forTabCount)
{
    orig_getButtonWidth(self, _cmd, w, leftover, isClipping, forTabCount);
    
    if ([[NSUserDefaults standardUserDefaults]boolForKey:kpSuppressTabBarWidthEnabled]) {
        double minX=0.0;

        /*
        BOOL closeClicked=[[self htaoValueForKey:@"STSTabBarModuleLastCloseClicked"]boolValue];
        BOOL mouseIsIn=NO;

        //LOG(@"%@",NSStringFromPoint(pt));
        //mouse is in
        if(closeClicked){
            NSPoint pt=[[self window]mouseLocationOutsideOfEventStream];
            pt=[self convertPoint:pt fromView:nil];
            mouseIsIn=[self mouse:pt inRect:[self frame]];
            //保存してる値があればそっちを優先
            if (mouseIsIn) {
                minX=[[self htaoValueForKey:@"STSTabBarModuleLastValue"]doubleValue];
            }
        }
        //mous is not in なのでクリック判定を消す
        if (!mouseIsIn && closeClicked) {
            [self htaoSetValue:[NSNumber numberWithBool:NO] forKey:@"STSTabBarModuleLastCloseClicked"];
        }
        */
        if (minX>100.0) {
            *w=minX;
        }else{
            //保存してる値を使わないので初期設定から取る
            minX=floor([[NSUserDefaults standardUserDefaults]doubleForKey:kpSuppressTabBarWidthValue]);
            //if (minX<140 || minX>480) minX=240;
            if (*w>minX) {
                *w=minX;
            }
//            [self htaoSetValue:[NSNumber numberWithDouble:*w] forKey:@"STSTabBarModuleLastValue"];
        }
    }
    
}

//閉じてるとき幅固定
static IMP orig_closeTabBtn;
static void ST_closeTabBtn(id self, SEL _cmd, id sender){
    [[self superview] htaoSetValue:[NSNumber numberWithBool:YES] forKey:@"STSTabBarModuleLastCloseClicked"];
    
    id tbm=[STCSafariStandCore mi:@"STSTabBarModule"];
    NSTrackingRectTag t=[[self superview]addTrackingRect:[[self superview]frame] owner:tbm userData:nil assumeInside:NO];
    [[[self superview]window]htaoSetValue:[NSNumber numberWithInteger:t] forKey:@"STSTabBarModuleLastCloseClicked"];
    
    LOG(@"%@,%@",[[self superview]className],NSStringFromRect([self frame]));
    orig_closeTabBtn(self, _cmd, sender);
}
                              
-(void)layoutTabBarForExistingWindow{
    //check exists window
    NSArray *windows=[NSApp windows];
    for (NSWindow* win in windows) {
        id winCtl=[win windowController];
        if([win isVisible] && [[winCtl className]isEqualToString:kSafariBrowserWindowController]
            && [winCtl respondsToSelector:@selector(isTabBarVisible)]
            && [winCtl respondsToSelector:@selector(tabBarView)]
           ){
            
            if (objc_msgSend(winCtl, @selector(isTabBarVisible))) {
                id tabBarView = objc_msgSend(winCtl, @selector(tabBarView));
                if([tabBarView respondsToSelector:@selector(_layOutButtons)]){
                    objc_msgSend(tabBarView, @selector(_layOutButtons));
                }
            }
        }
    }
}

- (id)initWithStand:(id)core
{
    self = [super initWithStand:core];
    if (self) {
        Class tmpClas=objc_msgSend(objc_getClass("BarBackground"), @selector(class));
        if(tmpClas){
            
            mach_timebase_info_data_t timebaseInfo;
            mach_timebase_info(&timebaseInfo);
            duration = ((1000000000 * timebaseInfo.denom) / 3) / timebaseInfo.numer; //1/3sec
            nextTime=mach_absolute_time();

            
            Method tmpMethod;
            struct objc_method_description *md;
            
            tmpMethod=class_getInstanceMethod([STSTabBarModule class], @selector(scrollWheel:));
            if(tmpMethod){
                md=method_getDescription(tmpMethod);
                IMP tmpImp=method_getImplementation(tmpMethod);
                if(tmpImp)class_addMethod(tmpClas, md->name, tmpImp, md->types);
            }
        }

        //タブバー幅変更
        orig_getButtonWidth = RMF(NSClassFromString(@"TabBarView"),
                              @selector(getButtonWidth:leftover:isClipping:forTabCount:), ST_getButtonWidth);
        //close時固定
        //orig_closeTabBtn = RMF(NSClassFromString(@"TabButton"),  @selector(closeTab:), ST_closeTabBtn);

    
        double minX=[[NSUserDefaults standardUserDefaults]doubleForKey:kpSuppressTabBarWidthValue];
        if (minX<140.0 || minX>480.0) minX=240.0;
        if ([[NSUserDefaults standardUserDefaults]boolForKey:kpSuppressTabBarWidthEnabled]) {
            [self layoutTabBarForExistingWindow];
        }
        [self observePrefValue:kpSuppressTabBarWidthEnabled];
        [self observePrefValue:kpSuppressTabBarWidthValue];
        
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)prefValue:(NSString*)key changed:(id)value
{
    if([key isEqualToString:kpSuppressTabBarWidthEnabled]||[key isEqualToString:kpSuppressTabBarWidthValue]){
        [self layoutTabBarForExistingWindow];
    }
}

- (BOOL)canAction{
    uint64_t now=mach_absolute_time();
    if (now>nextTime) {
        nextTime=now+duration;
        return YES;
    }
    return NO;
}

//addMethod to BarBackground
- (void)scrollWheel:(NSEvent *)theEvent
{
    if(![[NSUserDefaults standardUserDefaults]boolForKey:kpSwitchTabWithWheelEnabled]) return;
    id window=objc_msgSend(self, @selector(window));
	
    
	if(![[self className]isEqualToString:@"TabBarView"] && ![[self className]isEqualToString:@"FavoritesBarView"]) return;
    if([[[window windowController]className]isEqualToString:kSafariBrowserWindowController]){
        if ([[STCSafariStandCore mi:@"STSTabBarModule"]canAction]) {

            SEL action=nil;
            //[theEvent deltaY] が+なら上、-なら下
            CGFloat deltaY=[theEvent deltaY];
            if(deltaY>0){
                action=@selector(selectPreviousTab:);
            }else if(deltaY<0){
                action=@selector(selectNextTab:);
            }
            if(action){
                [NSApp sendAction:action to:nil from:self];
            }
        }
    }
    
}

- (void)mouseEntered:(NSEvent *)theEvent
{

}
- (void)mouseExited:(NSEvent *)theEvent
{
    //ここでTabBarViewが欲しいのだが
    NSTrackingRectTag t=[[[theEvent window]htaoValueForKey:@"STSTabBarModuleLastCloseClicked"]integerValue];
    if (t) {

    }
    
    
}
@end
