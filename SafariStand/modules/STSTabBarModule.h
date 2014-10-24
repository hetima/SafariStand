//
//  STSTabBarModule.h
//  SafariStand


/*
 ホイールスクロールでタブ切り替え
 */

#import <Foundation/Foundation.h>


@interface STSTabBarModule : STCModule

@end


@interface STTabIconLayer : CALayer

+ (id)installedIconLayerInView:(NSView*)view;

@end
