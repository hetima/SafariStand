//
//  STSelfUpdaterModule.m
//  SafariStand


#import "SafariStand.h"
#import "STSelfUpdaterModule.h"


enum{
    kSelfUpdaterNoError = 0,
    kSelfUpdaterNetworkError,
    kSelfUpdaterInstalledLatest,
    kSelfUpdaterAvailableButSkipped,
    kSelfUpdaterNotWritableError,
    kSelfUpdaterInSandboxError,

    kSelfUpdaterUnzipError,
    kSelfUpdaterFileCopyError,
};

@implementation STSelfUpdaterModule {
    BOOL _inOperation;
    NSAlert* _alert;
    STSelfUpdateChecker* _checker;
    STSelfUpdateDownloader* _downloader;
}

- (id)initWithStand:(id)core
{
    self = [super initWithStand:core];
    if (!self) return nil;
    
    _alert=nil;
    _winCtl=nil;
    _installedTag=[core currentVersionString];
    _installedRevision=[_installedTag stand_revisionFromVersionString];
    _safariRevision=[core safariRevision];
    _downloadUrl=nil;
    _availableTag=nil;
    _releaseNote=nil;
    _isChecking=NO;
    
    return self;
}


- (void)dealloc
{
    
}

- (void)modulesDidFinishLoading:(id)core
{
    if ([[STCSafariStandCore ud]boolForKey:kpSelfUpdateEnabled]) {
        [self checkUpdateWithDetailedResult:NO];
    }
}


