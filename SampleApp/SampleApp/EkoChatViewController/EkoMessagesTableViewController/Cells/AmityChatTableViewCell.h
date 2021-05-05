//
//  AmityChatTableViewCell.h
//  SampleApp
//
//  Created by Federico Zanetello on 5/16/18.
//  Copyright © 2018 David Zhang. All rights reserved.
//
@import AmitySDK;

@protocol AmityChatTableViewCell <NSObject>
- (void)displayMessage:(nonnull AmityMessage *)message client:(nonnull AmityClient *)client;
@end
