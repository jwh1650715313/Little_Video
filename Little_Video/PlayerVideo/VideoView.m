//
//  VideoView.m
//  LittleVideo
//
//  Created by JIng on 2017/2/23.
//  Copyright © 2017年 JIng. All rights reserved.
//

#import "VideoView.h"

@implementation VideoView

- (id)initWithFrame:(CGRect)frame
           videoURL:( NSURL *)videoURL
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.videoURL=videoURL;
        
        [self CustomView];
        
     
        
        
        
    }
    
    return self;
}



-(void)CustomView
{
    AVAsset *movieAsset = [AVURLAsset URLAssetWithURL:self.videoURL options:nil];
    playerItem = [AVPlayerItem playerItemWithAsset:movieAsset];
    player = [AVPlayer playerWithPlayerItem:playerItem];
    playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    playerLayer.frame =self.layer.bounds;
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.layer addSublayer:playerLayer];
    [player play];
    
    
    
    //1.监听播放的状态
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playStateDidChange:) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
    
}

-(void)removeNotification{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)playStateDidChange:(NSNotification *)info//视频播放完成
{
    NSLog(@"视频播放完成");
    [player seekToTime:CMTimeMake(0, 1)];
    [player play];
    
}


#pragma mark-页面消失后关闭播放器
-(void)dealloc{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [player.currentItem cancelPendingSeeks];
    [player.currentItem.asset cancelLoading];
    [player pause];
    
    [playerLayer removeFromSuperlayer];
    [player replaceCurrentItemWithPlayerItem:nil];
    player = nil;
    
    
    playerLayer = nil;
    
    
}



@end
