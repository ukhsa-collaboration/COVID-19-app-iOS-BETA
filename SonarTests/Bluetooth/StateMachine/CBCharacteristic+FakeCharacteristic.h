//
//  CBCharacteristic+FakeCharacteristic.h
//  SonarTests
//
//  Created by NHSX on 16/6/20
//  Copyright © 2020 NHSX. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

@interface CBCharacteristic (FakeCharacteristic)
- (instancetype)initWithUUID:(CBUUID *)uuid;

@end

NS_ASSUME_NONNULL_END
