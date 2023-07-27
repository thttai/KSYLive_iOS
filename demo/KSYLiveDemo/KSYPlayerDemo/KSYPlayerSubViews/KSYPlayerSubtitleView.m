//
//  KSYPlayerSubtitleView.m
//
//  Created by 施雪梅 on 17/7/12.
//  Copyright © 2017年 ksyun. All rights reserved.
//

#import "KSYPlayerSubtitleView.h"

#define COLOR_NUMBER 5
#define FONT_NUMBER 3

@interface KSYPlayerSubtitleView()<UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate,UIGestureRecognizerDelegate>{
    UILabel *_labelColor;
    UILabel *_labelFont;
    
    NSMutableArray *_colorPosArray;
    UILabel *_labelColorArray[COLOR_NUMBER];
    
    NSMutableArray *_fontPosArray;
    UILabel *_labelFontArray[COLOR_NUMBER];
    
    UILabel *_labelSubtitle;
    
    UIButton *_btnCloseSubtitle;
    UIButton *_btnOpenSubtitleFile;
    UITableView *_tableSubtitle;
    
    NSMutableArray *_extSubtitleFiles;
    
    NSString *_documentDir;
}
@end

@implementation KSYPlayerSubtitleView

- (id)init{
    self = [super init];
    
    _colorPosArray = [NSMutableArray array];
    for (int i = 0; i < COLOR_NUMBER; i++) {
        UIColor *color = [UIColor colorWithHue:i / (float)5 saturation:1.0 brightness:1.0 alpha:1.0];
        _labelColorArray[i] = [[UILabel alloc] init];
        _labelColorArray[i].backgroundColor = color;
    }
    
    NSArray *fontArray = [[NSArray alloc] initWithObjects:@"Georgia-Italic", @"Times New Roman", @"Zapfino", nil];
    _fontPosArray = [NSMutableArray array];
    for(int i = 0; i < FONT_NUMBER; i++)
    {
        _labelFontArray[i] = [[UILabel alloc] init];
        _labelFontArray[i].backgroundColor = [UIColor whiteColor];
        _labelFontArray[i].text = [fontArray objectAtIndex:i];
        _labelFontArray[i].textAlignment = NSTextAlignmentCenter;
        _labelFontArray[i].font = [UIFont fontWithName:_labelFontArray[i].text size:12];
    }
    
    _documentDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    _extSubtitleFiles = [NSMutableArray array];
    NSError *error = nil;
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_documentDir error:&error];
    for (NSString *fileName in files) {
        if([fileName hasSuffix:@".srt"] || [fileName hasSuffix:@".ass"])
            [_extSubtitleFiles addObject:fileName];
    }
    
    [self setupUI];
    
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(colorGridTapped:)];
    recognizer.delegate = self;
    [self addGestureRecognizer:recognizer];
    
    return self;
}

- (void) setupUI {
    _sliderFontSize =  [self addSliderName:@"Size" From:12 To:20 Init:16]; // create a slider for adjusting the font size
    _labelColor =  [self addLable:@"Color"]; // create a label for color option
    _labelFont = [self addLable:@"Font"]; // create a label for font option
    _labelSubtitle = [self addLable:@"Switch embedded subtitles"]; // create a label for subtitle option
    _btnCloseSubtitle = [self addButton:@"Close subtitles"]; // create a button for closing the subtitles
    _btnOpenSubtitleFile = [self addButton:@"Open local subtitle file"]; // create a button for opening a local subtitle file
    
    _tableSubtitle= [[UITableView alloc]init];
    _tableSubtitle.delegate   = self;
    _tableSubtitle.dataSource = self;
    [self addSubview:_tableSubtitle];
    
    [self layoutUI];
}

