//
//  PlayVideoViewController.m
//  LittleVideo
//
//  Created by JIng on 2017/2/23.
//  Copyright © 2017年 JIng. All rights reserved.
//

#import "PlayVideoViewController.h"

// 获取设备的物理高度
#define ScreenHeight ([UIScreen mainScreen].bounds.size.height)
// 获取设备的物理宽度
#define ScreenWidth ([UIScreen mainScreen].bounds.size.width)



@interface PlayVideoViewController ()

@end

@implementation PlayVideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.title=@"小视频";
    
    
    VideoView *AvPlay=[[VideoView alloc]initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight*0.6) videoURL:self.videoURL];
    
    [self.view addSubview:AvPlay];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
