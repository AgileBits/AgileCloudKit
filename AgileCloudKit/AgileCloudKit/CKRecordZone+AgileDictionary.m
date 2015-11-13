//
//  CKRecordZone+AgileDictionary.m
//  AgileCloudKit
//
//  Created by Adam Wulf on 10/15/15.
//  Copyright © 2015 AgileBits. All rights reserved.
//

#import "CKRecordZone+AgileDictionary.h"
#import "CKRecordZoneID+AgileDictionary.h"

@implementation CKRecordZone (AgileDictionary)

- (NSDictionary *)asAgileDictionary
{
    return @{ @"zoneID": [self.zoneID asAgileDictionary] };
}

@end
