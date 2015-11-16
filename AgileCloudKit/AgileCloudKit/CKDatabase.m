//
//  CKDatabase.h
//  CloudKit
//
//  Copyright (c) 2014 Apple Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <AgileCloudKit/AgileCloudKit.h>
#import "JSValue+AgileCloudKitExtensions.h"
#import "CKDatabase_Private.h"
#import "CKMediator_Private.h"
#import "Defines.h"
#import "CKRecordID+AgileDictionary.h"
#import "CKRecord+AgileDictionary.h"
#import "CKSubscription+AgileDictionary.h"
#import "CKSubscription_Private.h"
#import "CKRecord_Private.h"
#import "CKContainer_Private.h"
#import "CKBlockOperation.h"

@implementation CKDatabase {
    BOOL _public;
    CKContainer *_container;
}

- (instancetype)initWithContainer:(CKContainer *)container isPublic:(BOOL) public
{
    if (self = [super init]) {
        _public = public;
        _container = container;
    }
    return self;
}

- (CKContainer *)container
{
    return _container;
}

- (BOOL)isPublic
{
    return _public;
}

- (void)addOperation:(CKOperation *)operation
{
    [[[CKMediator sharedMediator] queue] addOperation:operation];
}

- (JSValue *)asJSValue
{
    if (![[CKMediator sharedMediator] isInitialized]) {
        @throw [NSException exceptionWithName:@"CannotUseContainerUntilInitialized" reason:@"Before using this container, CKMediator must be initialized" userInfo:nil];
    }
    __block JSValue *value;
    void (^block)() = ^{
        if (self.isPublic) {
            value = [[[self container] asJSValue] valueForProperty:@"publicCloudDatabase"];
        } else {
            value = [[[self container] asJSValue] valueForProperty:@"privateCloudDatabase"];
        }
    };
    if (![NSThread isMainThread]) {
        dispatch_sync(dispatch_get_main_queue(), block);
    } else {
        block();
    }
    return value;
}

- (void)fetchRecordWithID:(CKRecordID *)recordID completionHandler:(void (^)(CKRecord *record, NSError *error))completionHandler
{
    CKFetchRecordsOperation *recOp = [[CKFetchRecordsOperation alloc] initWithRecordIDs:@[recordID]];
    recOp.fetchRecordsCompletionBlock = ^(NSDictionary *dict, NSError *err) {
        if(err){
            NSError* recErr = err.userInfo[@"CKPartialErrors"][recordID];
            completionHandler(nil, recErr);
        }else{
            completionHandler([dict allValues][0], nil);
        }
    };
    [self addOperation:recOp];
}

- (void)saveRecord:(CKRecord *)record completionHandler:(void (^)(CKRecord *record, NSError *error))completionHandler
{
    CKModifyRecordsOperation *modOp = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:@[record] recordIDsToDelete:nil];
    modOp.modifyRecordsCompletionBlock = ^(NSArray /* CKRecord */ *savedRecords, NSArray /* CKRecordID */ *deletedRecordIDs, NSError *operationError) {
        if(operationError){
            completionHandler(nil, operationError);
        }else{
            completionHandler(savedRecords[0], nil);
        }
    };
    [self addOperation:modOp];
}

- (void)deleteRecordWithID:(CKRecordID *)recordID completionHandler:(void (^)(CKRecordID *recordID, NSError *error))completionHandler
{
    CKModifyRecordsOperation *modOp = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:nil recordIDsToDelete:@[recordID]];
    modOp.modifyRecordsCompletionBlock = ^(NSArray /* CKRecord */ *savedRecords, NSArray /* CKRecordID */ *deletedRecordIDs, NSError *operationError) {
        if(operationError){
            completionHandler(nil, operationError);
        }else{
            completionHandler(deletedRecordIDs[0], nil);
        }
    };
    [self addOperation:modOp];
}


- (void)performQuery:(CKQuery *)query inZoneWithID:(CKRecordZoneID *)zoneID completionHandler:(void (^)(NSArray /* CKRecord */ *results, NSError *error))completionHandler
{
    @throw kAbstractMethodException;
}


