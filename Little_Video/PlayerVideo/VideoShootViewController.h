//
//  VideoShootViewController.h
//  LittleVideo
//
//  Created by JIng on 2017/2/23.
//  Copyright © 2017年 JIng. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#define TIMER_INTERVAL 0.05
#define VIDEO_FOLDER @"videoFolder"


typedef void(^PropertyChangeBlock)(AVCaptureDevice *captureDevice);


@interface VideoShootViewController : UIViewController<AVCaptureFileOutputRecordingDelegate>//视频文件输出代理
{
    
    NSMutableArray* urlArray;//保存视频片段的数组
    
    float currentTime; //当前视频长度
    
    NSTimer *countTimer; //计时器
    UIView* progressPreView; //进度条
    float progressStep; //进度条每次变长的最小单位
    
    float preLayerWidth;//镜头宽
    float preLayerHeight;//镜头高
    float preLayerHWRate; //高，宽比
    
}

@property (weak, nonatomic) IBOutlet UIView *TopView;


@property (strong,nonatomic) AVCaptureSession *captureSession;//负责输入和输出设置之间的数据传递
@property (strong,nonatomic) AVCaptureDeviceInput *captureDeviceInput;//负责从AVCaptureDevice获得输入数据
@property (strong,nonatomic) AVCaptureMovieFileOutput *captureMovieFileOutput;//视频输出流
@property (strong,nonatomic) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;//相机拍摄预览图层


@property (assign,nonatomic) BOOL enableRotation;//是否允许旋转（注意在视频录制过程中禁止屏幕旋转）
@property (assign,nonatomic) CGRect *lastBounds;//旋转的前大小
@property (assign,nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;//后台任务标识


@property float totalTime; //视频总长度 默认10秒







@property (weak, nonatomic) IBOutlet UIView *viewContainer;


@property (weak, nonatomic) IBOutlet UIView *BottomView;


@property (weak, nonatomic) IBOutlet UIImageView *BackImage;


@property (weak, nonatomic) IBOutlet UIButton *takeButton;//录制按钮

@property (weak, nonatomic) IBOutlet UIButton *focusCursor;//聚焦光标

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *ConstantBtnLeft;


@property (weak, nonatomic) IBOutlet UIButton *flashBt;//闪光灯

@property (weak, nonatomic) IBOutlet UIButton *cameraBt;////切换摄像头


#pragma mark-各种点击事件
- (IBAction)popClick:(id)sender;//退出小视频事件


- (IBAction)toggleButtonClick:(id)sender;//切换摄像头


- (IBAction)flashOnClick:(id)sender;//闪光灯开关

- (IBAction)takeButtonClick:(id)sender;//录制事件


@end
