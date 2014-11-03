//
//  HTDOMElementHierarchyMenuItem.h
//  SafariStand
 

@import AppKit;

NSString* HTDescriptionDOMHTMLElement(id node);
NSMenuItem* HTDOMHTMLElementHierarchyMenuItemRetained(id node, NSString* title, SEL itemSelector, id target, BOOL includeBody);

@interface HTDOMElementHierarchyMenuItem : NSMenuItem {
    WebView* _view;
    id _hiliter;
    id _savedDOMRange;
}
- (id)initWithTitle:(NSString *)aString targetView:(WebView*)view;
- (void)cleanupHiliter;
@end