- (void)fetchAllRecordZonesWithCompletionHandler:(void (^)(NSArray /* CKRecordZone */ *zones, NSError *error))completionHandler
{
    CKBlockOperation *blockOp = [[CKBlockOperation alloc] initWithBlock:^(void (^opCompletionBlock)()) {
        [[[[self asJSValue] agile_invokeMethod:@"fetchAllRecordZones"] invokeMethod:@"then" withArguments:@[^(id response) {
            if([response[@"_errors"] count]){
                NSError* error = [[NSError alloc] initWithCKErrorDictionary:response[@"_errors"][0]];
                completionHandler(nil, error);
            }else{
                NSMutableArray* zones = [NSMutableArray array];
                for (NSDictionary* dict in (response[@"_zones"] ?: response[@"_results"])) {
                    [zones addObject:[[CKRecordZone alloc] initWithZoneName:dict[@"zoneID"][@"zoneName"]]];
                }
                completionHandler(zones, nil);
            }
            opCompletionBlock();
        }]] invokeMethod:@"catch"
         withArguments:@[^(NSDictionary *err) {
            NSError* error = [[NSError alloc] initWithCKErrorDictionary:err];
            completionHandler(nil, error);
            opCompletionBlock();
        }]];
    }];
    [[[CKMediator sharedMediator] queue] addOperation:blockOp];
}

- (void)fetchRecordZoneWithID:(CKRecordZoneID *)zoneID completionHandler:(void (^)(CKRecordZone *zone, NSError *error))completionHandler
{
    CKBlockOperation *blockOp = [[CKBlockOperation alloc] initWithBlock:^(void (^opCompletionBlock)()) {
        [[[[self asJSValue] invokeMethod:@"fetchRecordZone" withArguments:@[@{ @"zoneName": zoneID.zoneName }]] invokeMethod:@"then" withArguments:@[^(id response) {
            if([response[@"_errors"] count]){
                NSError* error = [[NSError alloc] initWithCKErrorDictionary:response[@"_errors"][0]];
                completionHandler(nil, error);
            }else{
                NSMutableArray* zones = [NSMutableArray array];
                for (NSDictionary* dict in (response[@"_zones"] ?: response[@"_results"])) {
                    [zones addObject:[[CKRecordZone alloc] initWithZoneName:dict[@"zoneID"][@"zoneName"]]];
                }
                completionHandler(zones[0], nil);
            }
            opCompletionBlock();
        }]] invokeMethod:@"catch"
         withArguments:@[^(NSDictionary *err) {
            NSError* error = [[NSError alloc] initWithCKErrorDictionary:err];
            completionHandler(nil, error);
            opCompletionBlock();
        }]];
    }];
    [[[CKMediator sharedMediator] queue] addOperation:blockOp];
}

- (void)saveRecordZone:(CKRecordZone *)zone completionHandler:(void (^)(CKRecordZone *zone, NSError *error))completionHandler
{
    CKBlockOperation *blockOp = [[CKBlockOperation alloc] initWithBlock:^(void (^opCompletionBlock)()) {
        [[[[self asJSValue] invokeMethod:@"saveRecordZone" withArguments:@[@{ @"zoneName": zone.zoneID.zoneName }]] invokeMethod:@"then" withArguments:@[^(id response) {
            if([response[@"_errors"] count]){
                NSError* error = [[NSError alloc] initWithCKErrorDictionary:response[@"_errors"][0]];
                completionHandler(nil, error);
            }else{
                NSMutableArray* zones = [NSMutableArray array];
                for (NSDictionary* dict in (response[@"_zones"] ?: response[@"_results"])) {
                    [zones addObject:[[CKRecordZone alloc] initWithZoneName:dict[@"zoneID"][@"zoneName"]]];
                }
                completionHandler(zones[0], nil);
            }
            opCompletionBlock();
        }]] invokeMethod:@"catch"
         withArguments:@[^(NSDictionary *err) {
            NSError* error = [[NSError alloc] initWithCKErrorDictionary:err];
            completionHandler(nil, error);
            opCompletionBlock();
        }]];
    }];
    [[[CKMediator sharedMediator] queue] addOperation:blockOp];
}

- (void)deleteRecordZoneWithID:(CKRecordZoneID *)zoneID completionHandler:(void (^)(CKRecordZoneID *zoneID, NSError *error))completionHandler
{
    CKModifyRecordZonesOperation *delOp = [[CKModifyRecordZonesOperation alloc] initWithRecordZonesToSave:nil recordZoneIDsToDelete:@[zoneID]];
    delOp.modifyRecordZonesCompletionBlock = ^(NSArray *savedRecordZones, NSArray *deletedRecordZoneIDs, NSError *operationError) {
        if(operationError){
            completionHandler(nil, operationError);
        }else{
            completionHandler(zoneID, nil);
        }
    };
    [self addOperation:delOp];
}


