//
//  CBService+FakeService.h
//  SonarTests
//
//  Created by NHSX on 16/6/20
//  Copyright © 2020 NHSX. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

@interface CBService (FakeService)

- (instancetype)initWithCharacteristics:(NSArray<CBCharacteristic *> *)characteristics;

@end

NS_ASSUME_NONNULL_END
