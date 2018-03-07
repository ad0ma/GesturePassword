//
//  ViewController.m
//  GesturePassword
//
//  Created by Adoma on 2018/3/7.
//  Copyright © 2018年 Adoma. All rights reserved.
//

#import "ViewController.h"
#import "GesturePswController.h"

@interface ViewController ()<GesturePswControllerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (IBAction)set
{
    GesturePswController *gesture = [GesturePswController gesturePsw:GestureTypeEnable delegate:self];
    [self.navigationController pushViewController:gesture animated:YES];
}

- (IBAction)verify
{
    GesturePswController *gesture = [GesturePswController gesturePsw:GestureTypeVerify delegate:self];
    [self.navigationController pushViewController:gesture animated:YES];
}


- (IBAction)modify
{
    GesturePswController *gesture = [GesturePswController gesturePsw:GestureTypeModify delegate:self];
    [self.navigationController pushViewController:gesture animated:YES];
}

- (void)alert:(NSString *)msg
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *sure = [UIAlertAction actionWithTitle:@"确定" style:0 handler:nil];
    
    [alert addAction:sure];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)gesturePswDidSet:(GesturePswController *)gesturePswController
{
    [self alert:@"手势密码设置成功"];
}

- (void)gesturePswDidVerify:(GesturePswController *)gesturePswController success:(BOOL)success
{
    if (success) {
        [self alert:@"手势密码确认成功"];
    } else {
        [self alert:@"手势密码确认失败"];
    }
}

- (void)gesturePswDidModify:(GesturePswController *)gesturePswController success:(BOOL)success
{
    if (success) {
        [self alert:@"手势密码修改成功"];
    } else {
        [self alert:@"手势密码修改失败"];
    }
}

- (void)changeAccount:(GesturePswController *)gesturePswController
{
    [self alert:@"切换账户"];
}

- (void)forgetGesturePsw:(GesturePswController *)gesturePswController
{
    [[NSUserDefaults standardUserDefaults] setInteger:MaxGesturePwdCheckCount forKey:kGesturePwdCheckCountKey];
}


@end
