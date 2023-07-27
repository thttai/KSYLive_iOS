//
//  KSYPipView.m
//  KSYGPUStreamerDemo
//
//  Created by 孙健 on 16/6/24.
//  Copyright © 2016年 ksyun. All rights reserved.
//

#import "KSYPipView.h"
#import "KSYNameSlider.h"
#import "KSYFileSelector.h"

@interface KSYPipView (){
    UILabel * _pipTitle;
    KSYFileSelector * _pipSel;
    KSYFileSelector * _bgpSel;
}
@end

@implementation KSYPipView
-(id)init{
    self = [super init];
    _pipStatus  = @"idle";
    _pipTitle   = [self addLable:@"PIP address Documents/movies"];
    _pipTitle.numberOfLines = 2;
    _pipTitle.textAlignment = NSTextAlignmentLeft;
    
    _progressV  = [[UIProgressView alloc] init];
    [self addSubview:_progressV];
    _pipPlay    = [self addButton:@"Play"]; // create a button for playing the video
    _pipPause   = [self addButton:@"Pause"]; // create a button for pausing the video
    _pipStop    = [self addButton:@"Stop"]; // create a button for stopping the video
    _pipNext    = [self addButton:@"Next video file"]; // create a button for switching to the next video file
    _bgpNext    = [self addButton:@"Next background image"]; // create a button for switching to the next background image
    _volumSl    = [self addSliderName:@"Volume" From:0 To:100 Init:50]; // create a slider for adjusting the volume
    
    _pipPattern = @[@".mp4", @".flv"];
    _bgpPattern = @[@".jpg",@".jpeg", @".png"];
    
    _pipSel = [[KSYFileSelector alloc] initWithDir:@"/Documents/movies/"
                                         andSuffix:_pipPattern];
    _bgpSel = [[KSYFileSelector alloc] initWithDir:@"/Documents/images/"
                                         andSuffix:_bgpPattern];
    if(_pipSel.filePath){
        _pipURL = [NSURL fileURLWithPath:_pipSel.filePath];
    }
    if(_bgpSel.filePath){
        _bgpURL = [NSURL fileURLWithPath:_bgpSel.filePath];
    }
    return self;
}
- (void)layoutUI{
    [super layoutUI];
    self.btnH = 10;
    [self putRow1:_progressV];
    self.btnH = 60;
    [self putRow1:_pipTitle];
    self.btnH = 30;
    [self putRow:@[_pipPlay,_pipPause, _pipStop] ];
    [self putRow1:_volumSl];
    [self putRow2:_pipNext
              and:_bgpNext];
}


- (IBAction)onBtn:(id)sender {
    if (sender == _pipNext){
        if( [_pipSel selectFileWithType:KSYSelectType_NEXT]){
            _pipURL = [NSURL fileURLWithPath:_pipSel.filePath];
        }
    }
    if (sender == _bgpNext){
        if( [_bgpSel selectFileWithType:KSYSelectType_NEXT] ){
            _bgpURL = [NSURL fileURLWithPath:_bgpSel.filePath];
        }
    }
    _pipTitle.text = [NSString stringWithFormat:@"%@: %@\n%@", _pipStatus, _pipSel.fileInfo, _bgpSel.fileInfo ];
    [super onBtn:sender];
}

@synthesize pipStatus = _pipStatus;
- (void) setPipStatus:(NSString *)pipStatus{
    _pipStatus = pipStatus;
    _pipTitle.text = [NSString stringWithFormat:@"%@: %@\n%@", _pipStatus, _pipSel.fileInfo, _bgpSel.fileInfo];
}
- (NSString *) pipStatus{
    return _pipStatus;
}
@end
