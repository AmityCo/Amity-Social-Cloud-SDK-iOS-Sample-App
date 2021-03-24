//
//  NSString+Eko.m
//  SampleApp
//
//  Created by Federico Zanetello on 6/15/18.
//  Copyright © 2018 David Zhang. All rights reserved.
//

#import "NSString+Eko.h"

@implementation NSString (empty)

- (BOOL)isWhitespace {
    return ([[self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]length] == 0);
}

@end
