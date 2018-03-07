//
//  GesturePswController.h
//  Adoma
//
//  Created by Adoma on 2018/3/7.
//  Copyright © 2018年 Adoma. All rights reserved.
//

#import <UIKit/UIKit.h>
@class GesturePswController;

#define MaxGesturePwdCheckCount 5
#define kGesturePwdKey @"kGesturePwdKey"
#define kGesturePwdCheckCountKey @"kGesturePwdCheckCountKey"

typedef NS_ENUM(NSUInteger, GestureType) {
    GestureTypeEnable,
    GestureTypeVerify,
    GestureTypeModify,
};

@protocol GesturePswControllerDelegate

@optional
- (void)gesturePswDidVerify:(GesturePswController*)gesturePswController success:(BOOL)success;

- (void)gesturePswDidModify:(GesturePswController*)gesturePswController success:(BOOL)success;

- (void)gesturePswDidSet:(GesturePswController*)gesturePswController;

- (void)changeAccount:(GesturePswController*)gesturePswController;

- (void)forgetGesturePsw:(GesturePswController*)gesturePswController;

@end

@interface GesturePswController : UIViewController

+ (instancetype)gesturePsw:(GestureType)type delegate:(id<GesturePswControllerDelegate>)delegate;

@end