- (void)prefValue:(NSString*)key changed:(id)value
{
    //if([key isEqualToString:])
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


- (NSInteger)isPluginDirWritable
{
    NSString* path=[[[NSBundle bundleWithIdentifier:kSafariStandBundleID]bundlePath]stringByDeletingLastPathComponent];
    if (![[NSFileManager defaultManager]isWritableFileAtPath:path]) {
        return kSelfUpdaterNotWritableError;
    }
    
    //if in Containers return NO
    NSString* containersPath=[NSString stringWithFormat:@"/Users/%@/Library/Containers", NSUserName()];
    if ([path hasPrefix:containersPath]) {
        return kSelfUpdaterInSandboxError;
    }
    
    return kSelfUpdaterNoError;
}


- (void)showAlertWithErrorType:(NSInteger)errorType
{
    NSString* info;
    NSString* altTitle=nil;
    
    switch (errorType) {
        case kSelfUpdaterNetworkError:
            info=@"Network error occurred.";
            break;
        case kSelfUpdaterInstalledLatest:
            info=[NSString stringWithFormat:@"%@ is latest version.", self.installedTag];
            break;
        case kSelfUpdaterAvailableButSkipped:
            info=@"Update is available but marked as skip.";
            altTitle=@"Reset Skip";
            break;
        case kSelfUpdaterNotWritableError:
            info=@"Plugin directory is not writable. Please check permission or install manually.";
            altTitle=@"Download Zip";
            break;
        case kSelfUpdaterInSandboxError:
            info=@"Plugin directory is in Sandbox. Please install manually.";
            altTitle=@"Download Zip";
            break;
            
        default:
            info=[NSString stringWithFormat:@"%ld", (long)errorType];
            break;
    }
    
    NSAlert* alert=[[NSAlert alloc]init];
    alert.messageText=@"SafariStand Update";
    alert.informativeText=info;
    [alert addButtonWithTitle:@"OK"]; //1000
    if(altTitle)[alert addButtonWithTitle:altTitle]; //1001
    
    NSModalResponse returnCode=[alert runModal];
    _alert=nil;
    
    if (returnCode==1001) {
        switch (errorType) {
            case kSelfUpdaterAvailableButSkipped:
                [self clearSkippedTag];
                break;
            case kSelfUpdaterNotWritableError:
            case kSelfUpdaterInSandboxError:
                if (self.downloadUrl) {
                    STSafariDownloadURL([NSURL URLWithString:self.downloadUrl], NO);
                }
                break;
                
            default:
                break;
        }
    }
    
}


- (IBAction)actInstall:(id)sender
{
    [self doInstall];
}


- (IBAction)actNotNow:(id)sender
{
    [_winCtl close];
    _winCtl=nil;
}


- (IBAction)actSkip:(id)sender
{
    [_winCtl close];
    
    [self setSkippedTag:self.availableTag];
    
    _winCtl=nil;
}


- (IBAction)actFinish:(id)sender
{
    [_winCtl close];
    _winCtl=nil;
    _checker=nil;
    _downloader=nil;
}


#pragma mark - check update

- (void)checkUpdateWithDetailedResult:(BOOL)showResult
{
    if (_winCtl) {
        [_winCtl showWindow:nil];
        return;
    }
    if (_checker || _alert) {
        return;
    }

    _checker=[[STSelfUpdateChecker alloc]initWithModule:self];
    self.isChecking=YES;
    [_checker checkUpdateWithDetailedResult:showResult];
    
}

- (void)updateCheckerDidFinishOperation:(STSelfUpdateChecker*)checker
{
    self.isChecking=NO;
    if (checker.state == kSelfUpdaterNoError) {
        _availableTag=[checker tagName];
        _releaseNote=[checker releaseNote];
        _downloadUrl=[checker downloadUrl];
        [self showUpdateWindow];

    }else if (checker.showResult) {
        [self showAlertWithErrorType:checker.state];
    }
    
    _checker=nil;
}

- (void)showUpdateWindow
{
    _winCtl=[[STSelfUpdaterWinCtl alloc]initWithWindowNibName:@"STSelfUpdaterWinCtl"];
    _winCtl.module=self;

    [_winCtl showWindow:self];

}



#pragma mark - download

- (void)doInstall
{
    NSInteger result=[self isPluginDirWritable];
    if (result != kSelfUpdaterNoError) {
        [_winCtl close];
        _winCtl=nil;
        [self showAlertWithErrorType:result];
        return;
    }
    _downloader=[[STSelfUpdateDownloader alloc]initWithModule:self];
    [_downloader start];
}

//not used
- (void)updateDownloaderDidFinishOperation:(STSelfUpdateDownloader*)downloader
{
    if (downloader.state != kSelfUpdaterNoError) {
        [self showAlertWithErrorType:downloader.state];
        _downloader=nil;
        [_winCtl close];
        _winCtl=nil;
    }
}

@end



@implementation STSelfUpdaterWinCtl


- (void)windowDidLoad
{
    [super windowDidLoad];
    NSDictionary *attr;
    NSMutableAttributedString *attrstr;
    NSString* label=[NSString stringWithFormat:@"SafariStand %@\n", self.module.availableTag];
    attr = @{ NSForegroundColorAttributeName : [NSColor controlTextColor],
              NSFontAttributeName : [NSFont fontWithName:@"Lucida Grande" size:20.0f]
              };
    attrstr = [[NSMutableAttributedString alloc] initWithString:label attributes:attr];
    [[self.oTextView textStorage]appendAttributedString:attrstr];
    
    
    NSString* note=self.module.releaseNote;
    attr = @{ NSForegroundColorAttributeName : [NSColor controlTextColor],
              NSFontAttributeName : [NSFont systemFontOfSize:13.0f]
              };
    attrstr = [[NSMutableAttributedString alloc] initWithString:@"\n" attributes:attr];
    [[self.oTextView textStorage]appendAttributedString:attrstr];
    
    attrstr = [[NSMutableAttributedString alloc] initWithString:note attributes:attr];
    [[self.oTextView textStorage]appendAttributedString:attrstr];
}


- (IBAction)actInstall:(id)sender
{
    [_module actInstall:nil];
}


- (IBAction)actNotNow:(id)sender
{
    [_module actNotNow:nil];
}


- (IBAction)actSkip:(id)sender
{
    [_module actSkip:nil];
}


- (IBAction)actFinish:(id)sender
{
    [_module actFinish:nil];
}

- (void)showProgressTab
{
    [self.oTabView selectTabViewItemAtIndex:1];
    NSRect rect=self.window.frame;
    CGFloat height=100.0f+(rect.size.height-self.oTabView.frame.size.height);
    rect.origin.y+=(rect.size.height-height);
    rect.size.height=height;
    rect.size.width=480.0f;
    [self.window setFrame:rect display:YES animate:YES];
}

- (void)showFinishedTab
{
    [self.oTabView selectTabViewItemAtIndex:2];
}

@end


@implementation STSelfUpdateChecker {
    BOOL _inOperation;
}

- (instancetype)initWithModule:(STSelfUpdaterModule*)module
{
    self = [super init];
    if (self) {
        _state=kSelfUpdaterNoError;
        _module=module;
        _releaseInfo=nil;
    }
    return self;
}

- (NSString*)tagName
{
    return [_releaseInfo objectForKey:@"tag_name"];
}


- (NSString*)downloadUrl
{
    return [[[_releaseInfo objectForKey:@"assets"]firstObject]objectForKey:@"browser_download_url"];
}

- (NSString*)releaseNote
{
    return [[_releaseInfo objectForKey:@"body"]stringByReplacingOccurrencesOfString:@"\r" withString:@""];
}


- (void)checkUpdateWithDetailedResult:(BOOL)showResult
{
    
    if (_inOperation) {
        return;
    }
    _showResult=showResult;
    _inOperation=YES;
    _state=kSelfUpdaterNoError;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        _releaseInfo=[self releaseForUpdateSync];
        _inOperation=NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            [_module updateCheckerDidFinishOperation:self];
        });
    });
    
}


