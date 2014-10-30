//
//  STCTabListGroupItem.h
//  SafariStand
//
//  Created by hetima on 2014/10/27.
//
//

#import <Foundation/Foundation.h>

@interface STCTabListGroupItem : NSObject

@property(nonatomic, copy)NSString* viewIdentifier;
@property(nonatomic)CGFloat viewHeight;
@property(nonatomic, getter=isGroupRow)BOOL groupRow;
@property(nonatomic, copy)NSString* title;
@property(nonatomic, strong)NSImage* image;

@end

@interface STCBottomGroupItem : STCTabListGroupItem
@end


@interface STCWindowGroupItem : STCTabListGroupItem
@property(nonatomic, weak)NSWindow* window;

@end