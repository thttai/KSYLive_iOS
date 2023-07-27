//
//  KSYFilterView.m
//  KSYGPUStreamerDemo
//
//  Created by 孙健 on 16/6/24.
//  Copyright © 2016年 ksyun. All rights reserved.
//
#import <GPUImage/GPUImage.h>
#import "KSYFilterView.h"
#import "KSYNameSlider.h"
#import "KSYPresetCfgView.h"
#import "ZipArchive.h"


@interface KSYFilterView() {
    UILabel * _lblSeg;
    NSInteger _curIdx;
    NSArray * _effectNames;
    NSInteger _curEffectIdx;
    //GPUResource资源的存储路径
    NSString *_gpuResourceDir;
}

@property (nonatomic) UILabel * lbPrevewFlip;
@property (nonatomic) UILabel * lbStreamFlip;

@property (nonatomic) UILabel * lbUiRotate;
@property (nonatomic) UILabel * lbStrRotate;

@property KSYNameSlider *proFilterLevel;
@property UIStepper *proFilterLevelStep;

@end

@implementation KSYFilterView

- (id)init{
    self = [super init];
    _effectNames = [NSArray arrayWithObjects:
    @"0 Original image without effects",
    @"1 Fresh and clean",
    @"2 Beautiful",
    @"3 Sweet and lovely",
    @"4 Nostalgic",
    @"5 Blues",
    @"6 Old photo",
    @"7 Cherry blossom",
    @"8 Cherry blossom (suitable for darker environments)",
    @"9 Rosy (suitable for darker environments)",
    @"10 Sunshine (suitable for darker environments)",
    @"11 Rosy",
    @"12 Sunshine",
    @"13 Natural",
    @"14 Lovers",
    @"15 Elegant",
    @"16 Pink lady ",
    @"17 Yogurt ",
    @"18 Fleeting ",
    @"19 Soft light ",
    @"20 Classic ",
    @"21 Early summer ",
    @"22 Black and white ",
    @"23 New York ",
    @"24 Ueno ",
    @"25 Azure ",
    @"26 Japanese style ",
    @"27 Cool ",
    @"28 Tilt-shift ",
    @"29 Dreamy ",
    @"30 Tranquil ",
    @"31 Migratory bird ",
    @"32 Graceful ", nil];
    [self downloadGPUResource];
    _curEffectIdx = 1;
    // 修改美颜parameter
    _filterParam1 = [self addSliderName:@"Parameter" From:0 To:100 Init:50]; // create a slider for adjusting the parameter value
    _filterParam2 = [self addSliderName:@"Whitening" From:0 To:100 Init:50]; // create a slider for adjusting the whitening value
    _filterParam3 = [self addSliderName:@"Rosy" From:0 To:100 Init:50]; // create a slider for adjusting the rosy value
    _filterParam2.hidden = YES; // hide the whitening slider
    _filterParam3.hidden = YES; // hide the rosy slider

    _proFilterLevel    = [self addSliderName:@"Type" From:1 To:4 Init:1]; // create a slider for choosing the filter type
    _proFilterLevel.precision = 0;
    _proFilterLevel.slider.enabled = NO;
    _proFilterLevelStep  = [[UIStepper alloc] init];
    _proFilterLevelStep.continuous = NO;
    _proFilterLevelStep.maximumValue = 4;
    _proFilterLevelStep.minimumValue = 1;
    [self addSubview:_proFilterLevelStep];
    [_proFilterLevelStep addTarget:self
                   action:@selector(onStep:)
         forControlEvents:UIControlEventValueChanged];
    _proFilterLevel.hidden = YES;
    _proFilterLevelStep.hidden = YES;
    
    _lblSeg = [self addLable:@"Filter"]; // create a label for filter option
    _filterGroupType = [self addSegCtrlWithItems:
    @[ @"Off",
    @"Old beauty",
    @"Beauty pro",
    @"Natural",
    @"Rosy",
    @"Effect",
    ]]; // create a segmented control for choosing the filter group type
    _filterGroupType.selectedSegmentIndex = 1; // set the default filter group type to old beauty
    [self selectFilter:1]; // select the old beauty filter

    _lbPrevewFlip = [self addLable:@"Preview mirror"]; // create a label for preview mirror option
    _lbStreamFlip = [self addLable:@"Push stream mirror"]; // create a label for push stream mirror option
    _swPrevewFlip = [self addSwitch:NO]; // create a switch for preview mirror option
    _swStreamFlip = [self addSwitch:NO]; // create a switch for push stream mirror option

    _lbUiRotate   = [self addLable:@"UI rotation"]; // create a label for UI rotation option
    _lbStrRotate  = [self addLable:@"Push stream rotation"]; // create a label for push stream rotation option
    _swUiRotate   = [self addSwitch:NO];
    _swStrRotate  = [self addSwitch:NO];
    _swStrRotate.enabled = NO;
    
    _effectPicker = [[UIPickerView alloc] init];
    [self addSubview: _effectPicker];
    _effectPicker.hidden     = YES;
    _effectPicker.delegate   = self;
    _effectPicker.dataSource = self;
    _effectPicker.showsSelectionIndicator= YES;
    _effectPicker.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.3];
    [_effectPicker selectRow:1 inComponent:0 animated:YES];
    return self;
}
- (void)layoutUI{
    [super layoutUI];
    self.yPos = 0;
    [self putRow: @[_lbPrevewFlip, _swPrevewFlip,
                    _lbStreamFlip, _swStreamFlip ]];
    [self putRow: @[_lbUiRotate, _swUiRotate,
                    _lbStrRotate, _swStrRotate ]];
    [self putLable:_lblSeg andView: _filterGroupType];
    CGFloat paramYPos = self.yPos;
    if ( self.width > self.height){
        self.winWdt /= 2;
    }
    [self putRow1:_filterParam1];
    [self putRow1:_filterParam2];
    [self putRow1:_filterParam3];
    [self putWide:_proFilterLevel andNarrow:_proFilterLevelStep];
    
    if ( self.width > self.height){
        _effectPicker.frame = CGRectMake( self.winWdt, paramYPos, self.winWdt, 162);
    }
    else {
        self.btnH = 162;
        [self putRow1:_effectPicker];
    }
}

