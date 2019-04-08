//
//  LiveShowViewController.m
//  QLLFLiveKitDemo
//
//  Created by qiu on 2019/4/8.
//  Copyright © 2019 qiu. All rights reserved.
//

#import "LiveShowViewController.h"

//权限判定
#import <AudioToolbox/AudioToolbox.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>

//主kit
#import <LFLiveKit.h>

#import "UIControl+YYAdd.h"
#import "UIView+YYAdd.h"


@interface LiveShowViewController () <LFLiveSessionDelegate>

/** 预览view */
@property (nonatomic, strong) UIView *previewView;

@property (nonatomic, strong)LFLiveSession *session;

@property (nonatomic, strong) UIButton *startLiveButton;
@property (nonatomic, strong) UILabel *stateLabel;

@end

@implementation LiveShowViewController

- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    
    //阻止iOS设备锁屏
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self RtmpInit];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    [self.view addSubview:self.previewView];
    
    //判断权限
    [self requestAccessForVideo];
    [self requestAccessForAudio];
    [self requestAccessForPhoto];
    
    
    [self.view addSubview:self.stateLabel];
    [self.view addSubview:self.startLiveButton];
    
}

#pragma mark --LFLivesession
-(void) RtmpInit{
    
    /**    自己定制高质量音频128K 分辨率设置为720*1280 方向竖屏 */
     LFLiveAudioConfiguration *audioConfiguration = [LFLiveAudioConfiguration new];
     audioConfiguration.numberOfChannels = 2;
     audioConfiguration.audioBitrate = LFLiveAudioBitRate_128Kbps;
     audioConfiguration.audioSampleRate = LFLiveAudioSampleRate_44100Hz;
     
     LFLiveVideoConfiguration *videoConfiguration = [LFLiveVideoConfiguration new];
     videoConfiguration.videoSize = CGSizeMake(720, 1280);
     videoConfiguration.videoBitRate = 800*1024;
     videoConfiguration.videoMaxBitRate = 1000*1024;
     videoConfiguration.videoMinBitRate = 500*1024;
     videoConfiguration.videoFrameRate = 15;
     videoConfiguration.videoMaxKeyframeInterval = 30;
     videoConfiguration.sessionPreset = LFCaptureSessionPreset720x1280;
     videoConfiguration.outputImageOrientation = UIInterfaceOrientationPortrait;
     LFLiveSession *session  = [[LFLiveSession alloc] initWithAudioConfiguration:[LFLiveAudioConfiguration defaultConfiguration] videoConfiguration:videoConfiguration captureType:LFLiveCaptureDefaultMask];
    
    /**    自己定制高质量音频128K 分辨率设置为720*1280 方向横屏  */
    
    /*
     LFLiveAudioConfiguration *audioConfiguration = [LFLiveAudioConfiguration new];
     audioConfiguration.numberOfChannels = 2;
     audioConfiguration.audioBitrate = LFLiveAudioBitRate_128Kbps;
     audioConfiguration.audioSampleRate = LFLiveAudioSampleRate_44100Hz;
     
     LFLiveVideoConfiguration *videoConfiguration = [LFLiveVideoConfiguration new];
     videoConfiguration.videoSize = CGSizeMake(1280, 720);
     videoConfiguration.videoBitRate = 800*1024;
     videoConfiguration.videoMaxBitRate = 1000*1024;
     videoConfiguration.videoMinBitRate = 500*1024;
     videoConfiguration.videoFrameRate = 15;
     videoConfiguration.videoMaxKeyframeInterval = 30;
     videoConfiguration.landscape = YES;
     videoConfiguration.sessionPreset = LFCaptureSessionPreset720x1280;
     
     _session = [[LFLiveSession alloc] initWithAudioConfiguration:audioConfiguration videoConfiguration:videoConfiguration];
     */
    session.mirror = NO;
    session.captureDevicePosition =  AVCaptureDevicePositionFront;
    session.delegate = self;
    session.showDebugInfo = YES;
    
    session.running = YES;
    session.muted = 0;
    session.preView= self.previewView;
    session.reconnectInterval = 2;
    session.reconnectCount = 2;
    _session = session;
}
- (UIView *)previewView {
    if (!_previewView) {
        _previewView = [UIView new];
        _previewView.frame = self.view.bounds;
        _previewView.backgroundColor = [UIColor clearColor];
        _previewView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _previewView;
}

#pragma mark -- LFStreamingSessionDelegate
- (void)liveSession:(nullable LFLiveSession *)session liveStateDidChange:(LFLiveState)state {
    switch (state) {
        case LFLiveReady:
            NSLog(@"准备完成");
            _stateLabel.text = @"未连接";
            break;
        case LFLivePending:
             NSLog(@"连接中");
            _stateLabel.text = @"连接中";
            break;
        case LFLiveStart:
             NSLog(@"已连接");
            _stateLabel.text = @"已连接";
            break;
        case LFLiveStop:
            NSLog(@"已断开");
            _stateLabel.text = @"未连接";
            break;
        case LFLiveError:
             NSLog(@"连接出错");
            _stateLabel.text = @"连接错误";
            break;
        case LFLiveRefresh:
            NSLog(@"正在刷新");
            _stateLabel.text = @"正在刷新";
            break;
        default:
            break;
    }
}

//连接失败
- (void)liveSession:(LFLiveSession *)session errorCode:(LFLiveSocketErrorCode)errorCode{
    NSLog(@"连接服务器失败");
}

//直播流的信息，如果需要显示当前流量和实时码率等信息可以在这个方法里实现
- (void)liveSession:(LFLiveSession *)session debugInfo:(LFLiveDebug *)debugInfo{
    
}

- (UILabel *)stateLabel {
    if (!_stateLabel) {
        _stateLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 80, 40)];
        _stateLabel.text = @"未连接";
        _stateLabel.textColor = [UIColor whiteColor];
        _stateLabel.font = [UIFont boldSystemFontOfSize:14.f];
    }
    return _stateLabel;
}

