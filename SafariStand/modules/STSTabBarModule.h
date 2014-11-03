//
//  STSTabBarModule.h
//  SafariStand


/*
 ホイールスクロールでタブ切り替え
 */

@import AppKit;


@interface STSTabBarModule : STCModule

@end


@interface STTabIconLayer : CALayer

+ (id)installedIconLayerInView:(NSView*)view;

@end
