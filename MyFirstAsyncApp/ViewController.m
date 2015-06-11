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
#import <ASCellNode.h>
#import <AddressBook/AddressBook.h>

@interface ViewController ()<ASTableViewDataSource, ASTableViewDelegate> {
    ASTableView *_tableView;
}

#pragma mark - Private Property Declarations

@property (nonatomic, strong) NSMutableArray *contactCollection;
@property (nonatomic, readonly) ABAddressBookRef addressbookReference;

@property (atomic, assign) BOOL dataSourceLocked;

@end

@implementation ViewController

#pragma mark - Private Synthesizers

@synthesize contactCollection = _contactCollection;
@synthesize addressbookReference = _addressbookReference;

#pragma mark - Overridden Getters 

- (NSMutableArray *)contactCollection {
    if (_contactCollection == nil) {
        _contactCollection = @[].mutableCopy;
    }
    
    return _contactCollection;
}

//addressbook getters
- (ABAddressBookRef)addressbookReference {
    if (_addressbookReference == nil) {
        _addressbookReference = ABAddressBookCreateWithOptions(NULL, nil);
    }
    
    return _addressbookReference;
}


#pragma mark - Private View Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _tableView = [[ASTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];

//    _tableView = [[ASTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain asyncDataFetching:YES];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone; // KittenNode has its own separator
    _tableView.asyncDataSource = self;
    _tableView.asyncDelegate = self;
    
    [self.view addSubview:_tableView];
}

- (void)viewWillAppear:(BOOL)animated {
    [self requestAddressbookPermission];
}

- (void)viewWillLayoutSubviews
{
    _tableView.frame = self.view.bounds;
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
    NSLog(@"firstname:%@", contact.firstname);
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

#pragma mark - Table View

#pragma mark Table View Cells

- (void)insertNewCellUsingValues:(ContactModel *)values {
    @autoreleasepool {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSPredicate *checkIfContactExists = [NSPredicate predicateWithFormat:@"SELF.contactID = %@", values.contactID];
            if ([self.contactCollection filteredArrayUsingPredicate:checkIfContactExists].count == 0) {
                NSUInteger nextIndex = self.contactCollection.count;
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:nextIndex inSection:0];
                NSArray *indexPaths = [NSArray arrayWithObject:indexPath];
                [self.contactCollection insertObject:values atIndex:nextIndex];
                
                [_tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
            }
            
            checkIfContactExists = nil;
            
        });
    }
}

#pragma mark Table View Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.contactCollection.count;
}


- (ASCellNode *)tableView:(ASTableView *)tableView nodeForRowAtIndexPath:(NSIndexPath *)indexPath {
    @autoreleasepool {
        ASTextCellNode *cellNode = [[ASTextCellNode alloc] init];
        ContactModel *model = self.contactCollection[indexPath.row];
        cellNode.text = [NSString stringWithFormat:@"%@-%@", model.firstname, model.lastname];
        model = nil;
        return cellNode;
    }
}

- (void)tableViewLockDataSource:(ASTableView *)tableView
{
    self.dataSourceLocked = YES;
}

- (void)tableViewUnlockDataSource:(ASTableView *)tableView
{
    self.dataSourceLocked = NO;
}

- (BOOL)shouldBatchFetchForTableView:(UITableView *)tableView
{
    return NO;
}






@end
