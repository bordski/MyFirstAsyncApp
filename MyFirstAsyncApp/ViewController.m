//
//  ViewController.m
//  MyFirstAsyncApp
//
//  Created by Michael Xernan Bordonada on 6/11/15.
//  Copyright (c) 2015 Michael Xernan Bordonada. All rights reserved.
//

#import "ViewController.h"
#import "ContactModel.h"

#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import <AsyncDisplayKit/ASAssert.h>

#import <AddressBook/AddressBook.h>

@interface ViewController ()<ASTableViewDataSource, ASTableViewDelegate> {
    ASTableView *_tableView;
}

#pragma mark - Private Property Declarations

@property (nonatomic, strong) NSMutableArray *contactCollection;
@property (nonatomic, readonly) ABAddressBookRef addressbookReference;

@end

@implementation ViewController

#pragma mark - Private Synthesizers

@synthesize contactCollection = _contactCollection;


#pragma mark - Private View Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _tableView = [[ASTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];

//    _tableView = [[ASTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain asyncDataFetching:YES];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone; // KittenNode has its own separator
    _tableView.asyncDataSource = self;
    _tableView.asyncDelegate = self;
}

#pragma mark - Memory Management Handler

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Models

#pragma mark ContactModel

#pragma mark - Model Creation handler

- (ContactModel *)createContactModelUsingABRecordRef:(ABRecordRef)rawContact {
    ContactModel *contact = [[ContactModel alloc] init];
    
    ABMutableMultiValueRef raweMail = ABRecordCopyValue(rawContact, kABPersonEmailProperty);
    ABMutableMultiValueRef rawMobilenumber = ABRecordCopyValue(rawContact, kABPersonPhoneProperty);
    
    contact.isSelected = TRUE;
    contact.contactID = [NSNumber numberWithInt:ABRecordGetRecordID(rawContact)];
    contact.firstname = (__bridge NSString *)ABRecordCopyValue(rawContact, kABPersonFirstNameProperty);
    contact.lastname = (__bridge NSString *)ABRecordCopyValue(rawContact, kABPersonLastNameProperty);
    contact.emailCollection = (__bridge NSArray *)ABMultiValueCopyArrayOfAllValues(raweMail);
    contact.numberCollection = (__bridge NSArray *)ABMultiValueCopyArrayOfAllValues(rawMobilenumber);
    NSString *base64PhotoString = (__bridge NSString *)ABRecordCopyValue(rawContact, kABPersonImageFormatThumbnail);
    if (base64PhotoString != nil) {
        contact.photoData = [[NSData alloc] initWithBase64EncodedString:base64PhotoString options:NSDataBase64DecodingIgnoreUnknownCharacters];
    }
    return contact;
}


#pragma mark - Addressbook

- (void)fetchAndInsertContacsToArray:(NSMutableArray *)array {
    @autoreleasepool {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            
            NSArray *rawContactCollection = (__bridge NSArray *)ABAddressBookCopyArrayOfAllPeople(self.addressbookReference);
            
            [rawContactCollection enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                
                ABRecordRef rawContact = (__bridge ABRecordRef)obj;
                
                ContactModel *contact = [self createContactModelUsingABRecordRef:rawContact];
                
                BOOL contactHasName = FALSE;
                
                if ([contact.firstname isEqualToString:@""] == FALSE) {
                    contactHasName = TRUE;
                } else if ([contact.lastname isEqualToString:@""] == FALSE) {
                    contactHasName = TRUE;
                }
                
                if (contactHasName) {
                    [self insertNewCellUsingValues:contact];
                } else if (contact.emailCollection.count > 0) {
                     //has email
                     [self insertNewCellUsingValues:contact];
                } else if (contact.numberCollection.count > 0) {
                     //has number
                     [self insertNewCellUsingValues:contact];
                }
                
            }];
        });
    }
}


#pragma mark Addressbook Request Handler
- (void)requestAddressbookPermission {
    @autoreleasepool {
        ABAddressBookRequestAccessWithCompletion(ABAddressBookCreateWithOptions(NULL, nil), ^(bool granted, CFErrorRef error) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                if (granted == TRUE) {
                    //                    [self createDummyData];
                    [self fetchAndInsertContacsToArray:self.contactCollection];
                } else {
                    NSLog(@"Application needs to access the addressbook in order for it to run properly, please allow access");
                }
            });
        });
    }
}

- (void)insertNewCellUsingValues:(ContactModel *)values {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        NSUInteger nextIndex = self.contactCollection.count;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:nextIndex inSection:0];
        NSArray *indexPaths = [NSArray arrayWithObject:indexPath];
        
        NSPredicate *checkIfContactExists = [NSPredicate predicateWithFormat:@"SELF.contactID = %@", values.contactID];
        if ([self.contactCollection filteredArrayUsingPredicate:checkIfContactExists].count == 0) {
            [self.contactCollection insertObject:values atIndex:self.contactCollection.count];
        }
        
        [_tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
        
        
    });
    
    
}

#pragma mark - Table View Data Source

- (ASCellNode *)tableView:(ASTableView *)tableView nodeForRowAtIndexPath:(NSIndexPath *)indexPath {
    
}



@end
