//
//  GesturePswController.m
//  Adoma
//
//  Created by Adoma on 2018/3/7.
//  Copyright © 2018年 Adoma. All rights reserved.
//

#import "GesturePswController.h"
#import <AudioToolbox/AudioToolbox.h>

@interface UIColor (ColorWithHexStrig)

+ (UIColor *)colorWithHexString:(NSString *)hexString;

@end

@implementation UIColor (ColorWithHexStrig)
//根据十六进制数值获取UIColor
+ (UIColor *)colorWithHexString:(NSString *)hexString {
    //去掉字符串两端的空格，并且取小写转换大写
    NSString *colorString = [[hexString
                              stringByTrimmingCharactersInSet:[NSCharacterSet
                                                               whitespaceAndNewlineCharacterSet]]
                             uppercaseString];
    //当给定的字符串长度小于6时，返回透明的
    if (colorString.length < 6) {
        return [UIColor clearColor];
    }
    // strip 0X if it appears
    if ([colorString hasPrefix:@"0X"])
        colorString = [colorString substringFromIndex:2];
    if ([colorString hasPrefix:@"#"])
        colorString = [colorString substringFromIndex:1];
    if ([colorString length] != 6) return [UIColor clearColor];
    
    unsigned int red = 0, green = 0, blue = 0;
    NSRange range = NSMakeRange(0, 2);
    [[NSScanner scannerWithString:[colorString substringWithRange:range]]
     scanHexInt:&red];
    range.location = 2;
    [[NSScanner scannerWithString:[colorString substringWithRange:range]]
     scanHexInt:&green];
    range.location = 4;
    [[NSScanner scannerWithString:[colorString substringWithRange:range]]
     scanHexInt:&blue];
    return [UIColor colorWithRed:red / 255.0
                           green:green / 255.0
                            blue:blue / 255.0
                           alpha:1];
}
@end

#define kSetHexColor(_Color_) [UIColor colorWithHexString:@ #_Color_]

#define RedColor kSetHexColor(F33038)
#define GreenColor kSetHexColor(28AF4E)
#define BlueColor kSetHexColor(2D9BF8)
#define NormalColor kSetHexColor(333333)

typedef NS_ENUM(NSUInteger, GestureNodeType) {
    GestureNodeTypeNormal,
    GestureNodeTypeSelected,
    GestureNodeTypeFail,
};

@interface GestureNode: NSObject

@property (nonatomic, weak) UIImageView *contentImageView;
@property (nonatomic, readonly) NSString *psw;
@property (nonatomic, assign) GestureNodeType type;

@end

@implementation GestureNode

- (NSString *)psw
{
    return @(self.contentImageView.tag - 1000).stringValue;
}

- (void)setType:(GestureNodeType)type
{
    _type = type;
    
    switch (type) {
        case GestureNodeTypeNormal:
            _contentImageView.image = [UIImage imageNamed:@"Oval"];
            break;
            
        case GestureNodeTypeSelected:
            _contentImageView.image = [UIImage imageNamed:@"yuan"];
            break;
            
        case GestureNodeTypeFail:
            _contentImageView.image = [UIImage imageNamed:@"yuan_red"];
            break;
            
        default:
            break;
    }
}

@end

typedef NS_ENUM(NSUInteger, GestureSubType) {
    GestureSubTypeNone,
    GestureSubTypeVerify,
    GestureSubTypeSetNew,
    GestureSubTypeVerifyNew,
};

typedef NS_ENUM(NSUInteger, GesturePswErrorType) {
    GesturePswErrorTypeLengthLess, //位数不足
    GesturePswErrorTypeNoCorrect, //不正确
    GesturePswErrorTypeNoConform, //不一致
};

@interface GesturePswController ()

@property (nonatomic, assign) GestureType type;

@property (nonatomic, assign) GestureSubType subType;

@property (nonatomic, weak) id<GesturePswControllerDelegate> delegate;

@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *dots;

@property (nonatomic, strong) NSMutableArray <GestureNode *> *nodes;

@property (nonatomic, strong) NSMutableArray <GestureNode *> *selectedNodes;

@property (nonatomic, strong) NSMutableArray <CAShapeLayer *> *lines;

@property (nonatomic, strong) CAShapeLayer *lineLayer;

@property (nonatomic, readonly) NSString *selectedPsw;

@property (nonatomic, copy) NSString *willVerifyPsw;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UILabel *tipLabel;

@property (weak, nonatomic) IBOutlet UIView *bottomView;

@property (weak, nonatomic) IBOutlet UIButton *resetPsw;

@property (nonatomic, assign) NSUInteger checkCount;

@property (nonatomic, assign) BOOL enable;

@end

