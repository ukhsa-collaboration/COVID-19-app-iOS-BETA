//
//  CBPeripheral+FakePeripheral.m
//  SonarTests
//
//  Created by NHSX on 2020/06/15
//  Copyright © 2020 NHSX. All rights reserved.
//

#import "CBPeripheral+FakePeripheral.h"
#import "CBService+FakeService.h"
#import "CBCharacteristic+FakeCharacteristic.h"

@implementation CBPeripheral (FakePeripheral)
// This does not seem to work in a category
@dynamic fakeService;

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

- (NSArray<CBService *> *)services
{
    return @[self.fakeService];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

- (void)readRSSI
{
    NSLog(@"CBPeripheral (FakePeripheral).readRSSI()");
    [self.delegate peripheral:self didReadRSSI:[NSNumber numberWithInt:-32] error:NULL];
}

-(void)discoverServices:(NSArray<CBUUID *> *)serviceUUIDs{
    [self.delegate peripheral:self didDiscoverServices:NULL];
}

- (void)discoverCharacteristics:(NSArray<CBUUID *> *)characteristicUUIDs forService:(CBService *)service {
    CBCharacteristic *sonarCharacteristic = [[CBCharacteristic alloc] initWithUUID: [characteristicUUIDs objectAtIndex: 0]];
    CBCharacteristic *keepaliveCharacteristic = [[CBCharacteristic alloc] initWithUUID: [characteristicUUIDs objectAtIndex: 1]];

    NSArray<CBCharacteristic *> *characteristics = @[sonarCharacteristic, keepaliveCharacteristic];

    self.fakeService = [[CBService alloc] initWithCharacteristics: characteristics];
    
    [self.delegate peripheral:self didDiscoverCharacteristicsForService: self.fakeService error:NULL];
}

#pragma clang diagnostic pop

// Without overridding the dealloc method, an exception is thrown during initialization:
//  --> caught "NSRangeException", "Cannot remove an observer <CBPeripheral 0x600001b30500> for the key path "delegate" from <CBPeripheral 0x600001b30500> because it is not registered as an observer.""
- (void)dealloc
{
}

@end
