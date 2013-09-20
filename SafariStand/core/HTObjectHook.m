//
//  HTObjectHook.m
//  SafariStand
//

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

