//
//  HTFilePresetPopUpButton.m

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import "HTFilePresetPopUpButton.h"


@implementation HTFilePresetPopUpButton
static NSString* HTFilePresetPopUpButtonCurrentValue= @"HTFilePresetPopUpButtonCurrentValue_";
static NSString* HTFilePresetPopUpButtonAllValues= @"HTFilePresetPopUpButtonAllValues_";

- (NSImage*)iconForFile:(NSString*)path
{
    //if(![[NSFileManager defaultManager]fileExistsAtPath:path])return nil;
    
    NSImage* image=[[NSWorkspace sharedWorkspace]iconForFile:path];
    if(image){
        [image setSize:NSMakeSize(16,16)];
    }
    return image;
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        _savedIndex=-1;
        self.presetIdentifier=nil;
    }
    return self;
}

- (void)dealloc
{

}


//must call this first. in awakeFromNib etc...
// identifier   prefix of preferences value that stores NSUserDefaults
// preset       default items
- (void)setupWithIdentifier:(NSString *)identifier preset:(NSArray*)preset
{
    [self removeAllItems];
    self.presetIdentifier=identifier;
    NSArray* allValues=[self allValuesFromPref];
    NSString* currentValue=[self currentValueFromPref];
    NSInteger i, cnt=[allValues count];
    
    if(cnt<=0){
        cnt=[preset count];
        allValues=preset;
    }
    for (i=0; i<cnt; i++) {
        NSString* path=[allValues objectAtIndex:i];
        
        if([[NSFileManager defaultManager]fileExistsAtPath:path]){
            NSString* title=[path lastPathComponent];
            NSMenuItem* item=[[self menu]addItemWithTitle:title action:@selector(actPathItemSelected:) keyEquivalent:@""];
            [item setRepresentedObject:path];
            [item setTarget:self];
            [item setImage:[self iconForFile:path]];
            if(currentValue && [path isEqualToString:currentValue]){
                [self selectItem:item];
                _savedIndex=[self indexOfSelectedItem];
                currentValue=nil;
            }
        }
    }
    
    if(currentValue && [[NSFileManager defaultManager]fileExistsAtPath:currentValue]){
        NSString* title=[currentValue lastPathComponent];
        NSMenuItem* item=[[self menu]insertItemWithTitle:title action:@selector(actPathItemSelected:) keyEquivalent:@"" atIndex:0];
        [item setRepresentedObject:currentValue];
        [item setTarget:self];
        [item setImage:[self iconForFile:currentValue]];
        [self selectItem:item];
        _savedIndex=[self indexOfSelectedItem];
    }
    
    if([self numberOfItems]<=0){
        //[[self menu]addItemWithTitle:title action:@selector(actPathItemSelected:) keyEquivalent:@""];
    }
    
    
    [[self menu]addItem:[NSMenuItem separatorItem]];
    
    NSMenuItem* item=[[self menu]addItemWithTitle:@"Other..." action:@selector(actChooseFileItemSelected:) keyEquivalent:@""];
    [item setTarget:self];

}


- (void)actPathItemSelected:(id)sender
{

    _savedIndex=[self indexOfSelectedItem];
    [self setCurrentValuePref:[sender representedObject]];
}

- (void)actChooseFileItemSelected:(id)sender
{

    //choose file/folder
    //FIXME: currently folder only
    NSOpenPanel *openPanel=[NSOpenPanel openPanel];
    [openPanel setCanChooseFiles:NO];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setAllowsMultipleSelection:NO];


    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger returnCode){
        if(returnCode==NSFileHandlingPanelOKButton && [[openPanel URLs]count]>0){
            NSURL *url=[[openPanel URLs]objectAtIndex:0];
            NSString* path=[url path];
            [self addFilePath:path select:YES];
        }else{
            if(_savedIndex>=0 && [self numberOfItems]>_savedIndex){
                [self selectItemAtIndex:_savedIndex];
            }
        }
    }];
}


- (void)addFilePath:(NSString *)path select:(BOOL)select
{
    NSInteger exist=[self indexOfItemWithRepresentedObject:path];
    if(exist>=0){
        if(select)[self selectItemAtIndex:exist];
    }else{
        NSString* title=[path lastPathComponent];

        NSMenuItem* item=[[self menu]insertItemWithTitle:title action:@selector(actPathItemSelected:) keyEquivalent:@"" atIndex:0];
        [item setRepresentedObject:path];
        [item setTarget:self];
        [item setImage:[self iconForFile:path]];
        if(select)[self selectItem:item];
        
        
        NSArray* items=[self itemArray];
        NSMutableArray* prefValues=[NSMutableArray array];
        
        NSInteger i, count = [items count];
        NSInteger prefLimit=[self valuesCacheLimit];
        NSInteger prefCount=0;
        for (i = 0; i < count; i++) {
            NSMenuItem* item = [items objectAtIndex:i];
            NSString* path=[item representedObject];
            if(path){
                if(prefLimit > prefCount){
                    [prefValues addObject:path];
                    prefCount++;
                }else{
                    [[self menu] removeItem:item];
                }
            }
        }
        [self setAllValuesPref:prefValues];
    }
    
    [self setCurrentValuePref:path];
    
    
    if(select)_savedIndex=[self indexOfSelectedItem];

}

-(NSInteger)valuesCacheLimit
{
    return 5;
}

- (NSString *)selectedFilePath
{
    return [[self selectedItem]representedObject];
}

#pragma mark -
#pragma mark NSUserDefaults

- (NSString *)currentValuePrefKey
{
    if(self.presetIdentifier){
        return [HTFilePresetPopUpButtonCurrentValue stringByAppendingString:self.presetIdentifier];
    }
    return nil;
}


- (NSString *)allValuesPrefKey
{
    if(self.presetIdentifier){
        return [HTFilePresetPopUpButtonAllValues stringByAppendingString:self.presetIdentifier];
    
    }
    return nil;
}

- (NSString*)currentValueFromPref
{
    NSString* prefKey=[self currentValuePrefKey];
    if(prefKey){
        return [[NSUserDefaults standardUserDefaults]objectForKey:prefKey];
    }
    return nil;
}
- (NSArray*)allValuesFromPref
{
    NSString* prefKey=[self allValuesPrefKey];
    if(prefKey){
        return [[NSUserDefaults standardUserDefaults]objectForKey:prefKey];
    }
    return nil;
}

-(void)setCurrentValuePref:(NSString*)path
{
    NSString* prefKey=[self currentValuePrefKey];
    if(prefKey && path){
        [[NSUserDefaults standardUserDefaults]setObject:path forKey:prefKey];
    }
}

-(void)setAllValuesPref:(NSArray*)ary
{
    NSString* prefKey=[self allValuesPrefKey];
    if(prefKey && ary){
        [[NSUserDefaults standardUserDefaults]setObject:ary forKey:prefKey];
    }
}



@end