- (UIButton *)startLiveButton {
    if (!_startLiveButton) {
        _startLiveButton = [UIButton new];
        _startLiveButton.size = CGSizeMake(self.view.width - 60, 44);
        _startLiveButton.left = 30;
        _startLiveButton.bottom = self.view.height - 50;
        _startLiveButton.layer.cornerRadius = _startLiveButton.height/2;
        [_startLiveButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_startLiveButton.titleLabel setFont:[UIFont systemFontOfSize:16]];
        [_startLiveButton setTitle:@"开始直播" forState:UIControlStateNormal];
        [_startLiveButton setBackgroundColor:[UIColor colorWithRed:50 green:32 blue:245 alpha:1]];
        _startLiveButton.exclusiveTouch = YES;
        __weak typeof(self) _self = self;
        [_startLiveButton addBlockForControlEvents:UIControlEventTouchUpInside block:^(id sender) {
            _self.startLiveButton.selected = !_self.startLiveButton.selected;
            if (_self.startLiveButton.selected) {
                [_self.startLiveButton setTitle:@"结束直播" forState:UIControlStateNormal];
                LFLiveStreamInfo *stream = [LFLiveStreamInfo new];
//                stream.url = @"rtmp://live.hkstv.hk.lxdns.com:1935/live/stream153";
                stream.url = @"rtmp://192.168.0.101:1935/rtmplive/room";
                [_self.session startLive:stream];
            } else {
                [_self.startLiveButton setTitle:@"开始直播" forState:UIControlStateNormal];
                [_self.session stopLive];
            }
        }];
    }
    return _startLiveButton;
}

#pragma mark -- 请求权限
- (void)requestAccessForVideo {
    __weak typeof(self) _self = self;
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (status) {
        case AVAuthorizationStatusNotDetermined: {
            // 许可对话没有出现，发起授权许可
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_self.session setRunning:YES];
                    });
                }
            }];
            break;
        }
        case AVAuthorizationStatusAuthorized: {
            // 已经开启授权，可继续
            dispatch_async(dispatch_get_main_queue(), ^{
                [_self.session setRunning:YES];
            });
            break;
        }
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted:
        // 用户明确地拒绝授权，或者相机设备无法访问
        
        break;
        default:
        break;
    }
}
    
- (void)requestAccessForAudio {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    switch (status) {
        case AVAuthorizationStatusNotDetermined: {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
            }];
            break;
        }
        case AVAuthorizationStatusAuthorized: {
            break;
        }
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted:
        break;
        default:
        break;
    }
}
    
    
- (void)requestAccessForPhoto{
    PHAuthorizationStatus authStatus = [PHPhotoLibrary authorizationStatus];
    switch (authStatus) {
        case PHAuthorizationStatusNotDetermined:
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        }];
        break;
        //无法授权
        case PHAuthorizationStatusRestricted:
        
        break;
        //明确拒绝
        case PHAuthorizationStatusDenied:
        
        break;
        
        //已授权
        case PHAuthorizationStatusAuthorized:
        
        break;
        
        default:
        break;
    }
}
@end
