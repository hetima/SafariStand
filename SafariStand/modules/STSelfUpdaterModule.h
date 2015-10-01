//
//  STSelfUpdaterModule.h
//  SafariStand


@import AppKit;

@class STSelfUpdaterWinCtl;

@interface STSelfUpdaterModule : STCModule

@property(nonatomic, strong, readonly) NSString* installedTag;
@property(nonatomic, strong, readonly) NSString* installedRevision;
@property(nonatomic, strong, readonly) NSString* safariRevision;
@property(nonatomic, strong, readonly) NSString* systemCodeName;
@property(nonatomic, strong, readonly) NSString* standCodeName;

@property(nonatomic) BOOL isChecking; //bind with progressIndicator
@property(nonatomic, strong, readonly) NSString* availableTag;
@property(nonatomic, strong, readonly) NSString* downloadUrl;
@property(nonatomic, strong, readonly) NSString* releaseNote;
@property(nonatomic, strong) STSelfUpdaterWinCtl* winCtl;

- (void)checkUpdateWithDetailedResult:(BOOL)showResult;

@end


@interface STSelfUpdaterWinCtl : NSWindowController
@property(nonatomic, weak) STSelfUpdaterModule* module;
@property(nonatomic, strong) IBOutlet NSTextView* oTextView;
@property(nonatomic, weak) IBOutlet NSTabView* oTabView;
@property(nonatomic, weak) IBOutlet NSProgressIndicator* oProgressIndicator;
@property(nonatomic, weak) IBOutlet NSTextField* oProgressLabel;
@property(nonatomic, weak) IBOutlet NSTextField* oResultLabel;
@property(nonatomic, weak) IBOutlet NSButton* oProgressCancelBtn;

- (void)showProgressTab;
- (void)showFinishedTab;

@end

@interface STSelfUpdateChecker : NSObject
@property(nonatomic, weak) STSelfUpdaterModule* module;
@property(nonatomic) NSInteger state;
@property(nonatomic) BOOL showResult;
@property(nonatomic, strong, readonly) NSDictionary* releaseInfo;

- (instancetype)initWithModule:(STSelfUpdaterModule*)module;
- (void)checkUpdateWithDetailedResult:(BOOL)showResult;

- (NSString*)tagName;
- (NSString*)downloadUrl;
- (NSString*)releaseNote;
@end


@interface STSelfUpdateDownloader : NSObject <NSURLSessionDownloadDelegate>
@property(nonatomic, weak) STSelfUpdaterModule* module;
@property(nonatomic) NSInteger state;

- (instancetype)initWithModule:(STSelfUpdaterModule*)module;
- (void)start;

@end
