//
//  EkoChatViewController.m
//  SampleApp
//
//  Created by David Zhang on 3/7/18.
//  Copyright © 2018 eko. All rights reserved.
//

@import EkoChat;
@import Photos;
#import "EkoChatViewController.h"
#import "EkoKeyboardService.h"
#import "NSString+Eko.h"
#import "SampleApp-Swift.h"

@interface EkoChatViewController () <UITextFieldDelegate, EkoKeyboardServiceDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, strong) EkoClient *client;
@property (nonatomic, strong) NSString *channelId;
@property (nonatomic, strong) EkoMessagesTableViewController *messageViewController;
@property (nonatomic, strong) EkoMessageRepository *messageRepository;
@property (nonatomic, strong) EkoNotificationToken *channelNotification;
@property (nonatomic, strong) IBOutlet UITextField *textField;

@property (weak, nonatomic) IBOutlet UIView *inputContainer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottom;
@property (weak, nonatomic) UIButton *titleButton;
@property (nonatomic, strong, nullable) EkoChannel *channel;

@end

@implementation EkoChatViewController

- (void)setupWithClient:(EkoClient *)client channelId:(NSString *)channelId channelType:(EkoChannelType)type {
    self.client = client;
    self.channelId = channelId;
    self.messageRepository = [[EkoMessageRepository alloc] initWithClient:self.client];
    [self joinChannelId:self.channelId type:type];
    [self addTitleButton];
    [self addLeaveButton];
    EkoChannelParticipation *channelPartecipation = [[EkoChannelParticipation alloc] initWithClient:self.client
                                                                                         andChannel:channelId];
    [channelPartecipation startReading];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    EkoChannelParticipation *channelPartecipation = [[EkoChannelParticipation alloc] initWithClient:self.client
                                                                                         andChannel:self.channelId];
    [channelPartecipation stopReading];
}

- (void)joinChannelId:(NSString *)channelId type:(EkoChannelType)type {
    EkoChannelRepository *repository = [[EkoChannelRepository alloc] initWithClient:self.client];
    __weak typeof(self) weakSelf = self;
    EkoObject<EkoChannel *> *channelObject = [repository joinChannel:channelId
                                                                type:type];
    self.channelNotification = [channelObject observeOnceWithBlock:^(EkoObject <EkoChannel *> * _Nonnull object, NSError * _Nullable error) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        if (strongSelf && !error) {
            EkoChannel *channel = object.object;
            strongSelf.channel = channel;
            [strongSelf updateDisplayNameWith:channel.displayName];

            // displaying momentarily the connected status in the UI
            UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithTitle:@"Connected"
                                                                           style:UIBarButtonItemStylePlain
                                                                          target:nil
                                                                          action:nil];
            [self.navigationItem setRightBarButtonItem:buttonItem
                                              animated:YES];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                UIImage *gearImage = [UIImage imageNamed:@"Settings"];

                UIBarButtonItem *channelSettings = [[UIBarButtonItem alloc] initWithImage:gearImage
                                                                                    style:UIBarButtonItemStylePlain
                                                                                   target:self action:@selector(navigateToChannelSettingsView)];
                [self.navigationItem setRightBarButtonItem:channelSettings];
            });
        }
    }];
}

- (void)addTitleButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button addTarget:self action:@selector(updateChannelDisplayName)
     forControlEvents:UIControlEventTouchUpInside];
    button.clipsToBounds = YES;
    self.titleButton = button;
    self.navigationItem.titleView = button;
}

- (void)addLeaveButton {
    UIBarButtonItem *leaveBtn = [[UIBarButtonItem alloc] initWithTitle:@"Leave"
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(leave)];
    UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"]
                                                                style:UIBarButtonItemStylePlain
                                                               target:self
                                                               action:@selector(back)];
    [self.navigationItem setLeftBarButtonItems:@[backBtn, leaveBtn]
                                      animated:YES];
}

- (void)leave {
    if (self.channel) {
        __weak __typeof(self)weakSelf = self;
        EkoChannel *channel = self.channel;
        self.channel = nil;
        [channel.participation leaveWithCompletion:^(BOOL success, NSError * _Nullable error) {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            if (strongSelf && success && !error) {
                [strongSelf.navigationController popViewControllerAnimated:YES];
            }
        }];
    }
}

