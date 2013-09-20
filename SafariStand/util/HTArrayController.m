//
//  HTArrayController.m
//  SafriStand


#import "HTArrayController.h"
#import <objc/objc-runtime.h>
#import "NSString+HTUtil.h"


@implementation HTArrayController

- (void)dealloc {

	[_pasteboardType release];
    [super dealloc];
}
- (void)awakeFromNib
{

    _pasteboardType=[[NSString HTUUIDStringWithFormat:@"%@_pbType"]retain];
    
	if([_pasteboardType length]>0){
		[oTableView registerForDraggedTypes:[NSArray arrayWithObjects:_pasteboardType, nil]];
		[oCollectionView registerForDraggedTypes:[NSArray arrayWithObjects:_pasteboardType, nil]];
	}
}


-(id)delegate
{
	return delegate;
}


-(NSTableView*)tableView
{
	return oTableView;
}
- (void)add:(id)sender
{
    id  newObject=nil;
    
    if([delegate respondsToSelector:@selector(defaultObjecOfHTArrayController:)]){
        newObject=objc_msgSend(delegate, @selector(defaultObjecOfHTArrayController:), self);
        //[delegate defaultObjecOfHTArrayController:self];
    }
    if(newObject){
        [super addObject:newObject];
    }else{
        [super add:sender];
    }
}


//drag & drop


- (BOOL)writeItemsAtIndexes:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pasteboard
{
    if(_pasteboardType==nil || [indexes count]>1)    return NO;
    [pasteboard setString:[NSString stringWithFormat: @"%ld",[indexes firstIndex]] forType:_pasteboardType];
    return YES;

}

- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
    return [self writeItemsAtIndexes:rowIndexes toPasteboard:pboard];

}
- (BOOL)collectionView:(NSCollectionView *)collectionView writeItemsAtIndexes:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pasteboard
{
    return [self writeItemsAtIndexes:indexes toPasteboard:pasteboard];

}



- (NSDragOperation)validateDrop:(id <NSDraggingInfo>)draggingInfo proposedIndex:(NSInteger)proposedDropIndex dropOperation:(NSCollectionViewDropOperation)proposedDropOperation
{
    if(_pasteboardType==nil)    return NSDragOperationNone;
    
    NSPasteboard *pb = [draggingInfo draggingPasteboard];
    NSInteger draggedRow = [[pb stringForType:_pasteboardType]intValue];
    
    if (proposedDropOperation == NSTableViewDropOn || proposedDropIndex == draggedRow || proposedDropIndex == draggedRow + 1)
        return NSDragOperationNone;
    return NSDragOperationMove;
}


- (NSDragOperation)tableView:(NSTableView*)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation;
{
    return [self validateDrop:info proposedIndex:row dropOperation:operation];
}

- (NSDragOperation)collectionView:(NSCollectionView *)collectionView validateDrop:(id <NSDraggingInfo>)draggingInfo proposedIndex:(NSInteger *)proposedDropIndex dropOperation:(NSCollectionViewDropOperation *)proposedDropOperation
{
    return [self validateDrop:draggingInfo proposedIndex:*proposedDropIndex dropOperation:*proposedDropOperation];
}



- (NSInteger)acceptDrop:(id <NSDraggingInfo>)info toIndex:(NSInteger)row
{
    NSInteger droppedIndex=-1;
    if(_pasteboardType==nil) return -1;

    NSPasteboard *pb = [info draggingPasteboard];
    int draggedIndex = [[pb stringForType: _pasteboardType ] intValue];
    
    if(draggedIndex==row) return -1;

    //[[self content] insertObject:[[self content] objectAtIndex:draggedIndex]atIndex: row];
    
    id target=[[[self arrangedObjects]objectAtIndex:draggedIndex]retain];
    //[self removeObject:target];// equalTo: なやつまで削除されてしまう
    [self removeObjectAtArrangedObjectIndex:draggedIndex];
    
    if (row < draggedIndex){
        //[[self content] removeObjectAtIndex: draggedIndex+1];
        droppedIndex=row;
    }else{
        //[[self content] removeObjectAtIndex: draggedIndex];
        droppedIndex=row-1;
    }

    [self insertObject:target atArrangedObjectIndex:droppedIndex];
    [target release];
    
    return droppedIndex;
}

- (BOOL)tableView:(NSTableView*)tableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation
{
    NSInteger droppedIndex=[self acceptDrop:info toIndex:row];
    if(droppedIndex<0)return NO;

    //[tableView reloadData];
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:droppedIndex] byExtendingSelection:NO];

    return YES;
}

- (BOOL)collectionView:(NSCollectionView *)collectionView acceptDrop:(id < NSDraggingInfo >)draggingInfo index:(NSInteger)index dropOperation:(NSCollectionViewDropOperation)dropOperation
{
    NSInteger droppedIndex=[self acceptDrop:draggingInfo toIndex:index];
    if(droppedIndex<0)return NO;
    
    [collectionView setSelectionIndexes:[NSIndexSet indexSetWithIndex:droppedIndex]];
    return YES;
}

- (BOOL)collectionView:(NSCollectionView *)collectionView canDragItemsAtIndexes:(NSIndexSet *)indexes withEvent:(NSEvent *)event
{
    if(_pasteboardType==nil||[indexes count]>1) return NO;
    return YES;

}
@end
