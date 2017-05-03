//
//  VideoShootViewController.m
//  LittleVideo
//
//  Created by JIng on 2017/2/23.
//  Copyright © 2017年 JIng. All rights reserved.
//


// 获取设备的物理高度
#define ScreenHeight ([UIScreen mainScreen].bounds.size.height)
// 获取设备的物理宽度
#define ScreenWidth ([UIScreen mainScreen].bounds.size.width)

#define RedColor [UIColor redColor]

#import "VideoShootViewController.h"
#import "UIViewExt.h"
#import "PlayVideoViewController.h"
@interface VideoShootViewController ()

@end

@implementation VideoShootViewController
@synthesize totalTime;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    
    [self CustomView];
}




- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
    
    self.takeButton.userInteractionEnabled=YES;
    self.flashBt.hidden=NO;
    self.cameraBt.userInteractionEnabled=YES;
    self.takeButton.selected=NO;

}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self.captureSession startRunning];//这句代码很重要,负责输入和输出设置之间的数据传递
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}


-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self.captureSession stopRunning];
    
    //还原数据-----------
    [self deleteAllVideos];
    currentTime = 0;
    [progressPreView setFrame:CGRectMake(0, preLayerHeight, 0, 4)];
}


//屏幕旋转时调整视频预览图层的方向
-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    AVCaptureConnection *captureConnection=[self.captureVideoPreviewLayer connection];
    captureConnection.videoOrientation=(AVCaptureVideoOrientation)toInterfaceOrientation;
}
//旋转后重新设置大小
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
    _captureVideoPreviewLayer.frame=self.viewContainer.bounds;
}

-(void)dealloc{
    [self removeNotification];//移除通知
}



#pragma mark-初始化视图
-(void)CustomView
{
    
    
    [self createVideoFolderIfNotExist];//创建保存视频的文件夹

    //毛玻璃效果
    UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
    effectView.frame =_BackImage.frame;
    [_BackImage addSubview:effectView];
    
    
    //初始化会话
    _captureSession=[[AVCaptureSession alloc]init];
    if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset640x480]) {//设置分辨率
        _captureSession.sessionPreset=AVCaptureSessionPreset640x480;
    }
    //获得摄像头输入设备
    AVCaptureDevice *captureDevice=[self getCameraDeviceWithPosition:AVCaptureDevicePositionBack];//取得后置摄像头
    if (!captureDevice) {
        NSLog(@"取得后置摄像头时出现问题.");
        return;
    }
    
    NSError *error=nil;
    //根据输入设备初始化设备输入对象，用于获得输入数据
    _captureDeviceInput=[[AVCaptureDeviceInput alloc]initWithDevice:captureDevice error:&error];
    
    
    //添加一个音频输入设备
    AVCaptureDevice *audioCaptureDevice=[[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
    
    if (error) {
        NSLog(@"取得设备输入对象时出错，错误原因：%@",error.localizedDescription);
        return;
    }
    AVCaptureDeviceInput *audioCaptureDeviceInput=[[AVCaptureDeviceInput alloc]initWithDevice:audioCaptureDevice error:&error];
    if (error) {
        NSLog(@"取得设备输入对象时出错，错误原因：%@",error.localizedDescription);
        return;
    }
    //初始化设备输出对象，用于获得输出数据
    _captureMovieFileOutput=[[AVCaptureMovieFileOutput alloc]init];
    
    //将设备输入添加到会话中
    if ([_captureSession canAddInput:_captureDeviceInput]) {
        [_captureSession addInput:_captureDeviceInput];
        [_captureSession addInput:audioCaptureDeviceInput];
        AVCaptureConnection *captureConnection=[_captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        if ([captureConnection isVideoStabilizationSupported ]) {
            captureConnection.preferredVideoStabilizationMode=AVCaptureVideoStabilizationModeAuto;
        }
    }
    
    //将设备输出添加到会话中
    if ([_captureSession canAddOutput:_captureMovieFileOutput]) {
        [_captureSession addOutput:_captureMovieFileOutput];
    }
    
    //创建视频预览层，用于实时展示摄像头状态
    _captureVideoPreviewLayer=[[AVCaptureVideoPreviewLayer alloc]initWithSession:self.captureSession];
    
    CALayer *layer=self.viewContainer.layer;
    layer.masksToBounds=YES;
    
    _captureVideoPreviewLayer.frame=CGRectMake(0, 0, ScreenWidth, ScreenHeight);
    _captureVideoPreviewLayer.videoGravity=AVLayerVideoGravityResizeAspectFill;//填充模式
    //将视频预览层添加到界面中
    [layer insertSublayer:_captureVideoPreviewLayer below:self.TopView.layer];
    
    _enableRotation=YES;
    [self addNotificationToCaptureDevice:captureDevice];
    [self addGenstureRecognizer];//添加点按手势，点按时聚焦
    
    
    
    
    //进度条
    //视频最大时长 默认15秒
    
    self.totalTime =15;

    progressStep = ScreenWidth*TIMER_INTERVAL/self.totalTime;
    _ConstantBtnLeft.constant=(ScreenWidth-60)/2;
    preLayerWidth = ScreenWidth;
    preLayerHeight = ScreenHeight;
    preLayerHWRate =preLayerHeight/preLayerWidth;
    urlArray = [NSMutableArray array];
    
    preLayerHeight=0;
    progressPreView = [[UIView alloc]initWithFrame:CGRectMake(0, preLayerHeight, 1, 4)];
    progressPreView.backgroundColor = RedColor;
    [self.BottomView addSubview:progressPreView];
    
    
}


#pragma mark - 视频输出代理

//开始录制
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
     [self startTimer];
}

//视频录制完成
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    NSLog(@"视频录制完成.");
    
     self.takeButton.userInteractionEnabled=NO;
    
    [urlArray addObject:outputFileURL];
    //时间到了
    if (currentTime>=self.totalTime) {
        [self mergeAndExportVideosAtFileURLs:urlArray];
    }
}