- (NSDictionary*)releaseForUpdateSync
{
    NSArray* tags=[self releasedTagsSync];
    NSString* revisionPrefix=[_module.installedRevision stringByAppendingString:@"."];
    
    //check current revision
    NSString* latestTag=[self _latestTagWithTags:tags prefix:revisionPrefix greaterThan:_module.installedTag];
    if ([latestTag isEqualToString:_module.installedTag]) {
        latestTag=nil;
    }
    
    //check Safari revision
    if (!latestTag && [_module.installedRevision compare:_module.safariRevision options:NSNumericSearch]==NSOrderedAscending) {
        revisionPrefix=[_module.safariRevision stringByAppendingString:@"."];
        latestTag=[self _latestTagWithTags:tags prefix:revisionPrefix greaterThan:@"0"];
        if ([latestTag isEqualToString:@"0"]) {
            latestTag=nil;
        }
    }
    
    if (!latestTag) {
        _state=kSelfUpdaterInstalledLatest;
        return nil;
    }
    
    NSString* urlStr=[NSString stringWithFormat:@"https://api.github.com/repos/%@/releases/tags/%@", kSafariStandGitHubRepoName, latestTag];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
    NSError* err;
    NSURLResponse* resp;
    NSData* data=[NSURLConnection sendSynchronousRequest:request returningResponse:&resp error:&err];
    if (!data || err) {
        _state=kSelfUpdaterNetworkError;
        return nil;
    }
    NSDictionary* releaseInfo=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&err];
    if (!releaseInfo || err) {
        _state=kSelfUpdaterNetworkError;
        return nil;
    }
    NSString* downloadUrl=[[[releaseInfo objectForKey:@"assets"]firstObject]objectForKey:@"browser_download_url"];
    if ([downloadUrl length]<=0) {
        _state=kSelfUpdaterInstalledLatest;
        return nil;
    }
    
    if ([latestTag isEqualToString:[_module skippedTag]]) {
        _state=kSelfUpdaterAvailableButSkipped;
        return nil;
    }
    
    return releaseInfo;
}

- (NSString*)_latestTagWithTags:(NSArray*)tags prefix:(NSString*)prefix greaterThan:(NSString*)base
{
    NSString* latestTag=base;
    for (NSString* tag in tags) {
        if ([tag hasPrefix:prefix]
            && [latestTag compare:tag options:NSNumericSearch]==NSOrderedAscending){
            latestTag=tag;
        }
    }
    return latestTag;
}


- (NSArray*)releasedTagsSync
{
    NSString* urlStr=[NSString stringWithFormat:@"https://api.github.com/repos/%@/tags", kSafariStandGitHubRepoName];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
    NSError* err;
    NSURLResponse* resp;
    NSData* data=[NSURLConnection sendSynchronousRequest:request returningResponse:&resp error:&err];
    if (!data || err) {
        _state=kSelfUpdaterNetworkError;
        return nil;
    }
    
    NSArray* jTags=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&err];
    if (!jTags || err) {
        _state=kSelfUpdaterNetworkError;
        return nil;
    }
    
    NSMutableArray* tags=[[NSMutableArray alloc]initWithCapacity:[jTags count]];
    for (NSDictionary* jTag in jTags) {
        NSString* tag=[jTag objectForKey:@"name"];
        if([tag length]>0)[tags addObject:tag];
    }
    return tags;
}

@end


@implementation STSelfUpdateDownloader {
    STSelfUpdaterWinCtl* _winCtl;
    NSURLSession* _session;
    NSURLSessionDownloadTask* _task;
    NSString* _tmpDir;
}

- (instancetype)initWithModule:(STSelfUpdaterModule*)module
{
    self = [super init];
    if (self) {
        _tmpDir=nil;
        _state=kSelfUpdaterNoError;
        _module=module;
        _winCtl=module.winCtl;

        NSURL* url = [NSURL URLWithString:_module.downloadUrl];
        NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        _task = [_session downloadTaskWithURL:url];
    }
    return self;
}


- (void)dealloc
{
    if ([[NSFileManager defaultManager]fileExistsAtPath:_tmpDir]) {
        [[NSFileManager defaultManager]removeItemAtPath:_tmpDir error:nil];
    }
    [self invalidateDownload];
}


- (void)invalidateDownload
{
    [_session invalidateAndCancel];
    _session=nil;
    _task=nil;
}


