//
//  STSContextMenuModule.h
//  SafariStand


#import <Foundation/Foundation.h>

@class SquashContextMenuSheetCtl;

@interface STSContextMenuModule : STCModule {

    
}
@property (nonatomic,retain)SquashContextMenuSheetCtl* squashSheetCtl;

-(NSWindow*)advancedSquashSettingSheet;

@end