@implementation GesturePswController

+ (instancetype)gesturePsw:(GestureType)type delegate:(id<GesturePswControllerDelegate>)delegate
{
    GesturePswController *gesture = [GesturePswController new];
    gesture.type = type;
    gesture.delegate = delegate;
    return gesture;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _enable = YES;
    _nodes = [NSMutableArray arrayWithCapacity:_dots.count];
    _selectedNodes = [NSMutableArray array];
    _lines = [NSMutableArray array];
    
    _lineLayer = [CAShapeLayer layer];
    _lineLayer.lineWidth = 2;
    _lineLayer.strokeColor = BlueColor.CGColor;
    [self.view.layer addSublayer:_lineLayer];
    
    for (UIImageView *imgView in _dots) {
        GestureNode *node = [GestureNode new];
        node.contentImageView = imgView;
        //init
        node.type = GestureNodeTypeNormal;
        
        [_nodes addObject:node];
    }
    
    switch (_type) {
        case GestureTypeEnable:
            self.subType = GestureSubTypeSetNew;
            break;
            
        case GestureTypeVerify:
            _bottomView.hidden = NO;
            _titleLabel.text = @"手势密码登录";
            break;
            
        case GestureTypeModify:
            self.subType = GestureSubTypeVerify;
            break;
            
        default:
            break;
    }
}

- (void)setSubType:(GestureSubType)subType
{
    _subType = subType;
    
    _tipLabel.textColor = NormalColor;
    _resetPsw.hidden = YES;
    
    switch (subType) {
            
        case GestureSubTypeVerify:
            _titleLabel.text = @"验证手势密码";
            _tipLabel.text = @"请绘制解锁图案";
            break;
            
        case GestureSubTypeSetNew:
            _titleLabel.text = @"设置手势密码";
            _tipLabel.text = @"请绘制解锁图案";
            break;
            
        case GestureSubTypeVerifyNew:
            _titleLabel.text = @"设置手势密码";
            _tipLabel.text = @"请再绘制一次";
            break;
            
        default:
            break;
    }
    
    [self reset];
}

- (NSString *)selectedPsw
{
    NSMutableString *mStr = @"".mutableCopy;
    for (GestureNode *node in _selectedNodes) {
        [mStr appendString:node.psw];
    }
    return mStr.copy;
}

- (void)reset
{
    //移除所有已选择
    for (GestureNode *node in _selectedNodes) {
        node.type = GestureNodeTypeNormal;
    }
    [_selectedNodes removeAllObjects];
    
    //移除线
    for (CAShapeLayer *line in _lines) {
        [line removeFromSuperlayer];
    }
    [_lines removeAllObjects];
    
    //可以被选择
    _enable = YES;
}

- (void)setError:(GesturePswErrorType)errorType
{
    for (GestureNode *node in _selectedNodes) {
        node.type = GestureNodeTypeFail;
    }
    
    for (CAShapeLayer *line in _lines) {
        line.strokeColor = RedColor.CGColor;
    }
    
    _tipLabel.textColor = RedColor;
    
    switch (errorType) {
        case GesturePswErrorTypeNoConform:
            _tipLabel.text = @"两次图案不同，请重新绘制";
            break;
            
        case GesturePswErrorTypeNoCorrect:
            _tipLabel.text = [NSString stringWithFormat:@"密码错误，还可以输入%ld次",self.checkCount];
            break;
            
        case GesturePswErrorTypeLengthLess:
            _tipLabel.text = @"至少需连接4个点，请重新绘制";
            break;
            
        default:
            break;
    }
    
    CAKeyframeAnimation *kfa = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
    CGFloat s = 5;
    kfa.values = @[@(-s),@(0),@(s),@(0),@(-s),@(0),@(s),@(0)];
    //时长
    kfa.duration = 0.3f;
    //重复
    kfa.repeatCount = 2;
    //移除
    kfa.removedOnCompletion = YES;
    [_tipLabel.layer addAnimation:kfa forKey:@"shake"];
}

