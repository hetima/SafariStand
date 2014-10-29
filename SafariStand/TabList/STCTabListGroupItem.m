//
//  STCTabListGroupItem.m
//  SafariStand
//
//  Created by hetima on 2014/10/27.
//
//

#import "STCTabListGroupItem.h"

@implementation STCTabListGroupItem

- (instancetype)init
{
    self = [super init];
    if (self) {
        _viewIdentifier=@"group";
        _groupRow=YES;
        _viewHeight=20.0;
    }
    return self;
}

- (void)dealloc
{
    LOG(@"group d");
}



@end

@implementation STCBottomGroupItem

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.viewIdentifier=@"bottomGroup";
        
        self.groupRow=NO;
        self.image=nil;
        self.title=@"";
        
    }
    return self;
}

//pretend to STTabProxy
- (BOOL)isSelected
{
    return NO;
}

@end


@implementation STCWindowGroupItem

- (instancetype)init
{
    self = [super init];
    if (self) {
        //self.viewIdentifier=@"windowGroup";
        
        static NSImage* windowGroupItemImage;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            windowGroupItemImage=[[NSBundle bundleWithIdentifier:kSafariStandBundleID]imageForResource:@"STTLWindowIcon"];
            [windowGroupItemImage setTemplate:YES];
        });
        
        self.image=windowGroupItemImage;
        // ウインドウタイトルの変更監視するのめんどいし、選択してるタブと同じ名前だから省略
        // ウインドウの幅とか表示するのがいいかもしれない。変更監視（ｒｙ
        self.title=@"";

    }
    return self;
}

@end

