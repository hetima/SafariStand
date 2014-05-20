//
//  STSContextMenuModule.h
//  SafariStand


#import <Foundation/Foundation.h>

@class STSquashContextMenuSheetCtl;

@interface STSContextMenuModule : STCModule

@property (nonatomic, strong) STSquashContextMenuSheetCtl* squashSheetCtl;

- (NSWindow*)advancedSquashSettingSheet;

@end

