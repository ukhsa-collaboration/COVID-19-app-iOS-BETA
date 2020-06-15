//
//  CBPeripheral+Exploration.m
//  SonarTests
//
//  Created by NHSX on 2020/06/15
//  Copyright © 2020 NHSX. All rights reserved.
//

#import "CBPeripheral+Exploration.h"

@implementation CBPeripheral (Exploration)

- (instancetype)initWithSomething:(int)something
{
    self = [CBPeripheral new];

    return self;
}

- (NSString *)name
{
    return @"some name";
}

- (NSUUID *)identifier
{
    return [[NSUUID alloc] initWithUUIDString:@"BB007703-C407-48E3-A1B6-7CF7BD31A6E4"];
}

- (void)dealloc
{
    NSLog(@"Why are we here?");
}

@end
