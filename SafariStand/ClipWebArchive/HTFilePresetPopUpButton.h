//
//  HTFilePresetPopUpButton.h

#import <Cocoa/Cocoa.h>


//#define HTFilePresetPopUpButtonCurrentValue @"HTFilePresetPopUpButtonCurrentValue"
//#define HTFilePresetPopUpButtonAllValues @"HTFilePresetPopUpButtonAllValues"

@interface HTFilePresetPopUpButton : NSPopUpButton {
    NSString* _identifier;
    NSInteger _savedIndex;
}


- (void)setupWithIdentifier:(NSString *)identifier preset:(NSArray*)preset;

- (NSInteger)valuesCacheLimit;
- (NSString *)selectedFilePath;
- (NSString *)presetIdentifier;
- (void)setPresetIdentifier:(NSString *)identifier;

- (void)addFilePath:(NSString *)path select:(BOOL)select;


- (NSString*)currentValueFromPref;
- (NSArray*)allValuesFromPref;
- (void)setCurrentValuePref:(NSString*)path;
- (void)setAllValuesPref:(NSArray*)ary;

@end
