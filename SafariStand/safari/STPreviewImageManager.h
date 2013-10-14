//
//  STPreviewImageManager.h
//  SafariStand
//
//  Created by main on 2013/10/12.
//
//

#import <Foundation/Foundation.h>

@class STTabProxy, STPreviewImageDelivery;

@interface STPreviewImageManager : NSObject

- (void)requestPreviewImage:(STTabProxy*)tabProxy instantDelivery:(BOOL)instantDelivery;
- (void)invalidateRequestForTabProxy:(STTabProxy*)tabProxy;

@end

@interface STPreviewImageDelivery : NSObject

@property (weak)STTabProxy* tabProxy;
@property (nonatomic, strong)NSString* path;
@property (nonatomic, strong)NSString* nameHash;
@property (nonatomic, strong)NSImage* image;

- (id)initWithTabProxy:(STTabProxy*)tabProxy;
- (void)deliver;

@end