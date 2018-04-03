//
//  HRPGToDoTableViewController.m
//  HabitRPG
//
//  Created by Phillip Thelen on 08/03/14.
//  Copyright © 2017 HabitRPG Inc. All rights reserved.
//

#import "HRPGToDoTableViewController.h"
#import "ChecklistItem.h"
#import "HRPGCheckBoxView.h"
#import "Habitica-Swift.h"

@interface HRPGToDoTableViewController ()
@property NSString *readableName;
@property NSString *typeName;
@property NSDateFormatter *dateFormatter;
@property NSIndexPath *expandedIndexPath;
@end

@implementation HRPGToDoTableViewController

@dynamic readableName;
@dynamic typeName;

- (void)viewDidLoad {
    self.readableName = NSLocalizedString(@"To-Do", nil);
    self.typeName = @"todo";
    self.dataSource = [TodoTableViewDataSourceInstantiator instantiateWithPredicate:[self getPredicate]];
    [super viewDidLoad];

    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    self.dateFormatter.timeStyle = NSDateFormatterNoStyle;

    self.tutorialIdentifier = @"todos";
}

- (void)refresh {
    [super refresh];
    [[HRPGManager sharedManager] fetchCompletedTasks:nil onError:nil];
}
- (NSDictionary *)getDefinitonForTutorial:(NSString *)tutorialIdentifier {
    if ([tutorialIdentifier isEqualToString:@"todos"]) {
        return @{
            @"textList" : @[NSLocalizedString(@"Use To-Dos to keep track of tasks you need to do just once.", nil),
                            NSLocalizedString(@"If your To-Do has to be done by a certain time, set a due date. Looks like you can check one off — go ahead!", nil)]
                            
        };
    }
    return [super getDefinitonForTutorial:tutorialIdentifier];
}

- (NSString *)getCellNibName {
    return @"ToDoTableViewCell";
}

- (void)clearCompletedTasks:(UITapGestureRecognizer *)tapRecognizer {
    [[HRPGManager sharedManager] clearCompletedTasks:^() {
        [[HRPGManager sharedManager] fetchUser:nil onError:nil];
    } onError:nil];
}

- (void)didChangeFilter:(NSNotification *)notification {
    [super didChangeFilter:notification];
    if (self.filterType == TaskToDoFilterTypeDone) {
        /*if ([self.fetchedResultsController fetchedObjects].count == 0) {
            [[HRPGManager sharedManager] fetchCompletedTasks:nil onError:nil];
        }*/
    }
}

@end
