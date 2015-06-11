//
//  ContactModel.h
//  ImportContactsPrototype
//
//  Created by Michael Xernan Bordonada on 5/6/15.
//  Copyright (c) 2015 Michael Xernan Bordonada. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ContactModel : NSObject

//selection variables
@property (nonatomic, assign) BOOL isSelected;

//contact information variables
@property (nonatomic, strong) NSNumber *contactID;
@property (nonatomic, strong) NSString *firstname;
@property (nonatomic, strong) NSString *lastname;
@property (nonatomic, strong) NSArray *emailCollection;
@property (nonatomic, strong) NSArray *numberCollection;

@property (nonatomic, strong) NSData *photoData;


@property (nonatomic, strong) NSString *contactRepresentation;
@property (nonatomic, strong) NSMutableDictionary *contactDictionaryRepresentation;


@end
