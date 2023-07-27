//
//  KSYVideoListVC.m
//  KSYLiveDemo
//
//  Created by iVermisseDich on 2017/3/23.
//  Copyright © 2017年 qyvideo. All rights reserved.
//

#import "KSYVideoListVC.h"
#import <libksygpulive/KSYMoviePlayerController.h>

#pragma mark - KSYVideoListCell

@interface KSYVideoListCell : UITableViewCell

@end

@implementation KSYVideoListCell

- (instancetype)init{
    if (self = [super init]) {
        [self setupSubview];
    }
    return self;
}

- (void)setupSubview{
    UIView *ctrlView = [[UIView alloc] initWithFrame:self.bounds];
    
    [self.contentView addSubview:ctrlView];
}

@end

#define kVideoListCellReuseId @"com.ksyun.videolistcell.reuseid"

#pragma mark - KSYVideoListVC

@interface KSYVideoListVC ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *videoList;

// 播放地址
@property (nonatomic, strong) NSArray *videoUrls;

// 记录播放进度（用于点播，当地址为直播和点播混合时，建议使用字典）
@property (nonatomic, strong) NSMutableArray *playbackTimes;

// 当前的播放器
@property (nonatomic, strong) KSYMoviePlayerController *player;
// 当前播放的cell 的indexPath
@property (nonatomic, assign) NSIndexPath *curPlayingIdx;

@end

@implementation KSYVideoListVC

- (id)initWithUrl:(NSURL *)videoListUrl{
    if (self = [super init]) {
        _videoUrls = @[videoListUrl,videoListUrl,videoListUrl,videoListUrl,videoListUrl];
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // 此处初始化为0，也可根据其他方式保存的历史记录，进行初始化
    _playbackTimes = [NSMutableArray array];
    for (NSInteger i = 0; i < _videoUrls.count; ++i) {
        [_playbackTimes addObject:@(0)];
    }
    
    [self setupUI];
}

- (void)setupUI{
    self.view.backgroundColor = [UIColor whiteColor];
    _videoList = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    [_videoList registerClass:[KSYVideoListCell class] forCellReuseIdentifier:kVideoListCellReuseId];
    _videoList.dataSource = self;
    _videoList.delegate = self;
    [self.view addSubview:_videoList];
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    //返回流地址个数
    return _videoUrls.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    KSYVideoListCell *cell = [tableView dequeueReusableCellWithIdentifier:kVideoListCellReuseId forIndexPath:indexPath];
    //视频标题
    cell.textLabel.text = [NSString stringWithFormat:@"Video-%ld Cover Art",(long)indexPath.row];
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return self.view.frame.size.width * self.view.frame.size.width / self.view.frame.size.height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    //Get the play URL of the selected video
    NSURL *url = _videoUrls[indexPath.row];
    KSYVideoListCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (!_player) {
        //Initialize the player
        _player = [[KSYMoviePlayerController alloc] initWithContentURL:url];
        _player.scalingMode = MPMovieScalingModeAspectFill;
        _player.view.frame = cell.bounds;
        [cell.contentView addSubview:_player.view];
        [cell.contentView sendSubviewToBack:_player.view];
        //Prepare the video playback
        [_player prepareToPlay];
    } else if (_curPlayingIdx == indexPath) {
        //If the selected video is the one that is already playing
        if (_player.isPlaying) {
            [_player pause];
            // Record the playback duration
            _playbackTimes[indexPath.row] = @(_player.currentPlaybackTime);
        }else if ([_player playbackState] == MPMoviePlaybackStatePaused){
            [_player play];
        }else {
            // Check superView
            if ([_player.view superview] != cell.contentView) {
                [_player.view removeFromSuperview];
                _player.view.frame = cell.bounds;
                [cell.contentView addSubview:_player.view];
                [cell.contentView sendSubviewToBack:_player.view];
            }
            [_player prepareToPlay];
        }
    } else {//Choose to play a new video
        // Reset the player
        [_player reset:NO];
        // Set new URL
        [_player setUrl:url];
        // Add play view to cell
        [_player.view removeFromSuperview];
        _player.view.frame = cell.bounds;
        [cell.contentView addSubview:_player.view];
        [cell.contentView sendSubviewToBack:_player.view];
        // Get the playback progress
        NSTimeInterval pos = [_playbackTimes[indexPath.row] doubleValue];
        // Start playing
        [_player seekTo:pos accurate:YES];
        [_player prepareToPlay];
    }
    
    _curPlayingIdx = indexPath;
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    // 暂停播放，可扩展超出屏幕的悬浮窗播放等需求
    if (_curPlayingIdx == indexPath) {
        [_player pause];
        [_player.view removeFromSuperview];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath == _curPlayingIdx) {
        if (_player.playbackState == MPMoviePlaybackStatePaused) {
            _player.view.frame = cell.contentView.bounds;
            [cell.contentView addSubview:_player.view];
            [cell.contentView sendSubviewToBack:_player.view];
        }
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    //将返回按钮放置在tableView的上部
    if (section == 0) {
        UIButton *quitBtn = [[UIButton alloc] init];
        [quitBtn addTarget:self action:@selector(onQuit:) forControlEvents:UIControlEventTouchUpInside];
        quitBtn.backgroundColor = [UIColor lightGrayColor];
        [quitBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [quitBtn setTitle:@"return" forState:UIControlStateNormal];
        [quitBtn sizeToFit];
        return quitBtn;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (section == 0) {
        return 44;
    }
    return 0;
}

#pragma mark - onAction
- (void)onQuit:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dealloc{
    [self.player stop];
}

@end
