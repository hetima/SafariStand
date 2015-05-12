//
//  STSelfUpdaterModule.m
//  SafariStand


#import "SafariStand.h"
#import "STSelfUpdaterModule.h"


@implementation STSelfUpdaterModule

- (id)initWithStand:(id)core
{
    self = [super initWithStand:core];
    if (!self) return nil;
    
    _installedTag=[core currentVersionString];
    _installedRevision=[_installedTag stand_revisionFromVersionString];
    _safariRevision=[core safariRevision];
    
    
    return self;
}


- (void)dealloc
{
    
}



- (NSString*)skippedTag
{
    NSString* tag=[[STCSafariStandCore ud]stringForKey:kpSelfUpdateSkippedTag];
    if (tag && [tag length]) {
        return tag;
    }
    return nil;
}


- (void)setSkippedTag:(NSString*)tag
{
    [[STCSafariStandCore ud]setObject:tag forKey:kpSelfUpdateSkippedTag];
}


- (void)clearSkippedTag
{
    [[STCSafariStandCore ud]removeObjectForKey:kpSelfUpdateSkippedTag];
}


- (BOOL)isPluginDirWritable
{
    NSString* path=[[[NSBundle bundleWithIdentifier:kSafariStandBundleID]bundlePath]stringByDeletingLastPathComponent];
    if (![[NSFileManager defaultManager]isWritableFileAtPath:path]) {
        return NO;
    }
    
    //if in Containers return NO
    NSString* containersPath=[NSString stringWithFormat:@"/Users/%@/Library/Containers", NSUserName()];
    if ([path hasPrefix:containersPath]) {
        return NO;
    }
    
    
    return YES;
}


- (void)prefValue:(NSString*)key changed:(id)value
{
    //if([key isEqualToString:])
}


@end

