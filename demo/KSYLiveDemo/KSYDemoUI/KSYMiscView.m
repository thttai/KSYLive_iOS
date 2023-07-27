//
//  KSYFilterView.m
//  KSYGPUStreamerDemo
//
//  Created by 孙健 on 16/6/24.
//  Copyright © 2016年 ksyun. All rights reserved.
//
#import "KSYPresetCfgView.h"
#import "KSYMiscView.h"
#import "KSYFileSelector.h"

@interface KSYMiscView() {
    UIButton * _curBtn;
    UILabel  * _lblScene;
    UILabel  * _lbrScene;
    UILabel  * _lblPerf;
    UILabel  * _lblRec;
    UILabel  * _lblLogo;
    KSYFileSelector *_sel;
    BOOL     _skipBtnTap; // skip btn tap for 0.5 seconds
}

@end

@implementation KSYMiscView

- (id)init{
    self = [super init];
    _btn0  = [self addButton:@"Screenshot 1"]; // create a button for taking a screenshot 1
    _btn1  = [self addButton:@"Screenshot 2"]; // create a button for taking a screenshot 2
    _btn2  = [self addButton:@"Filter screenshot"]; // create a button for taking a screenshot with filter

    _lblLogo = [self addLable:@"Logo"]; // create a label for logo option
    _btn3  = [self addButton:@"Select"]; // create a button for selecting a logo
    _btn4  = [self addButton:@"Capture"]; // create a button for capturing a logo
    _btn5  = [self addButton:@"Clear"]; // create a button for clearing the logo
    _btnAnimate  = [self addButton:@"Animated image"]; // create a button for creating an animated image
    _btnNext     = [self addButton:@" Next "]; // create a button for going to the next image
    _lblAnimate  = [self addLable:@"Animated logo"]; // create a label for animated logo option
    _sel = [[KSYFileSelector alloc] initWithDir:@"/Documents/logo/"
                                      andSuffix:@[@".gif", @".png", @".apng"]];
    if (_sel.fileList.count < 3) {
        NSArray *names = @[@"ksyun.gif",@"elephant.png", @"horse.gif"];
        for (NSString* name in names ) {
            NSString * host = @"https://ks3-cn-beijing.ksyun.com/ksy.vcloud.sdk/picture/animateLogo/";
            NSString * url = [host stringByAppendingString:name];
            [_sel downloadFile:url name:name ];
        }
    }
    else {
        for (int i= 0; i < 2; ++i){
            [_sel selectFileWithType:KSYSelectType_NEXT];
        }
    }
    _lblRec       = [self addLable:@"Bypass recording"]; // create a label for bypass recording option
    _swBypassRec  = [self addSwitch:NO]; // create a switch for bypass recording option
    _lblRecDur    = [self addLable:@"0s"]; // create a label for showing the recording duration

    _layerSeg = [self addSegCtrlWithItems:@[ @"Logo", @"Text"]]; // create a segmented control for choosing the layer type
    _alphaSl  = [self addSliderName:@"Alpha" From:0.0 To:1.0 Init:1.0]; // create a slider for adjusting the alpha value

    _lblScene      = [self addLable:@"Live scene"]; // create a label for live scene option
    _liveSceneSeg  = [self addSegCtrlWithItems:@[ @"Default", @"Show", @"Game"]]; // create a segmented control for choosing the live scene
    _lbrScene      = [self addLable:@"Recording scene"]; // create a label for recording scene option
    _recSceneSeg  = [self addSegCtrlWithItems:@[ @"Constant bitrate", @"Constant quality"]]; // create a segmented control for choosing the recording scene
    _lblPerf       = [self addLable:@"Encoding performance"]; // create a label for encoding performance option
    _vEncPerfSeg   = [self addSegCtrlWithItems:@[ @"Low power", @"Balanced", @"High performance"]]; // create a segmented control for choosing the encoding performance
    _autoReconnect = [self addSliderName:@"Auto reconnect times" From:0.0 To:10 Init:3]; // create a slider for adjusting the auto reconnect times
    // Add a button to show the pull stream address and corresponding QR code
    _buttonPlayUrlAndQR = [self addButton:@"Pull stream address and QR code"];
    [self updateLogoBtn]; // update the logo button
    _buttonAe = [self addButton:@"Sticker editor"]; // create a button for editing stickers
    _skipBtnTap = NO;
    return self;
}

