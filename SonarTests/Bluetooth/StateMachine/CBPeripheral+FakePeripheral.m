//
//  CBPeripheral+FakePeripheral.m
//  SonarTests
//
//  Created by NHSX on 2020/06/15
//  Copyright © 2020 NHSX. All rights reserved.
//

#import "CBPeripheral+FakePeripheral.h"

@implementation CBPeripheral (FakePeripheral)

- (instancetype)initWithName:(NSString *)name
{
    self = [CBPeripheral new];

    [self performSelector:@selector(setName:) withObject:name];

    return self;
}

- (NSUUID *)identifier
{
    return [[NSUUID alloc] initWithUUIDString:@"BB007703-C407-48E3-A1B6-7CF7BD31A6E4"];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

- (void)readRSSI
{
    NSLog(@"CBPeripheral (FakePeripheral).readRSSI()");
}

#pragma clang diagnostic pop

// Without overridding the dealloc method, an exception is thrown during initialization:
//  --> caught "NSRangeException", "Cannot remove an observer <CBPeripheral 0x600001b30500> for the key path "delegate" from <CBPeripheral 0x600001b30500> because it is not registered as an observer.""
- (void)dealloc
{
}

@end