- (void)back {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)updateChannelDisplayName {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Enter The New Channel Display Name"
                                                                   message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Rename"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
        NSString *newDisplayName = alert.textFields[0].text;
        __weak typeof(self) weakSelf = self;
        EkoChannelRepository *channelRepo = [[EkoChannelRepository alloc] initWithClient:self.client];
        [channelRepo setDisplayNameForChannel:self.channelId
                                  displayName:newDisplayName
                                   completion:^(BOOL success, NSError * _Nullable error) {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            if (strongSelf) {
                if (success) {
                    [strongSelf updateDisplayNameWith:newDisplayName];
                } else {
                    NSLog(@"%@", [error description]);
                }
            }
        }];
    }]];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = [self.titleButton titleForState:UIControlStateNormal];
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)navigateToChannelSettingsView {
    ChannelSettingsTableViewController *settingsViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ChannelSettingsTableViewController"];
    settingsViewController.client = self.client;
    settingsViewController.channelId = self.channelId;
    [self.navigationController pushViewController:settingsViewController
                                         animated:YES];
}

- (void)updateDisplayNameWith:(NSString *)displayName {
    if (displayName == nil || [displayName isWhitespace]) {
        [self.titleButton setTitle:@"~no display name~" forState:UIControlStateNormal];
    } else {
        [self.titleButton setTitle:displayName forState:UIControlStateNormal];
    }
    [self.titleButton sizeToFit];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.textField.delegate = self;
    
    [[EkoKeyboardService sharedInstance] setDelegate:self];
    [[EkoKeyboardService sharedInstance] setup];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[EkoMessagesTableViewController class]]) {
        EkoMessagesTableViewController *destination = segue.destinationViewController;
        destination.client = self.client;
        destination.channelId = self.channelId;
        self.messageViewController = destination;
    }
}

- (void)sendTextMessage {
    NSString *text = self.textField.text;
    self.textField.text = @"";
    if (!text.isWhitespace) {
        NSLog(@"Sending text message: %@", text);
        [self.messageRepository createTextMessageWithChannelId:self.channelId
                                                          text:text
                                                      parentId:self.messageViewController.replyToMessageId];
        self.messageViewController.replyToMessageId = nil;
    }
}

- (void)sendImageMessage:(UIImage *)image {;
    NSLog(@"Sending image message");
    [self.messageRepository createImageMessageWithChannelId:self.channelId
                                                      image:image
                                                    caption:@""
                                                  fullImage:NO
                                                   parentId:self.messageViewController.replyToMessageId];
    self.messageViewController.replyToMessageId = nil;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self sendTextMessage];
    return YES;
}

- (IBAction)didPressSend:(UIButton *)sender {
    [self sendTextMessage];
}

- (void)keyboardWillChange:(EkoKeyboardService*)service newHeight:(CGFloat)newHeight oldHeight:(CGFloat)oldHeight animationDuration:(NSTimeInterval)duration {
    CGFloat offset = newHeight > 0 ? self.view.safeAreaInsets.bottom : 0;
    self.bottom.constant = -(newHeight - offset);
    [self.view setNeedsUpdateConstraints];
    [self.view layoutIfNeeded];
    EkoMessagesTableViewController *viewController = [self.childViewControllers firstObject];
    [viewController scrollToBottom];
    
}
- (IBAction)showImagePickerRequest:(UIButton *)sender {
    switch ([PHPhotoLibrary authorizationStatus]) {
        case PHAuthorizationStatusNotDetermined: {
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                [self showImagePickerRequest:sender];
            }];
            break;
        }
        case PHAuthorizationStatusDenied:
        case PHAuthorizationStatusRestricted: {
            NSLog(@"No authorization 🙈");
            break;
        }
        case PHAuthorizationStatusAuthorized: {
            [self showImagePicker];
            break;
        }
    }
}

- (void)showImagePicker {
    UIImagePickerController* imagePicker = [UIImagePickerController new];
    // Check if image access is authorized
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        // Use delegate methods to get result of photo library -- Look up UIImagePicker delegate methods
        imagePicker.delegate = self;
        [self presentViewController:imagePicker animated:true completion:nil];
    } else {
        NSLog(@"No photo library? 🙈");
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    [self sendImageMessage:info[UIImagePickerControllerOriginalImage]];
}

@end
