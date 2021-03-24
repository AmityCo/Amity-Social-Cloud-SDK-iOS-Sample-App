//
//  EkoChatTableViewCell.h
//  SampleApp
//
//  Created by Federico Zanetello on 5/16/18.
//  Copyright © 2018 David Zhang. All rights reserved.
//
@import EkoChat;

@protocol EkoChatTableViewCell <NSObject>
- (void)displayMessage:(nonnull EkoMessage *)message client:(nonnull EkoClient *)client;
@end
