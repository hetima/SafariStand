//
//  NSObject+HTAssociatedObject.m
//  SafariStand

#if __has_feature(objc_arc)
#error This file must be compiled with -fno-objc_arc
#endif

#import <objc/message.h>

#import "NSObject+HTAssociatedObject.h"

static char htaokey;

@implementation NSObject (HTAssociatedObject)


- (NSMutableDictionary*)htaoDictionary
{   

    return objc_getAssociatedObject(self, &htaokey);
}

- (void)htaoSetValue:(id)value forKey:(id)key
{
    NSMutableDictionary* dic=[self htaoDictionary];
    if(!dic){
        dic=[NSMutableDictionary dictionaryWithObject:value forKey:key];
        objc_setAssociatedObject(self, &htaokey, dic, OBJC_ASSOCIATION_RETAIN);
    }else{
        [dic setObject:value forKey:key];
    }
}

- (id)htaoValueForKey:(id)key
{
    NSDictionary* dic=[self htaoDictionary];
    return [dic objectForKey:key];
    
}


@end