- (void)fetchSubscriptionWithID:(NSString *)subscriptionID completionHandler:(void (^)(CKSubscription *subscription, NSError *error))completionHandler
{
    @throw kAbstractMethodException;
}

- (void)fetchAllSubscriptionsWithCompletionHandler:(void (^)(NSArray /* CKSubscription */ *subscriptions, NSError *error))completionHandler
{
    CKBlockOperation *blockOp = [[CKBlockOperation alloc] initWithBlock:^(void (^opCompletionBlock)()) {
        [[[[self asJSValue] agile_invokeMethod:@"fetchAllSubscriptions"] invokeMethod:@"then" withArguments:@[^(id response) {
            if([response[@"_errors"] count]){
                NSError* error = [[NSError alloc] initWithCKErrorDictionary:response[@"_errors"][0]];
                completionHandler(nil, error);
            }else{
                NSMutableArray* subs = [NSMutableArray array];
                for (NSDictionary* dict in (response[@"_subscriptions"] ?: response[@"_results"])) {
                    [subs addObject:[[CKSubscription alloc] initWithDictionary:dict]];
                }
                completionHandler(subs, nil);
            }
            opCompletionBlock();
        }]] invokeMethod:@"catch"
         withArguments:@[^(NSDictionary *err) {
            NSError* error = [[NSError alloc] initWithCKErrorDictionary:err];
            completionHandler(nil, error);
            opCompletionBlock();
        }]];
    }];
    [[[CKMediator sharedMediator] queue] addOperation:blockOp];
}

- (void)saveSubscription:(CKSubscription *)subscription completionHandler:(void (^)(CKSubscription *subscription, NSError *error))completionHandler
{
    CKModifySubscriptionsOperation *modOp = [[CKModifySubscriptionsOperation alloc] initWithSubscriptionsToSave:@[subscription] subscriptionIDsToDelete:nil];
    modOp.modifySubscriptionsCompletionBlock = ^(NSArray *savedSubscriptions, NSArray *deletedSubscriptionIDs, NSError *operationError) {
        if(operationError){
            completionHandler(nil, operationError);
        }else{
            completionHandler(savedSubscriptions[0], nil);
        }
    };
    [self addOperation:modOp];
}

- (void)deleteSubscriptionWithID:(NSString *)subscriptionID completionHandler:(void (^)(NSString *subscriptionID, NSError *error))completionHandler
{
    CKBlockOperation *blockOp = [[CKBlockOperation alloc] initWithBlock:^(void (^opCompletionBlock)()) {
        [[[[self asJSValue] invokeMethod:@"deleteSubscription" withArguments:@[@{ @"subscriptionID": subscriptionID }]] invokeMethod:@"then" withArguments:@[^(id response) {
            if([response[@"_errors"] count]){
                NSError* error = [[NSError alloc] initWithCKErrorDictionary:response[@"_errors"][0]];
                completionHandler(nil, error);
            }else{
                completionHandler(subscriptionID, nil);
            }
            opCompletionBlock();
        }]] invokeMethod:@"catch"
         withArguments:@[^(id err) {
            NSError* error = [[NSError alloc] initWithCKErrorDictionary:err];
            completionHandler(nil, error);
            opCompletionBlock();
        }]];
    }];
    [[[CKMediator sharedMediator] queue] addOperation:blockOp];
}


#pragma mark - Web Services


- (void)sendPOSTRequestTo:(NSString *)fragment withJSON:(id)postData completionHandler:(void (^)(id jsonResponse, NSError *error))completionHandler
{
    NSString *fetchURLString = [NSString stringWithFormat:@"https://api.apple-cloudkit.com/database/1/%@/%@/%@/%@?ckAPIToken=%@&ckSession=%@",
                                                          self.container.cloudKitContainerName,
                                                          self.container.cloudKitEnvironment,
                                                          self.isPublic ? @"public" : @"private",
                                                          fragment,
                                                          self.container.cloudKitAPIToken,
                                                          [CKContainer percentEscape:[CKMediator sharedMediator].sessionToken]];

    [CKContainer sendPOSTRequestTo:[NSURL URLWithString:fetchURLString] withJSON:postData completionHandler:completionHandler];
}


@end