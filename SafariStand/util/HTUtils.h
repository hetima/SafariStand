//
//  HTUtils.h
//  SafariStand


#import <Foundation/Foundation.h>


int HTAddXattrMDItemWhereFroms(NSString* path, NSArray* URLArray);

int HTAddXattr(NSString* path, const char *cName, id value);
NSString* HTMD5StringFromString(NSString* inStr);

NSURL* HTBestURLFromPasteboard(NSPasteboard* pb, BOOL needsInstance);

void HTShowPopupMenuForButton(NSEvent* event, NSButton* view, NSMenu* aMenu);