- (void)layoutUI{
    [super layoutUI];
    self.yPos = 0;
    
    [self putNarrow:_labelColor andWide:nil];
    
    for (int i = 0; i < COLOR_NUMBER; i++) {
        float elemWidth = (self.frame.size.width -  CGRectGetMaxX(_labelColor.frame) - (COLOR_NUMBER + 1) * self.gap)  / (COLOR_NUMBER);
        if(elemWidth > 0)
        {
            CGRect rect = CGRectMake(CGRectGetMaxX(_labelColor.frame) + self.gap + i * (elemWidth + self.gap), CGRectGetMinY(_labelColor.frame), elemWidth, self.btnH);
             _labelColorArray[i].frame = rect;
            [_colorPosArray addObject:[NSValue valueWithCGRect:rect]];
        }
        
        [self addSubview: _labelColorArray[i]];
    }
    
    [self putNarrow:_labelFont andWide:nil];
    
    for (int i = 0; i < FONT_NUMBER; i++) {
        float elemWidth = (self.frame.size.width -  CGRectGetMaxX(_labelColor.frame) - (FONT_NUMBER + 1) * self.gap)  / (FONT_NUMBER);
        if(elemWidth > 0)
        {
            CGRect rect = CGRectMake(CGRectGetMaxX(_labelFont.frame) + self.gap + i * (elemWidth + self.gap), CGRectGetMinY(_labelFont.frame), elemWidth, self.btnH);
            _labelFontArray[i].frame = rect;
            [_fontPosArray addObject:[NSValue valueWithCGRect:rect]];
        }
        
        [self addSubview:_labelFontArray[i]];
    }
    
    [self putRow1:_sliderFontSize];
    
    if(_subtitleNumBlock)
        _subtitleNumBlock();
    if(_subtitleNum > 0)
    {
        NSMutableArray *subtitleItem = [NSMutableArray array];
        for(int i = 0; i < _subtitleNum; i++)
        {
            NSString *name  = [NSString stringWithFormat:@"Subtitle%d", i+1]; // create a string for the subtitle name with an index
            [subtitleItem addObject:name];
        }
        _segSubtitle = [self addSegCtrlWithItems:subtitleItem];
        _segSubtitle.selectedSegmentIndex = _selectedSubtitleIndex;
        [self putLable:_labelSubtitle andView:_segSubtitle];
    }
    [self putRow1:_btnCloseSubtitle];
    [self putRow1:_btnOpenSubtitleFile];
    
    _btnCloseSubtitle.selected = NO;
    _btnOpenSubtitleFile.selected = NO;
    float yPos = CGRectGetMaxY(_btnOpenSubtitleFile.frame) + self.gap;
    _tableSubtitle.frame = CGRectMake(0, yPos, self.width, (self.height - yPos) / 2);
    _tableSubtitle.backgroundColor = [UIColor grayColor];
    _tableSubtitle.hidden = YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    // 若为UITableViewCellContentView（即点击了tableViewCell），则不截获Touch事件
    if ([NSStringFromClass([touch.view class]) isEqualToString:@"UITableViewCellContentView"]) {
        return NO;
    }
    return  YES;
}

- (void) colorGridTapped:(UITapGestureRecognizer *)recognizer {
    CGPoint point = [recognizer locationInView:self];
    
    CGRect pos = [[_colorPosArray objectAtIndex:0] CGRectValue];
    if(point.y >= pos.origin.y && point.y <= pos.origin.y + pos.size.height)
    {
        for (int i = 0; i < COLOR_NUMBER; i++) {
            pos = [[_colorPosArray objectAtIndex:i] CGRectValue];
            if(point.x >= pos.origin.x && point.x <=  pos.origin.x + pos.size.width)
            {
                if(_fontColorBlock)
                    _fontColorBlock(_labelColorArray[i].backgroundColor);
                return ;
            }
        }
    }
    
    pos = [[_fontPosArray objectAtIndex:0] CGRectValue];
    if(point.y >= pos.origin.y && point.y <= pos.origin.y + pos.size.height)
    {
        for (int i = 0; i < FONT_NUMBER; i++) {
            pos = [[_fontPosArray objectAtIndex:i] CGRectValue];
            if(point.x >= pos.origin.x && point.x <=  pos.origin.x + pos.size.width)
            {
                if(_fontBlock)
                    _fontBlock(_labelFontArray[i].text);
                return ;
            }
        }
    }
}

- (void)onBtn:(id)sender {
    if(sender == _btnOpenSubtitleFile)
    {
        _btnOpenSubtitleFile.selected = !_btnOpenSubtitleFile.selected;
        _tableSubtitle.hidden = !_tableSubtitle.hidden;
    }
    else if(sender == _btnCloseSubtitle)
    {
        _tableSubtitle.hidden = YES;
        _btnOpenSubtitleFile.selected = NO;
        if(_closeSubtitleBlock)
            _closeSubtitleBlock();
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
        return _extSubtitleFiles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"abc"];
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"abc"];
        cell.textLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    }
    
    cell.textLabel.text = _extSubtitleFiles[indexPath.row];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.backgroundColor = [UIColor grayColor];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if(_subtitleFileSelectedBlock)
        _subtitleFileSelectedBlock([NSString stringWithFormat:@"%@%s%@", _documentDir, "/", _extSubtitleFiles[indexPath.row]]);
}

@end
