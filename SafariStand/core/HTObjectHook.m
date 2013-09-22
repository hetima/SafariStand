//
//  HTObjectHook.m
//  SafariStand
//

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import "SafariStand.h"
#import "HTObjectHook.h"


IMP Replace_MethodImp_WithFunc(Class aClass, SEL origSel, const void* repFunc)
{
    Method origMethod;
    IMP oldImp = NULL;

    if (aClass && (origMethod = class_getInstanceMethod(aClass, origSel))){
        oldImp=method_setImplementation(origMethod, repFunc);
    }

    return oldImp;
}


IMP Replace_ClassMethodImp_WithFunc(Class aClass, SEL origSel, const void* repFunc)
{
    Method origMethod;
    IMP oldImp = NULL;

    if (aClass && (origMethod = class_getClassMethod(aClass, origSel))){
        oldImp=method_setImplementation(origMethod, repFunc);
    }

    return oldImp;
}

