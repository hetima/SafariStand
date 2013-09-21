//
//  HTUtils.m
//  SafariStand

#if __has_feature(objc_arc)
#error This file must be compiled with -fno-objc_arc
#endif

#import <sys/xattr.h>
//#import <openssl/md5.h>
#import <CommonCrypto/CommonDigest.h>
#import <objc/message.h>

#import "HTUtils.h"
#import "NSString+HTUtil.h"

int HTAddXattrMDItemWhereFroms(NSString* path, NSArray* URLArray)
{
    return HTAddXattr(path, "com.apple.metadata:kMDItemWhereFroms", URLArray);
}

//value must be a kind of NSData, NSString, NSNumber, NSDate, NSArray, or NSDictionary
int HTAddXattr(NSString* path, const char *cName, id value)
{
    const char *cPath=[path fileSystemRepresentation];
    NSData* data=[NSPropertyListSerialization dataFromPropertyList:value format:NSPropertyListBinaryFormat_v1_0 errorDescription:nil];
    
    if(data && cPath && cName){
        return setxattr(cPath, cName, [data bytes], [data length], 0, 0);
    }
    return -1;
}

NSString* HTMD5StringFromString(NSString* inStr)
{

    const char *cstr = [inStr UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cstr, (CC_LONG)strlen(cstr), digest);
    return [NSString stringWithFormat: @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                digest[0], digest[1],
                digest[2], digest[3],
                digest[4], digest[5],
                digest[6], digest[7],
                digest[8], digest[9],
                digest[10], digest[11],
                digest[12], digest[13],
                digest[14], digest[15]];
}

NSURL* HTBestURLFromPasteboard(NSPasteboard* pb, BOOL needsInstance){
    NSURL* result=nil;
    //if ([pb respondsToSelector:@selector(_web_bestURL)])result=objc_msgSend(pb, @selector(_web_bestURL));
    if(needsInstance && [[pb types] containsObject:NSURLPboardType]){
        NSURL *URLFromPasteboard = [NSURL URLFromPasteboard:pb];
        NSString *scheme = [URLFromPasteboard scheme];
        if ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]) {
            return URLFromPasteboard;
        }
    }
    
    static NSArray* availableTypes=nil;
    if (availableTypes==nil) {

        availableTypes=[[NSArray alloc]initWithObjects:@"public.url", @"public.file-url", NSStringPboardType, nil];
    }
    NSString* type=[pb availableTypeFromArray:availableTypes];


    
	if([type isEqualToString:@"public.url"]){
        if(!needsInstance){
            result=(id)availableTypes;
        }else{
            result=[NSURL URLWithString:[pb stringForType:type]];
        }
	}else if([type isEqualToString:@"public.file-url"]){
        
        static NSArray* alloedExt=nil;
        if (!alloedExt) {
            alloedExt=[[NSArray alloc]initWithObjects:
                @"html", @"htm", @"webarchive", @"jpg", @"png", @"jpeg", @"tif", @"tiff", @"rtf", @"pdf", nil];
        }
        NSString* urlStr=[pb stringForType:type];
        NSString* ext=[[urlStr pathExtension]lowercaseString];
        if([ext length]>0 && [alloedExt indexOfObject:ext] != NSNotFound){
            if(!needsInstance){
                result=(id)availableTypes;
            }else{
                result=[NSURL URLWithString:urlStr];
            }
        }

        
        
	}else if([type isEqualToString:NSStringPboardType]){
		NSString* urlString=[pb stringForType:NSStringPboardType];
        urlString=[urlString htModeratedStringWithin:0];
        if([urlString hasPrefix:@"http://"]||[urlString hasPrefix:@"https://"]){
            if(!needsInstance){
                result=(id)availableTypes;
            }else{
                result=[NSURL URLWithString:urlString];
            }
        }
        /*
		NSInteger length=[urlString length];
        if(length<1024*8){
        urlString=[urlString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if([urlString hasPrefix:@"http://"]||[urlString hasPrefix:@"https://"]){
                NSArray* tmpAry=[urlString componentsSeparatedByString:@"\n"];
                if([tmpAry count]>0)urlString=[tmpAry objectAtIndex:0];
                urlString=[urlString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                if(!needsInstance){
                    result=(id)availableTypes;
                }else{
                    result=[NSURL URLWithString:urlString];
                }
            }
        }*/
	}
    

    return result;
}


void HTShowPopupMenuForButton(NSEvent* event, NSButton* view, NSMenu* aMenu)
{
    NSAutoreleasePool*  arp=[[NSAutoreleasePool alloc]init];

    [[view cell]setHighlighted:YES];
    //[view display];
    //    _currentWindow=[view window];
    
    if([aMenu respondsToSelector:@selector(popUpInRect:ofView:)]){
        NSRect bounds=[view bounds];
        bounds.size.height+=2;
        bounds.origin.x-=2;
        objc_msgSend(aMenu, @selector(popUpInRect:ofView:), bounds, view);
    }else{
        [NSMenu popUpContextMenu:aMenu withEvent:event forView:view];
    }
    
    //    _currentWindow=nil;
    [[view cell]setHighlighted:NO];
    //[view setNeedsDisplay:YES];
    
    [arp release];
}


