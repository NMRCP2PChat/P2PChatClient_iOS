//
//  MyFetchedResultsControllerDelegate.m
//  ZXKChat_2
//
//  Created by xiaokun on 15/12/20.
//  Copyright © 2015年 xiaokun. All rights reserved.
//

#import "MyFetchedResultsControllerDelegate.h"

@interface MyFetchedResultsControllerDelegate ()

@property (strong, nonatomic) UITableView *tableView;
@property (weak, nonatomic) NSFetchedResultsController *controller;

@end

@implementation MyFetchedResultsControllerDelegate

- (id)initWithTableView:(UITableView *)tableView {
    self = [super init];
    _tableView = tableView;
    return self;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [_tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    
    switch(type) {
        case NSFetchedResultsChangeInsert:{
            [_tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
            break;
            
        case NSFetchedResultsChangeDelete:
            [_tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationBottom];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeMove:
            [_tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationBottom];
            [_tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationTop];
            break;
    }
    [_tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    _controller = controller;
    [_tableView endUpdates];
    [self scrollToBottom];
}

- (void)scrollToBottom {
    NSArray *sections = _controller.sections;
    if (sections.count <= 0) return;
    id<NSFetchedResultsSectionInfo> sectionInfo = sections[0];
    if (sectionInfo.numberOfObjects > 1) {
        [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:sectionInfo.numberOfObjects - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}
@end
