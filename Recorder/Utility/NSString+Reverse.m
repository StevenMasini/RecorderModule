//
//  NSString+Reverse.m
//  Recorder
//
//  Created by Steven Masini on 8/18/15.
//  Copyright (c) 2015 Steven Masini. All rights reserved.
//

#import "NSString+Reverse.h"

@implementation NSString (Reverse)

- (NSString *)reversedString {
    NSMutableString *reversedString = [[NSMutableString alloc] initWithCapacity:self.length];
    for (NSInteger i = self.length - 1;i>=0;i--) {
        unichar c = [self characterAtIndex:i];
        NSString *character = [NSString stringWithCharacters:&c length:1];
        [reversedString appendString:character];
    }
    return [NSString stringWithString:reversedString];
}

@end