- (IBAction)onStep:(id)sender {
    if (sender == _proFilterLevelStep) {
        _proFilterLevel.value = _proFilterLevelStep.value;
        [self selectFilter: _filterGroupType.selectedSegmentIndex];
    }
    [super onSegCtrl:sender];
}

- (IBAction)onSwitch:(id)sender {
    if (sender == _swUiRotate){
        // 只有界面跟随设备旋转, 推流才能旋转
        _swStrRotate.enabled = _swUiRotate.on;
        if (!_swUiRotate.on) {
            _swStrRotate.on = NO;
        }
    }
    [super onSwitch:sender];
}

- (IBAction)onSegCtrl:(id)sender {
    if (_filterGroupType == sender){
        [self selectFilter: _filterGroupType.selectedSegmentIndex];
    }
    [super onSegCtrl:sender];
}
- (void) selectFilter:(NSInteger)idx {
    _curIdx = idx;
    _filterParam1.hidden = YES;
    _filterParam2.hidden = YES;
    _filterParam3.hidden = YES;
    _proFilterLevel.hidden = YES;
    _proFilterLevelStep.hidden = YES;
    _effectPicker.hidden = YES;
    // 标识当前被选择的滤镜
    if (idx == 0){
        _curFilter  = nil;
    }
    else if (idx == 1){
        _filterParam1.nameL.text = @"parameter";
        _filterParam1.hidden = NO;
        _curFilter = [[KSYGPUBeautifyExtFilter alloc] init];
    }
    else if (idx == 2){ // 美颜pro
        _filterParam1.hidden = NO;
        _filterParam2.hidden = NO;
        _filterParam3.hidden = NO;
        _proFilterLevel.hidden = NO;
        _proFilterLevelStep.hidden = NO;
        KSYBeautifyProFilter * f = [[KSYBeautifyProFilter alloc] initWithIdx:_proFilterLevel.value];
        _filterParam1.nameL.text = @"Microdermabrasion";
        f.grindRatio  = _filterParam1.normalValue;
        f.whitenRatio = _filterParam2.normalValue;
        f.ruddyRatio  = _filterParam3.normalValue;
        _curFilter    = f;
    }
    else if (idx == 3){ // natural
        _filterParam1.hidden = NO;
        _filterParam2.hidden = NO;
        _filterParam3.hidden = NO;
        KSYBeautifyProFilter * nf = [[KSYBeautifyProFilter alloc] initWithIdx:3];
        _filterParam1.nameL.text = @"Microdermabrasion";
        nf.grindRatio  = _filterParam1.normalValue;
        nf.whitenRatio = _filterParam2.normalValue;
        nf.ruddyRatio  = _filterParam3.normalValue;
        _curFilter    = nf;
    }
    else if (idx == 4){ // rosy + 美颜
        _filterParam1.nameL.text = @"Microdermabrasion";
        _filterParam3.nameL.text = @"rosy";
        _filterParam1.hidden = NO;
        _filterParam2.hidden = NO;
        _filterParam3.hidden = NO;
        NSString *imgPath=[_gpuResourceDir stringByAppendingString:@"3_tianmeikeren.png"];
        UIImage *rubbyMat=[[UIImage alloc]initWithContentsOfFile:imgPath];
        if (rubbyMat == nil) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Tip"
                                                            message:@"The effect resources are being downloaded, please try again later"
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"OK", nil]; // create an alert view with a tip message and an OK button
            alert.alertViewStyle = UIAlertViewStyleDefault;
            [alert show];
        }
        KSYBeautifyFaceFilter *bf = [[KSYBeautifyFaceFilter alloc] initWithRubbyMaterial:rubbyMat];
        bf.grindRatio  = _filterParam1.normalValue;
        bf.whitenRatio = _filterParam2.normalValue;
        bf.ruddyRatio  = _filterParam3.normalValue;
        _curFilter = bf;
    }
    else if (idx == 5){ // 美颜 + special effects 滤镜组合
        _filterParam1.nameL.text = @"Microdermabrasion";
        _filterParam3.nameL.text = @"special effects";
        _filterParam1.hidden = NO;
        _filterParam2.hidden = NO;
        _filterParam3.hidden = NO;
        _effectPicker.hidden = NO;
        _proFilterLevel.hidden = NO;
        _proFilterLevelStep.hidden = NO;
        // 构造美颜滤镜 和  special effects滤镜
        KSYBeautifyProFilter    * bf = [[KSYBeautifyProFilter alloc] initWithIdx:_proFilterLevel.value];
        bf.grindRatio  = _filterParam1.normalValue;
        bf.whitenRatio = _filterParam2.normalValue;
        bf.ruddyRatio  = 0.5;
        
        KSYBuildInSpecialEffects * sf = [[KSYBuildInSpecialEffects alloc] initWithIdx:_curEffectIdx];
        sf.intensity   = _filterParam3.normalValue;
        [bf addTarget:sf];
        
        // 用滤镜组 将 滤镜 串联成整体
        GPUImageFilterGroup * fg = [[GPUImageFilterGroup alloc] init];
        [fg addFilter:bf];
        [fg addFilter:sf];
        
        [fg setInitialFilters:[NSArray arrayWithObject:bf]];
        [fg setTerminalFilter:sf];
        _curFilter = fg;
    }
    else {
        _curFilter = nil;
    }
}