- (void)start
{
    _winCtl.oProgressCancelBtn.action=@selector(actCancelDownload:);
    _winCtl.oProgressCancelBtn.target=self;
    _winCtl.oProgressIndicator.doubleValue=0.0f;
    _winCtl.oProgressIndicator.maxValue=1.0f;
    _winCtl.oProgressLabel.stringValue=@"Download...";
    [_winCtl showProgressTab];
    [_task resume];
}

- (IBAction)actCancelDownload:(id)sender
{
    [self invalidateDownload];
    _winCtl.oResultLabel.stringValue=@"User canceled.";
    _state=kSelfUpdaterNoError;
    [_winCtl showFinishedTab];
}

#pragma mark - download

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes
{
}


- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    double val = (double)totalBytesWritten / (double)totalBytesExpectedToWrite;
    _winCtl.oProgressIndicator.doubleValue=val;
}


- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    _winCtl.oProgressIndicator.doubleValue=1.0f;
    [self invalidateDownload];
    [self unzipAndInstall:[location path]];
}

#pragma mark - unzip

- (void)unzipAndInstall:(NSString*)path
{
    _winCtl.oProgressCancelBtn.action=nil;
    _winCtl.oProgressCancelBtn.target=nil;
    _winCtl.oProgressCancelBtn.enabled=NO;
    
    _winCtl.oProgressIndicator.indeterminate=YES;
    [_winCtl.oProgressIndicator startAnimation:nil];
    _winCtl.oProgressLabel.stringValue=@"Extract Archive...";
    
    _tmpDir=[path stringByAppendingString:@"_output"];
    
    HTRemoveXattr(path, "com.apple.quarantine");
    NSArray *arguments = @[@"-qq", path, @"-x", @"__MACOSX/*", @"-d", _tmpDir];
    NSTask *unzipTask = [[NSTask alloc] init];
    [unzipTask setLaunchPath:@"/usr/bin/unzip"];
    [unzipTask setArguments:arguments];
    [unzipTask launch];
    [unzipTask waitUntilExit];
    
    if ([unzipTask terminationStatus]!=0) {
        [[NSFileManager defaultManager]removeItemAtPath:_tmpDir error:nil];
        _state=kSelfUpdaterUnzipError;
    }else{
        NSString* newBundlePath=[self _bundlePathInExtractedDirectory:_tmpDir];
        if (newBundlePath) {
            [self _copyNewBundleToPluginDirectory:newBundlePath];
        }else{
            _state=kSelfUpdaterFileCopyError;
        }
    }
    
    if (_state!=kSelfUpdaterNoError) {
        
    }
    
    NSString* label;
    switch (_state) {
        case kSelfUpdaterFileCopyError:
            label=@"Failed to update. Couldnot copy files.";
            break;
        case kSelfUpdaterUnzipError:
            label=@"Failed to update. Couldnot extract archive.";
            break;
            
        default:
            label=@"New version of SafariStand was installed. Please restart Safari.";
            break;
    }
    
    _winCtl.oResultLabel.stringValue=label;
    [_winCtl showFinishedTab];
    
}


- (NSString*)_bundlePathInExtractedDirectory:(NSString*)path
{
    NSEnumerator* e=[[NSFileManager defaultManager]enumeratorAtPath:path];
    NSString* subPath;
    while (subPath=[e nextObject]) {
        if ([[subPath lastPathComponent]isEqualToString:@"SafariStand.bundle"]) {  // SafariStandx.x.xxx/SafariStand.bundle
            NSString* newBundlePath=[path stringByAppendingPathComponent:subPath];
            NSString* check=[newBundlePath stringByAppendingPathComponent:@"Contents/Info.plist"];
            if ([[NSFileManager defaultManager]fileExistsAtPath:check]) {
                return newBundlePath;
            }
        }
    }
    
    return nil;
}


- (void)_copyNewBundleToPluginDirectory:(NSString*)newBundlePath
{
    NSString* oldBundlePath=[[NSBundle bundleWithIdentifier:kSafariStandBundleID]bundlePath];
    //NSString* path=[oldBundlePath stringByDeletingLastPathComponent]; //already checked writable

    if(![[NSFileManager defaultManager]trashItemAtURL:[NSURL fileURLWithPath:oldBundlePath] resultingItemURL:nil error:nil]){
        _state=kSelfUpdaterFileCopyError;
        return;
    }
    if(![[NSFileManager defaultManager]copyItemAtPath:newBundlePath toPath:oldBundlePath error:nil]){
        _state=kSelfUpdaterFileCopyError;
        return;
    }
    
}

@end