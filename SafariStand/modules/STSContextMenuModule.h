//
//  STSContextMenuModule.h
//  SafariStand


#import <Foundation/Foundation.h>

@class STSquashContextMenuSheetCtl;

@interface STSContextMenuModule : STCModule

@property (nonatomic,retain)STSquashContextMenuSheetCtl* squashSheetCtl;

-(NSWindow*)advancedSquashSettingSheet;

@end