- (IBAction)onSlider:(id)sender {
    if (sender != _filterParam1 &&
        sender != _filterParam2 &&
        sender != _filterParam3 ) {
        return;
    }
    float nalVal = _filterParam1.normalValue;
    if (_curIdx == 1){
        int val = (nalVal*5) + 1; // level 1~5
        [(KSYGPUBeautifyExtFilter *)_curFilter setBeautylevel: val];
    }
    else if (_curIdx == 2 || _curIdx == 3) {
        KSYBeautifyProFilter * f =(KSYBeautifyProFilter*)_curFilter;
        if (sender == _filterParam1 ){
            f.grindRatio = _filterParam1.normalValue;
        }
        if (sender == _filterParam2 ) {
            f.whitenRatio = _filterParam2.normalValue;
        }
        if (sender == _filterParam3 ) {  // rosyparameter
            f.ruddyRatio = _filterParam3.normalValue;
        }
    }
    else if (_curIdx == 4 ){ // 美颜
        KSYBeautifyFaceFilter * f =(KSYBeautifyFaceFilter*)_curFilter;
        if (sender == _filterParam1 ){
            f.grindRatio = _filterParam1.normalValue;
        }
        if (sender == _filterParam2 ) {
            f.whitenRatio = _filterParam2.normalValue;
        }
        if (sender == _filterParam3 ) {  // rosyparameter
            f.ruddyRatio = _filterParam3.normalValue;
        }
    }
    else if ( _curIdx == 5 ){
        GPUImageFilterGroup * fg = (GPUImageFilterGroup *)_curFilter;
        KSYBeautifyProFilter    * bf = (KSYBeautifyProFilter *)[fg filterAtIndex:0];
        KSYBuildInSpecialEffects * sf = (KSYBuildInSpecialEffects *)[fg filterAtIndex:1];
        if (sender == _filterParam1 ){
            bf.grindRatio = _filterParam1.normalValue;
        }
        if (sender == _filterParam2 ) {
            bf.whitenRatio = _filterParam2.normalValue;
        }
        if (sender == _filterParam3 ) {  // special effectsparameter
            [sf setIntensity:_filterParam3.normalValue];
        }
    }
    [super onSlider:sender];
}

