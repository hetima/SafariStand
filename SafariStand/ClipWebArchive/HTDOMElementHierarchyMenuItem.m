//
//  HTDOMElementHierarchyMenuItem.m

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import <WebKit/WebKit.h>
#import "HTDOMElementHierarchyMenuItem.h"


NSMenuItem* HTDOMHTMLElementHierarchyMenuItemRetained(id node, NSString* title, SEL itemSelector, id target, BOOL includeBody)
{
    NSMenuItem* result=nil;
    
//    WebFrame* frame=[[node ownerDocument] webFrame];
    ////NSView* view=[[[[frame frameView] documentView] enclosingScrollView] contentView];
//    NSView* view=[frame webView];
    
    
    NSMenu* myMenu=[[NSMenu alloc]initWithTitle:title];
    //HTDOMElementHierarchyMenuItem* myMenuItem=[[HTDOMElementHierarchyMenuItem alloc] initWithTitle:title targetView:view];
    NSMenuItem* myMenuItem=[[NSMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""];
    
    while(node){
        if([node isKindOfClass:[DOMDocument class]]
         || (!includeBody && [node isKindOfClass:[DOMHTMLBodyElement class]])
         || [node isKindOfClass:[DOMHTMLDocument class]]
         || [node isKindOfClass:[WebUndefined class]]){
             break;
        }else{
            if([node respondsToSelector:@selector(tagName)]){
                NSMenuItem* addedItem=[myMenu addItemWithTitle:HTDescriptionDOMHTMLElement(node) 
                            action:itemSelector keyEquivalent:@""];
                [addedItem setRepresentedObject:node];
                [addedItem setTarget:target];
            }
            node=[node parentNode];
        }
    }

    
    if([myMenu numberOfItems]>0){
        [myMenuItem setSubmenu:myMenu];
        result=myMenuItem;
    }
    return result;
}

NSString* HTDescriptionDOMHTMLElement(id node)
{

    NSMutableString* tagName=[[[node tagName]lowercaseString]mutableCopy];
    if([tagName length]<=0)return @"";
    
    NSString* className=[node className];
    NSString* idName=[node idName];
    if([idName length]>0){
        [tagName appendFormat:@" id=\"%@\"",idName];
    }
    if([className length]>0){
        [tagName appendFormat:@" class=\"%@\"",className];
    }
    return tagName;
}



@implementation HTDOMElementHierarchyMenuItem



- (id)initWithTitle:(NSString *)aString targetView:(WebView*)view
{
    self = [super initWithTitle:aString action:nil keyEquivalent:@""];
    if (self != nil) {
        _view=view;
        _savedDOMRange=[_view selectedDOMRange];
    }
    return self;

}

/*
- (void)setSubmenu:(NSMenu *)submenu;
{
    [super setSubmenu:submenu];
    [submenu setDelegate:self];
}*/
- (void) dealloc
{
    [self cleanupHiliter];
}


- (void)cleanupHiliter
{
//    NSLog(@"cleanupHiliter");
    if(_savedDOMRange){
        [_view setSelectedDOMRange:_savedDOMRange affinity:NSSelectionAffinityDownstream];
        _savedDOMRange=nil;
    }
}


- (void)hiliteNode:(id)node
{
    if (![_view window])return;
    

    if(_hiliter==nil){
        
        
        //メニュー閉じるのを検知できない（menuWillClose: や NSMenuDidEndTrackingNotification 来ず）ので投げておく。
        //メニュー閉じた後で投げられるはず。
        //メニューは次回メニュー表示時かwebViewを閉じた時に開放される
        [self performSelector:@selector(cleanupHiliter) withObject:nil afterDelay:0];
        
    }
    //
    DOMRange* domrange=[[node ownerDocument] createRange];
    [domrange selectNode:node];
    [_view setSelectedDOMRange:_savedDOMRange affinity:NSSelectionAffinityDownstream];
    [_view setNeedsDisplay:YES];
}

- (void)menu:(NSMenu *)menu willHighlightItem:(NSMenuItem *)item
{

    id node=[item representedObject];
    if(node){
    
//        [self hiliteNode:node];
    }else if(_hiliter){
    
    }
}


@end
