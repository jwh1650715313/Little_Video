//
//  ViewController.m
//  Little_Video
//  GitHub地址:https://github.com/jwh1650715313/Little_Video
//  Created by JIng on 2017/2/24.
//  Copyright © 2017年 JIng. All rights reserved.
//

#import "ViewController.h"

#import "VideoShootViewController.h"

// 获取设备的物理高度
#define ScreenHeight ([UIScreen mainScreen].bounds.size.height)
// 获取设备的物理宽度
#define ScreenWidth ([UIScreen mainScreen].bounds.size.width)

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    _ViewTopConstant.constant=(ScreenHeight-30)/2;
    _ViewLeftConstant.constant=(ScreenWidth-70)/2;
    
    
    
    
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/** 小视频点击事件 */
- (IBAction)VideoClick:(id)sender {
    
    VideoShootViewController  *VideoShootVc=[[VideoShootViewController alloc]init];
    
    [self.navigationController pushViewController:VideoShootVc animated:YES];
    
}

@end
