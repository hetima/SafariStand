//
//  NSFileManager+SafariStand.m
//  SafariStand

#import <objc/message.h>
#import "NSFileManager+SafariStand.h"

@implementation NSFileManager (SafariStand)

- (SEL)stand_selectorForPathWithUniqueFilenameForPath;
{

    static SEL nameForPathSelector=nil;
    if (!nameForPathSelector) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            if ([self respondsToSelector:@selector(safari_pathWithUniqueFilenameForPath:)]) {
                nameForPathSelector=@selector(safari_pathWithUniqueFilenameForPath:);
            }else if ([self respondsToSelector:@selector(_webkit_pathWithUniqueFilenameForPath:)]) {
                nameForPathSelector=@selector(_webkit_pathWithUniqueFilenameForPath:);
            }else{
                //stand_pathWithUniqueFilenameForPath: 返すと今の仕様では無限ループするので nil
                nameForPathSelector=nil;
            }
        });
    }
    
    return nameForPathSelector;
}

- (NSString*)stand_pathWithUniqueFilenameForPath:(NSString*)path
{
    SEL nameForPathSelector=[self stand_selectorForPathWithUniqueFilenameForPath];
    if (nameForPathSelector) {
        return objc_msgSend(self, nameForPathSelector, path);
    }
    
    //見つからない場合は自前で。
    if ([self fileExistsAtPath:path]) {
        NSString* parent=[path stringByDeletingLastPathComponent];
        NSString* filename=[path lastPathComponent];
        NSString* suffix=[filename pathExtension];
        NSString* prefix=[filename stringByDeletingPathExtension];
        
        for (NSUInteger i = 2; i<=58168; i++) {
            NSString *newName=[NSString stringWithFormat:@"%@-%lu.%@", prefix, (unsigned long)i, suffix];
            path=[parent stringByAppendingPathComponent:newName];
            if (![self fileExistsAtPath:path]) {
                break;
            }
        }
    }
    
    return path;
}

@end