- (void)layoutUI{
    [super layoutUI];
    self.btnH = 30;
    if (self.width > self.height) {
        self.btnH = 25;
    }
    [self putRow3:_btn0
              and:_btn1
              and:_btn2];
    [self putLable:_lblScene
           andView:_liveSceneSeg];
    [self putLable:_lbrScene
           andView:_recSceneSeg];
    [self putLable:_lblPerf
           andView:_vEncPerfSeg];
    [self putRow:@[_lblLogo,_btn4,_btn3,_btn5,_btnAnimate]];
    [self putWide:_lblAnimate andNarrow:_btnNext];
    [self putNarrow:_layerSeg andWide:_alphaSl];
    [self putRow:@[_lblRec, _swBypassRec, _lblRecDur]];
    [self putRow1:_autoReconnect];
    [self putRow:@[_buttonPlayUrlAndQR, _buttonAe]];
}
- (IBAction)onBtn:(id)sender {
    if (_skipBtnTap) {
        return;
    }
    _skipBtnTap = YES;
    if (sender == _btnAnimate) {
        _btnAnimate.selected = !_btnAnimate.selected;
        [self updateLogoBtn];
    }
    else if (sender == _btnNext) {
        [_sel selectFileWithType:KSYSelectType_NEXT];
        _animatePath = _sel.filePath;
        _lblAnimate.text = _sel.fileInfo;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        _skipBtnTap = NO;
    });
    [super onBtn:sender];
}
- (void) updateLogoBtn {
    if (_btnAnimate.selected) {
        _btn3.enabled = NO;
        _btn4.enabled = NO;
        _btn5.enabled = NO;
        _btnNext.enabled = YES;
        _animatePath = _sel.filePath;
        _lblAnimate.text = _sel.fileInfo;
    }
    else {
        _btn3.enabled = YES;
        _btn4.enabled = YES;
        _btn5.enabled = YES;
        _btnNext.enabled = NO;
        _lblAnimate.text = @"";
    }
}
@synthesize liveScene = _liveScene;
- (KSYLiveScene) liveScene{
    if (_liveSceneSeg.selectedSegmentIndex == 1){
        return KSYLiveScene_Showself;
    }
    else if (_liveSceneSeg.selectedSegmentIndex == 2){
        return KSYLiveScene_Game;
    }
    else {
        return KSYLiveScene_Default;
    }
}

@synthesize recScene = _recScene;
- (KSYRecScene) recScene{
    if (_recSceneSeg.selectedSegmentIndex == 0){
        return KSYRecScene_ConstantBitRate;
    }
    else if (_recSceneSeg.selectedSegmentIndex == 1){
        return KSYRecScene_ConstantQuality;
    }
    else {
        return KSYRecScene_ConstantBitRate;
    }
}

static KSYVideoEncodePerformance perfArray[] = {
    KSYVideoEncodePer_LowPower,
    KSYVideoEncodePer_Balance,
    KSYVideoEncodePer_HighPerformance
};
@synthesize vEncPerf =  _vEncPerf;
- (KSYVideoEncodePerformance) vEncPerf{
    long idx = _vEncPerfSeg.selectedSegmentIndex;
    if ( idx >= 0 && idx < 3 ) {
        return perfArray[idx];
    }
    else {
        return KSYVideoEncodePer_Balance;
    }
}
- (void) setVEncPerf:(KSYVideoEncodePerformance)vEncPerf {
    for (int i = 0 ; i< 3; ++i) {
        if ( vEncPerf == perfArray[i] ) {
            _vEncPerfSeg.selectedSegmentIndex = i;
        }
    }
}
@end
