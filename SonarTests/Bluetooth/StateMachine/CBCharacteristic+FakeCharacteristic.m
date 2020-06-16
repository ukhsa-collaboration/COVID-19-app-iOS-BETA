//
//  CBCharacteristic+FakeCharacteristic.m
//  SonarTests
//
//  Created by NHSX on 16/6/20
//  Copyright © 2020 NHSX. All rights reserved.
//

#import "CBCharacteristic+FakeCharacteristic.h"

@implementation CBCharacteristic (FakeCharacteristic)
- (instancetype)initWithUUID:(CBUUID *)uuid {
    self = [CBCharacteristic new];
    return self;
}

- (CBUUID *)UUID {
    return [CBUUID new];
}

- (void)dealloc
{
}

@end
