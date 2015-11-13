//
//  CKAsset_Private.h
//  AgileCloudKit
//
//  Created by Adam Wulf on 9/12/15.
//  Copyright © 2015 AgileBits. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CKAsset.h"

@interface CKAsset (AgilePrivate)

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

- (void)updateWithDictionary:(NSDictionary *)dictionary;

- (void)downloadSynchronouslyWithProgressBlock:(void (^)(double progress))progressBlock;

- (void)uploadSynchronouslyIntoRecord:(CKRecord *)record andField:(NSString *)fieldName inDatabase:(CKDatabase *)database;

// after downloading synchronously, an asset will either
// have a fileURL or a downloadError set
@property(nonatomic, readonly, copy) NSError *downloadError;

@property(nonatomic, readonly) NSString *fileChecksum;
@property(nonatomic, readonly) NSString *referenceChecksum;
@property(nonatomic, readonly) NSUInteger fileSize;
@property(nonatomic, readonly) NSString *wrappingKey;
@property(nonatomic, readonly) NSString *receipt;

@end
