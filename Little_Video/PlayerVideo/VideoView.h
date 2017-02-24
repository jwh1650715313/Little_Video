//
//  VideoView.h
//  LittleVideo
//
//  Created by JIng on 2017/2/23.
//  Copyright © 2017年 JIng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
@interface VideoView : UIView
{
    
    AVPlayer *player;
    AVPlayerItem *playerItem;
    AVPlayerLayer *playerLayer;
    
}

- (id)initWithFrame:(CGRect)frame
           videoURL:( NSURL *)videoURL;

@property(nonatomic,retain) NSURL * videoURL;


@end
