//
//  STSTabBarModule.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import <mach/mach_time.h>
#import "SafariStand.h"
#import "STSTabBarModule.h"


@implementation STSTabBarModule


-(void)layoutTabBarForExistingWindow
{
    //check exists window
    NSArray *windows=[NSApp windows];
    for (NSWindow* win in windows) {
        id winCtl=[win windowController];
        if([win isVisible] && [[winCtl className]isEqualToString:kSafariBrowserWindowController]
            && [winCtl respondsToSelector:@selector(isTabBarVisible)]
            && [winCtl respondsToSelector:@selector(scrollableTabBarView)]
           ){
            
            if (objc_msgSend(winCtl, @selector(isTabBarVisible))) {
                id tabBarView = objc_msgSend(winCtl, @selector(scrollableTabBarView));
                if([tabBarView respondsToSelector:@selector(_updateButtonsAndLayOutAnimated:)]){
                    objc_msgSend(tabBarView, @selector(_updateButtonsAndLayOutAnimated:), YES);
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
        KZRMETHOD_SWIZZLING_WITHBLOCK
        (
         "ScrollableTabBarView", "_buttonWidthForNumberOfButtons:inWidth:remainderWidth:",
         KZRMethodInspection, call, sel,
         ^double (id slf, unsigned long long buttonNum, double inWidth, double* remainderWidth){
             double result=call.as_double(slf, sel, buttonNum, inWidth, remainderWidth);
             if ([[NSUserDefaults standardUserDefaults]boolForKey:kpSuppressTabBarWidthEnabled]) {
                 double maxWidth=floor([[NSUserDefaults standardUserDefaults]doubleForKey:kpSuppressTabBarWidthValue]);
                 if (result>maxWidth) {
                     //double diff=result-maxWidth;
                     //*remainderWidth=diff+*remainderWidth;
                     return maxWidth;
                 }
             }
             return result;
         });
        
        KZRMETHOD_SWIZZLING_WITHBLOCK
        (
         "ScrollableTabBarView", "_shouldLayOutButtonsToAlignWithWindowCenter",
         KZRMethodInspection, call, sel,
         ^BOOL (id slf){
             if ([[NSUserDefaults standardUserDefaults]boolForKey:kpSuppressTabBarWidthEnabled]) {
                 return NO;
             }
             
             BOOL result=call.as_char(slf, sel);
             return result;
         });

    
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

}

- (void)prefValue:(NSString*)key changed:(id)value
{
    if([key isEqualToString:kpSuppressTabBarWidthEnabled]||[key isEqualToString:kpSuppressTabBarWidthValue]){
        [self layoutTabBarForExistingWindow];
    }
}

- (BOOL)canAction
{
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
	
    LOG(@"%@",[self className]);
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
