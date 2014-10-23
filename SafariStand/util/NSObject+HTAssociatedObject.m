//
//  NSObject+HTAssociatedObject.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import <objc/message.h>

#import "NSObject+HTAssociatedObject.h"

static char htaokey;

@implementation NSObject (HTAssociatedObject)


- (NSMutableDictionary*)htao_dictionary
{   

    return objc_getAssociatedObject(self, &htaokey);
}

//value==nil なら remove
- (void)htao_setValue:(id)value forKey:(id)key
{
    if (!key) {
        return;
    }
    
    NSMutableDictionary* dic=[self htao_dictionary];
    if(!dic){
        if (value) {
            dic=[NSMutableDictionary dictionaryWithObject:value forKey:key];
            objc_setAssociatedObject(self, &htaokey, dic, OBJC_ASSOCIATION_RETAIN);
        }
    }else{
        if (value) {
            [dic setObject:value forKey:key];
        }else{
            [dic removeObjectForKey:key];
        }
    }
}

- (id)htao_valueForKey:(id)key
{
    NSDictionary* dic=[self htao_dictionary];
    return [dic objectForKey:key];
}


@end