#pragma mark-各种事件

//页面返回
- (IBAction)popClick:(id)sender {
    
      [self.navigationController popViewControllerAnimated:YES];
}

// 切换前后摄像头


- (IBAction)toggleButtonClick:(id)sender {
    
    AVCaptureDevice *currentDevice=[self.captureDeviceInput device];
    AVCaptureDevicePosition currentPosition=[currentDevice position];
    AVCaptureDevice *toChangeDevice;
    AVCaptureDevicePosition toChangePosition=AVCaptureDevicePositionFront;
    if (currentPosition==AVCaptureDevicePositionUnspecified||currentPosition==AVCaptureDevicePositionFront) {
        toChangePosition=AVCaptureDevicePositionBack;
        _flashBt.hidden = NO;
    }else{
        _flashBt.hidden = YES;
    }
    toChangeDevice=[self getCameraDeviceWithPosition:toChangePosition];
    //获得要调整的设备输入对象
    AVCaptureDeviceInput *toChangeDeviceInput=[[AVCaptureDeviceInput alloc]initWithDevice:toChangeDevice error:nil];
    
    //改变会话的配置前一定要先开启配置，配置完成后提交配置改变
    [self.captureSession beginConfiguration];
    //移除原有输入对象
    [self.captureSession removeInput:self.captureDeviceInput];
    //添加新的输入对象
    if ([self.captureSession canAddInput:toChangeDeviceInput]) {
        [self.captureSession addInput:toChangeDeviceInput];
        self.captureDeviceInput=toChangeDeviceInput;
    }
    //提交会话配置
    [self.captureSession commitConfiguration];
    
    //关闭闪光灯
    _flashBt.selected = NO;
    
    [self setTorchMode:AVCaptureTorchModeOff];
}

//闪光灯的开关

- (IBAction)flashOnClick:(id)sender {
    
    UIButton   *bt=(UIButton *)sender;
    
    if (bt.selected == YES) {
        bt.selected = NO;
        //关闭闪光灯
        [self setTorchMode:AVCaptureTorchModeOff];
    }else{
        bt.selected = YES;
        //开启闪光灯
        
        [self setTorchMode:AVCaptureTorchModeOn];
    }
    
}

