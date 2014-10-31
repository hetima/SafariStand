//
//  HTUtils.h
//  SafariStand


#import <Foundation/Foundation.h>


int HTAddXattrMDItemWhereFroms(NSString* path, NSArray* URLArray);
BOOL HTClearFileQuarantineState(NSString* path);

int HTAddXattr(NSString* path, const char *cName, id value);
int HTRemoveXattr(NSString* path, const char *cName);

NSString* HTMD5StringFromString(NSString* inStr);
NSColor* HTColorFromHTMLString(NSString *inStr);

NSData* HTPNGDataRepresentation(NSImage* image);
NSImage* HTImageWithBackgroundColor(NSImage* image, NSColor* color);

NSURL* HTBestURLFromPasteboard(NSPasteboard* pb, BOOL needsInstance);

void HTShowPopupMenuForButton(NSEvent* event, NSButton* view, NSMenu* aMenu);

NSString* HTStringFromDateWithFormat(NSDate* date, NSString* format);

NSString* HTDomainFromHost(NSString* host);
