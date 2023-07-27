//
//  KSYPlayerPicView.m
//
//  Created by 施雪梅 on 17/7/12.
//  Copyright © 2017年 ksyun. All rights reserved.
//

#import "KSYPlayerPicView.h"

@interface KSYPlayerPicView(){
    UILabel *_labelContenMode;
    UILabel *_labelRotate;
    UILabel *_labelMirror;
    UIButton *_btnShotScreen;
}
@end

@implementation KSYPlayerPicView

- (id)init{
    self = [super init];
    
    [self setupUI];
    return self;
}

- (void) setupUI {
    _labelContenMode = [self addLable:@"Fill mode"]; // create a label for fill mode option
    _segContentMode = [self addSegCtrlWithItems:@[@"None", @"Aspect fit", @"Aspect fill", @"Full screen"]]; // create a segmented control for choosing the fill mode

    _labelRotate = [self addLable:@"Rotate"]; // create a label for rotate option
    _segRotate = [self addSegCtrlWithItems:@[@"0", @"90", @"180", @"270"]]; // create a segmented control for choosing the rotation angle

    _labelMirror = [self addLable:@"Mirror"]; // create a label for mirror option
    _segMirror = [self addSegCtrlWithItems:@[@"Normal", @"Reverse"]]; // create a segmented control for choosing the mirror direction

    _btnShotScreen = [self addButton:@"Screenshot"]; // create a button for taking a screenshot
    [self layoutUI];
}

- (void)layoutUI{
    [super layoutUI];
    self.yPos = 0;
    
    [self putLable:_labelContenMode andView:_segContentMode];
    [self putLable:_labelRotate andView:_segRotate];
    [self putLable:_labelMirror andView:_segMirror];
    [self putRow1:_btnShotScreen];
}

@synthesize contentMode = _contentMode;
- (MPMovieScalingMode) contentMode{
    MPMovieScalingMode mode = MPMovieScalingModeNone;
    switch(_segContentMode.selectedSegmentIndex) {
        case 0:
            mode = MPMovieScalingModeNone;
            break;
        case 1:
            mode = MPMovieScalingModeAspectFit;
            break;
        case 2:
            mode = MPMovieScalingModeAspectFill;
            break;
        case 3:
            mode = MPMovieScalingModeFill;
            break;
        default:
            return  MPMovieScalingModeNone;
            break;
    }
    return mode;
}

- (void) setContentMode:(MPMovieScalingMode)contentMode{
    _contentMode = contentMode;
    _segContentMode.selectedSegmentIndex = (contentMode - MPMovieScalingModeNone);
}


@synthesize rotateDegress = _rotateDegress;
- (int) rotateDegress{
    return (int)_segRotate.selectedSegmentIndex * 90;
}

@synthesize bMirror = _bMirror;
- (BOOL)bMirror{
    return (BOOL)_segMirror.selectedSegmentIndex;
}

@end