//视频录制
- (IBAction)takeButtonClick:(id)sender {
    
    UIButton  *Btn=(UIButton *)sender;
    Btn.selected=!Btn.selected;
    //根据设备输出获得连接
    AVCaptureConnection *captureConnection=[self.captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    //根据连接取得设备输出的数据
    if (![self.captureMovieFileOutput isRecording]) {
        self.enableRotation=NO;
        self.cameraBt.userInteractionEnabled=NO;
        //如果支持多任务则则开始多任务
        if ([[UIDevice currentDevice] isMultitaskingSupported]) {
            self.backgroundTaskIdentifier=[[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
        }
        //预览图层和视频方向保持一致
        captureConnection.videoOrientation=[self.captureVideoPreviewLayer connection].videoOrientation;
        [self.captureMovieFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:[self getVideoSaveFilePathString]] recordingDelegate:self];
    }
    else{
        [self stopTimer];
        [self.captureMovieFileOutput stopRecording];//停止录制
       
    }
}






#pragma mark - 通知
/**
 *  给输入设备添加通知
 */
-(void)addNotificationToCaptureDevice:(AVCaptureDevice *)captureDevice{
    //注意添加区域改变捕获通知必须首先设置设备允许捕获
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        captureDevice.subjectAreaChangeMonitoringEnabled=YES;
    }];
    NSNotificationCenter *notificationCenter= [NSNotificationCenter defaultCenter];
    //捕获区域发生改变
    [notificationCenter addObserver:self selector:@selector(areaChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:captureDevice];
}
-(void)removeNotificationFromCaptureDevice:(AVCaptureDevice *)captureDevice{
    NSNotificationCenter *notificationCenter= [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:captureDevice];
}
/**
 *  移除所有通知
 */
-(void)removeNotification{
    NSNotificationCenter *notificationCenter= [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self];
}

-(void)addNotificationToCaptureSession:(AVCaptureSession *)captureSession{
    NSNotificationCenter *notificationCenter= [NSNotificationCenter defaultCenter];
    //会话出错
    [notificationCenter addObserver:self selector:@selector(sessionRuntimeError:) name:AVCaptureSessionRuntimeErrorNotification object:captureSession];
}

/**
 *  设备连接成功
 *
 *  @param notification 通知对象
 */
-(void)deviceConnected:(NSNotification *)notification{
    NSLog(@"设备已连接...");
}
/**
 *  设备连接断开
 *
 *  @param notification 通知对象
 */
-(void)deviceDisconnected:(NSNotification *)notification{
    NSLog(@"设备已断开.");
}
/**
 *  捕获区域改变
 *
 *  @param notification 通知对象
 */
-(void)areaChange:(NSNotification *)notification{
    NSLog(@"捕获区域改变...");
}

/**
 *  会话出错
 *
 *  @param notification 通知对象
 */
-(void)sessionRuntimeError:(NSNotification *)notification{
    NSLog(@"会话发生错误.");
}




#pragma mark - 私有方法

/**
 *  取得指定位置的摄像头
 *
 *  @param position 摄像头位置
 *
 *  @return 摄像头设备
 */
-(AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition )position{
    NSArray *cameras= [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras) {
        if ([camera position]==position) {
            return camera;
        }
    }
    return nil;
}

/**
 *  改变设备属性的统一操作方法
 *
 *  @param propertyChange 属性改变操作
 */
-(void)changeDeviceProperty:(PropertyChangeBlock)propertyChange{
    AVCaptureDevice *captureDevice= [self.captureDeviceInput device];
    NSError *error;
    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
    if ([captureDevice lockForConfiguration:&error]) {
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
    }else{
        NSLog(@"设置设备属性过程发生错误，错误信息：%@",error.localizedDescription);
    }
}


/**
 *  设置闪光灯模式
 *
 *  @param torchMode 闪光灯模式
 */
-(void)setTorchMode:(AVCaptureTorchMode )torchMode{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isTorchModeSupported:torchMode]) {
            [captureDevice setTorchMode:torchMode];
        }
    }];
}

/**
 *  设置聚焦模式
 *
 *  @param focusMode 聚焦模式
 */
-(void)setFocusMode:(AVCaptureFocusMode )focusMode{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isFocusModeSupported:focusMode]) {
            [captureDevice setFocusMode:focusMode];
        }
    }];
}
/**
 *  设置曝光模式
 *
 *  @param exposureMode 曝光模式
 */
-(void)setExposureMode:(AVCaptureExposureMode)exposureMode{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isExposureModeSupported:exposureMode]) {
            [captureDevice setExposureMode:exposureMode];
        }
    }];
}
/**
 *  设置聚焦点
 *
 *  @param point 聚焦点
 */
