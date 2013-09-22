//
//  HTFilePresetPopUpButton.h

#import <Cocoa/Cocoa.h>


//#define HTFilePresetPopUpButtonCurrentValue @"HTFilePresetPopUpButtonCurrentValue"
//#define HTFilePresetPopUpButtonAllValues @"HTFilePresetPopUpButtonAllValues"

@interface HTFilePresetPopUpButton : NSPopUpButton {
    NSInteger _savedIndex;
}

@property (nonatomic, strong) NSString* presetIdentifier;

- (void)setupWithIdentifier:(NSString *)identifier preset:(NSArray*)preset;

- (NSInteger)valuesCacheLimit;
- (NSString *)selectedFilePath;

- (void)addFilePath:(NSString *)path select:(BOOL)select;


- (NSString*)currentValueFromPref;
- (NSArray*)allValuesFromPref;
- (void)setCurrentValuePref:(NSString*)path;
- (void)setAllValuesPref:(NSArray*)ary;

@end
