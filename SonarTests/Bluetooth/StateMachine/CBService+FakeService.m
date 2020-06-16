//
//  CBService+FakeService.m
//  SonarTests
//
//  Created by NHSX on 16/6/20
//  Copyright © 2020 NHSX. All rights reserved.
//

#import "CBService+FakeService.h"

@implementation CBService (FakeService)
- (instancetype)initWithCharacteristics:(NSArray<CBCharacteristic *> *)characteristics {
    self = [CBService new];

    [self performSelector:@selector(setCharacteristics:) withObject:characteristics];
    
    return self;
}
// Without overridding the dealloc method, an exception is thrown during initialization:
//  --> caught "NSRangeException", "Cannot remove an observer <CBPeripheral 0x600001b30500> for the key path "delegate" from <CBPeripheral 0x600001b30500> because it is not registered as an observer.""
- (void)dealloc
{
}

@end