-(void)focusWithMode:(AVCaptureFocusMode)focusMode exposureMode:(AVCaptureExposureMode)exposureMode atPoint:(CGPoint)point{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isFocusModeSupported:focusMode]) {
            [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        if ([captureDevice isFocusPointOfInterestSupported]) {
            [captureDevice setFocusPointOfInterest:point];
        }
        if ([captureDevice isExposureModeSupported:exposureMode]) {
            [captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
        }
        if ([captureDevice isExposurePointOfInterestSupported]) {
            [captureDevice setExposurePointOfInterest:point];
        }
    }];
}

/**
 *  添加点按手势，点按时聚焦
 */
-(void)addGenstureRecognizer{
    UITapGestureRecognizer *tapGesture=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapScreen:)];
    [self.viewContainer addGestureRecognizer:tapGesture];
}
-(void)tapScreen:(UITapGestureRecognizer *)tapGesture{
    CGPoint point= [tapGesture locationInView:self.viewContainer];
    //将UI坐标转化为摄像头坐标
    CGPoint cameraPoint= [self.captureVideoPreviewLayer captureDevicePointOfInterestForPoint:point];
    [self setFocusCursorWithPoint:point];
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposureMode:AVCaptureExposureModeAutoExpose atPoint:cameraPoint];
}

/**
 *  设置聚焦光标位置
 *
 *  @param point 光标位置
 */
-(void)setFocusCursorWithPoint:(CGPoint)point{
    self.focusCursor.center=point;
    self.focusCursor.transform=CGAffineTransformMakeScale(1.5, 1.5);
    self.focusCursor.alpha=1.0;
    [UIView animateWithDuration:1.0 animations:^{
        self.focusCursor.transform=CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        self.focusCursor.alpha=0;
        
    }];
}

/**
 *  开始倒计时
 *
 *
 */
-(void)startTimer{
    
    
    countTimer = [NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
    [countTimer fire];
}


/**
 *  正在倒计时
 *
 *
 */
- (void)onTimer:(NSTimer *)timer
{
    currentTime += TIMER_INTERVAL;
    float progressWidth = progressPreView.width+progressStep;
    
    [progressPreView setFrame:CGRectMake(0, preLayerHeight, progressWidth, 4)];
   
    
    //时间到了停止录制视频
    if (currentTime>=self.totalTime) {
        [countTimer invalidate];
        countTimer = nil;
        [_captureMovieFileOutput stopRecording];
    }
    
}


/**
 *  结束倒计时
 *
 *
 */
-(void)stopTimer{
    
    [countTimer invalidate];
    countTimer = nil;
    
    [self finishBtTap];
    
}


/**
 *  结束状态
 *
 *
 */
-(void)finishBtTap{
    
    currentTime=totalTime;
    [countTimer invalidate];
    countTimer = nil;
    
    //正在拍摄
    if (_captureMovieFileOutput.isRecording) {
        [_captureMovieFileOutput stopRecording];
    }else{//已经暂停了
        [self mergeAndExportVideosAtFileURLs:urlArray];
    }
}



#pragma mark-视频保存
- (void)mergeAndExportVideosAtFileURLs:(NSMutableArray *)fileURLArray
{
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        
        CGSize renderSize = CGSizeMake(0, 0);
        
        NSMutableArray *layerInstructionArray = [[NSMutableArray alloc] init];
        
        AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
        
        CMTime totalDuration = kCMTimeZero;
        
        //先去assetTrack 也为了取renderSize
        NSMutableArray *assetTrackArray = [[NSMutableArray alloc] init];
        NSMutableArray *assetArray = [[NSMutableArray alloc] init];
        for (NSURL *fileURL in fileURLArray) {
            AVAsset *asset = [AVAsset assetWithURL:fileURL];
            
            if (!asset) {
                continue;
            }
            
            [assetArray addObject:asset];
            
            AVAssetTrack *assetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
            [assetTrackArray addObject:assetTrack];
            
            renderSize.width = MAX(renderSize.width, assetTrack.naturalSize.height);
            renderSize.height = MAX(renderSize.height, assetTrack.naturalSize.width);
        }
        
        CGFloat renderW = MIN(renderSize.width, renderSize.height);
        
        for (int i = 0; i < [assetArray count] && i < [assetTrackArray count]; i++) {
            
            AVAsset *asset = [assetArray objectAtIndex:i];
            AVAssetTrack *assetTrack = [assetTrackArray objectAtIndex:i];
            
            AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                                ofTrack:[[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0]
                                 atTime:totalDuration
                                  error:nil];
            
            AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
            
            [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                                ofTrack:assetTrack
                                 atTime:totalDuration
                                  error:&error];
            
            //fix orientationissue
            AVMutableVideoCompositionLayerInstruction *layerInstruciton = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
            
            totalDuration = CMTimeAdd(totalDuration, asset.duration);
            
            CGFloat rate;
            rate = renderW / MIN(assetTrack.naturalSize.width, assetTrack.naturalSize.height);
            
            CGAffineTransform layerTransform = CGAffineTransformMake(assetTrack.preferredTransform.a, assetTrack.preferredTransform.b, assetTrack.preferredTransform.c, assetTrack.preferredTransform.d, assetTrack.preferredTransform.tx * rate, assetTrack.preferredTransform.ty * rate);
            layerTransform = CGAffineTransformConcat(layerTransform, CGAffineTransformMake(1, 0, 0, 1, 0, -(assetTrack.naturalSize.width - assetTrack.naturalSize.height) /10.0));//向上移动取中部影响
            layerTransform = CGAffineTransformScale(layerTransform, rate, rate);//放缩，解决前后摄像结果大小不对称
            
            [layerInstruciton setTransform:layerTransform atTime:kCMTimeZero];
            [layerInstruciton setOpacity:0.0 atTime:totalDuration];
            
            //data
            [layerInstructionArray addObject:layerInstruciton];
        }
        
        //get save path
        NSURL *mergeFileURL = [NSURL fileURLWithPath:[self getVideoMergeFilePathString]];
        
        //export
        AVMutableVideoCompositionInstruction *mainInstruciton = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        mainInstruciton.timeRange = CMTimeRangeMake(kCMTimeZero, totalDuration);
        mainInstruciton.layerInstructions = layerInstructionArray;
        AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
        mainCompositionInst.instructions = @[mainInstruciton];
        mainCompositionInst.frameDuration = CMTimeMake(1, 30);
        mainCompositionInst.renderSize = CGSizeMake(renderW, renderW);
        
        AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetMediumQuality];
        exporter.videoComposition = mainCompositionInst;
        exporter.outputURL = mergeFileURL;
        exporter.outputFileType = AVFileTypeMPEG4;
        exporter.shouldOptimizeForNetworkUse = YES;
        [exporter exportAsynchronouslyWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                
                 PlayVideoViewController  *vc=[[PlayVideoViewController alloc]init];
                 vc.videoURL=mergeFileURL;
                 [self.navigationController pushViewController:vc animated:YES];
                
            });
        }];
    });
    
    
}


