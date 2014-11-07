

#import "STCModule.h"
#import "STCSafariStandCore.h"
#import "NSObject+HTAssociatedObject.h"
#import "NSString+HTUtil.h"
#import "HTUtils.h"
#import "STSafariConnect.h"


#ifndef LOCALIZEd
#define LOCALIZEd
#define LOCALIZE(key) \
[[NSBundle bundleWithIdentifier:kSafariStandBundleID] localizedStringForKey:(key) value:key table:nil]
#endif

