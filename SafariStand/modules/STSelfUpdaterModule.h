//
//  STSelfUpdaterModule.h
//  SafariStand


@import AppKit;


@interface STSelfUpdaterModule : STCModule

@property(nonatomic, strong, readonly) NSString* installedTag;
@property(nonatomic, strong, readonly) NSString* installedRevision;
@property(nonatomic, strong, readonly) NSString* safariRevision;


@end

