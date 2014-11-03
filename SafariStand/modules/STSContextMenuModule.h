//
//  STSContextMenuModule.h
//  SafariStand


@import AppKit;

@class STSquashContextMenuSheetCtl;

@interface STSContextMenuModule : STCModule

@property (nonatomic, strong) STSquashContextMenuSheetCtl* squashSheetCtl;

- (NSWindow*)advancedSquashSettingSheet;

@end

