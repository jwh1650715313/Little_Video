//
//  ViewController.h
//  Little_Video
//
//  Created by JIng on 2017/2/24.
//  Copyright © 2017年 JIng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *ViewTopConstant;


@property (weak, nonatomic) IBOutlet NSLayoutConstraint *ViewLeftConstant;

- (IBAction)VideoClick:(id)sender;


@end

