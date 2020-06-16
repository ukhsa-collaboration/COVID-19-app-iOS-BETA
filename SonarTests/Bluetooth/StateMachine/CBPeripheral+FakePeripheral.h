//
//  CBPeripheral+FakePeripheral.h
//  SonarTests
//
//  Created by NHSX on 2020/06/15
//  Copyright © 2020 NHSX. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

@interface CBPeripheral (FakePeripheral)
@property (strong) CBService *fakeService;

- (instancetype)initWithName:(NSString *)name;
- (void)readRSSI;
- (void)discoverServices:(NSArray<CBUUID *> *)serviceUUIDs;
- (void)discoverCharacteristics:(NSArray<CBUUID *> *)characteristicUUIDs forService:(CBService *)service;

@end

NS_ASSUME_NONNULL_END