- (void)addNode:(GestureNode *)node
{
    if ([_selectedNodes containsObject:node]) {
        return;
    }
    
    GestureNode *lastNode = _selectedNodes.lastObject;
    
    if (lastNode) {
        
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:lastNode.contentImageView.center];
        [path addLineToPoint:node.contentImageView.center];
        
        for (GestureNode *n in _nodes) {
            if ([_selectedNodes containsObject:n] == NO && [path containsPoint:n.contentImageView.center] && n != node) {
                n.type = GestureNodeTypeSelected;
                [_selectedNodes addObject:n];
            }
        }
        
        CAShapeLayer *layer = [CAShapeLayer layer];
        
        layer.path = path.CGPath;
        layer.lineWidth = 2;
        layer.strokeColor = BlueColor.CGColor;
        
        [self.view.layer insertSublayer:layer below:lastNode.contentImageView.layer];
        [_lines addObject:layer];
    }
    
    node.type = GestureNodeTypeSelected;
    [_selectedNodes addObject:node];
    
    AudioServicesPlaySystemSound(1519);
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (_enable == NO) {
        return;
    }
    
    UITouch *touch = touches.allObjects.firstObject;
    
    if (_selectedNodes.count > 0) {
        
        GestureNode *lastNode = _selectedNodes.lastObject;
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:lastNode.contentImageView.center];
        [path addLineToPoint:[touch locationInView:self.view]];
        _lineLayer.path = path.CGPath;
    }
    
    for (GestureNode *node in _nodes) {
        
        if (node.type != GestureNodeTypeNormal) {
            continue;
        }
        
        UIImageView *imageView = node.contentImageView;
        CGPoint point = [touch locationInView:imageView];
        
        if ([imageView pointInside:point withEvent:nil]) {
            [self addNode:node];
            break;
        }
        
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (_enable == NO) {
        return;
    }
    
    _lineLayer.path = nil;
    
    if (_selectedNodes.count == 0) {
        return;
    }
    
    _enable = NO;
    
    if (_selectedNodes.count < 4) {
        
        [self setError:GesturePswErrorTypeLengthLess];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.subType = _subType;
        });
        return;
    }
    
    switch (_type) {
        case GestureTypeEnable:
            [self setPsw];
            break;
            
        case GestureTypeVerify:
            [self verifyPsw];
            break;
            
        case GestureTypeModify:
            [self modifyPsw];
            break;
            
        default:
            break;
    }
    
}

- (void)verifyPsw
{
    NSString *old = [[NSUserDefaults standardUserDefaults] stringForKey:kGesturePwdKey];
    
    if ([self.selectedPsw isEqualToString:old]) {
        
        _tipLabel.text = @"手势密码验证成功";
        _tipLabel.textColor = GreenColor;
        
        [[NSUserDefaults standardUserDefaults] setInteger:MaxGesturePwdCheckCount forKey:kGesturePwdCheckCountKey];
        
        if (_type == GestureTypeModify) {
            self.subType = GestureSubTypeSetNew;
        } else {
            [self.delegate gesturePswDidVerify:self success:YES];
        }
        
    } else {
        
        self.checkCount = [[NSUserDefaults standardUserDefaults] integerForKey:kGesturePwdCheckCountKey] - 1;
        
        [[NSUserDefaults standardUserDefaults] setInteger:self.checkCount forKey:kGesturePwdCheckCountKey];
        
        if (self.checkCount > 0) {
            [self setError:GesturePswErrorTypeNoCorrect];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self reset];
            });
        } else {
            if (_type == GestureTypeModify) {
                [self.delegate gesturePswDidModify:self success:NO];
            } else {
                [self.delegate gesturePswDidVerify:self success:NO];
            }
        }
    }
}

- (void)setPsw
{
    switch (_subType) {
        case GestureSubTypeSetNew:
            self.willVerifyPsw = self.selectedPsw;
            self.subType = GestureSubTypeVerifyNew;
            break;
            
        case GestureSubTypeVerifyNew:
            if ([self.willVerifyPsw isEqualToString:self.selectedPsw]) {
                
                _tipLabel.textColor = GreenColor;
                
                [[NSUserDefaults standardUserDefaults] setObject:self.willVerifyPsw forKey:kGesturePwdKey];
                [[NSUserDefaults standardUserDefaults] setInteger:MaxGesturePwdCheckCount forKey:kGesturePwdCheckCountKey];
                
                if (self.type == GestureTypeModify) {
                    _tipLabel.text = @"手势密码修改成功";
                    [self.delegate gesturePswDidModify:self success:YES];
                } else {
                    _tipLabel.text = @"手势密码设置成功";
                    [self.delegate gesturePswDidSet:self];
                }
            } else {
                
                [self setError:GesturePswErrorTypeNoConform];
                self.resetPsw.hidden = NO;
            }
            break;
            
        default:
            break;
    }
}

- (void)modifyPsw
{
    switch (_subType) {
        case GestureSubTypeVerify:
            [self verifyPsw];
            break;
            
        default:
            [self setPsw];
            break;
    }
}

- (IBAction)changeAccount
{
    [self.delegate changeAccount:self];
}

- (IBAction)forgetGesturePsw
{
    [self.delegate forgetGesturePsw:self];
}

- (IBAction)resetPswAction
{
    self.subType = GestureSubTypeSetNew;
}



@end