//最后合成为 mp4
- (NSString *)getVideoMergeFilePathString
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    
    path = [path stringByAppendingPathComponent:VIDEO_FOLDER];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMddHHmmss";
    NSString *nowTimeStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
    
    NSString *fileName = [[path stringByAppendingPathComponent:nowTimeStr] stringByAppendingString:@"merge.mp4"];
    
    return fileName;
}

//录制保存的时候要保存为 mov
- (NSString *)getVideoSaveFilePathString
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    
    path = [path stringByAppendingPathComponent:VIDEO_FOLDER];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMddHHmmss";
    NSString *nowTimeStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
    
    NSString *fileName = [[path stringByAppendingPathComponent:nowTimeStr] stringByAppendingString:@".mov"];
    
    return fileName;
}

#pragma mark-创建文件夹
- (void)createVideoFolderIfNotExist
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    
    NSString *folderPath = [path stringByAppendingPathComponent:VIDEO_FOLDER];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL isDirExist = [fileManager fileExistsAtPath:folderPath isDirectory:&isDir];
    
    if(!(isDirExist && isDir))
    {
        BOOL bCreateDir = [fileManager createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
        if(!bCreateDir){
            NSLog(@"创建保存视频文件夹失败");
        }
    }
}


- (void)deleteAllVideos
{
    for (NSURL *videoFileURL in urlArray) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *filePath = [[videoFileURL absoluteString] stringByReplacingOccurrencesOfString:@"file://" withString:@""];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if ([fileManager fileExistsAtPath:filePath]) {
                NSError *error = nil;
                [fileManager removeItemAtPath:filePath error:&error];
                
                if (error) {
                    NSLog(@"delete All Video 删除视频文件出错:%@", error);
                }
            }
        });
    }
    [urlArray removeAllObjects];
}



@end