#pragma mark - effect picker
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView*)pickerView {
    return 1; // 单列
}
- (NSInteger)pickerView:(UIPickerView *)pickerView
numberOfRowsInComponent:(NSInteger)component {
    return _effectNames.count;//
}
- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component{
    return [_effectNames objectAtIndex:row];
}
- (void)pickerView:(UIPickerView *)pickerView
      didSelectRow:(NSInteger)row
       inComponent:(NSInteger)component {
    _curEffectIdx = row;
    if (! [_curFilter isMemberOfClass:[GPUImageFilterGroup class]]){
        return;
    }
    GPUImageFilterGroup * fg = (GPUImageFilterGroup *)_curFilter;
    if (![fg.terminalFilter isMemberOfClass:[KSYBuildInSpecialEffects class]]) {
        return;
    }
    KSYBuildInSpecialEffects * sf = (KSYBuildInSpecialEffects *)fg.terminalFilter;
    [sf setSpecialEffectsIdx:_curEffectIdx];
}

-(void)downloadGPUResource{ // 下载资源文件
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    _gpuResourceDir=[NSHomeDirectory() stringByAppendingString:@"/Documents/GPUResource/"];
    // 判断文件夹是否存在，如果不存在，则创建
    if (![[NSFileManager defaultManager] fileExistsAtPath:_gpuResourceDir]) {
        [fileManager createDirectoryAtPath:_gpuResourceDir
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:nil];
    }
    NSString *zipPath = [_gpuResourceDir stringByAppendingString:@"KSYGPUResource.zip"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:zipPath]) {
        return; // already downloaded
    }
    NSString *zipUrl = @"https://ks3-cn-beijing.ksyun.com/ksy.vcloud.sdk/Ios/KSYLive_iOS_Resource/KSYGPUResource.zip";
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSURL *url =[NSURL URLWithString:zipUrl];
        NSData *data =[NSData dataWithContentsOfURL:url];
        [data writeToFile:zipPath atomically:YES];
        ZipArchive *zipArchive = [[ZipArchive alloc] init];
        [zipArchive UnzipOpenFile:zipPath ];
        [zipArchive UnzipFileTo:_gpuResourceDir overWrite:YES];
        [zipArchive UnzipCloseFile];
    });
}

@end
