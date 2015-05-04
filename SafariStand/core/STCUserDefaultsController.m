//
//  STCUserDefaultsController.m
//  SafariStand


#import "SafariStand.h"
#import "STCUserDefaultsController.h"


@implementation STCUserDefaults

- (void)setObject:(id)value forKey:(NSString *)defaultName
{
    [self willChangeValueForKey:defaultName];
    [super setObject:value forKey:defaultName];
    [self didChangeValueForKey:defaultName];
}

@end


@implementation STCUserDefaultsController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self=[super initWithCoder:coder];

    NSUserDefaults* ud=[STCSafariStandCore ud];
    ((void(*)(id, SEL, ...))objc_msgSend)(self, NSSelectorFromString(@"_setDefaults:"), ud);
    
    return self;
}

@end
