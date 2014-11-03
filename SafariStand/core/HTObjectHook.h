//
//  HTObjectHook.h
//  SafariStand
//


@import Foundation;



IMP Replace_MethodImp_WithFunc(Class aClass, SEL origSel, const void* repFunc);
IMP Replace_ClassMethodImp_WithFunc(Class aClass, SEL origSel, const void* repFunc);


#ifndef REPFUNCDEFd
#define REPFUNCDEFd
#define RMF(aClass, origSel, repFunc) Replace_MethodImp_WithFunc(aClass, origSel, repFunc)
#define RCMF(aClass, origSel, repFunc) Replace_ClassMethodImp_WithFunc(aClass, origSel, repFunc)
#endif
