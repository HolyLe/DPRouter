//
//  ViewControllerA.m
//  DPRouter
//
//  Created by 麻小亮 on 2019/6/4.
//  Copyright © 2019 麻小亮. All rights reserved.
//

#import "ViewControllerA.h"

@interface ViewControllerA ()

@end

@implementation ViewControllerA

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:arc4random()%255/256.0 green:arc4random()%255/256.0 blue:arc4random()%255/256.0 alpha:1];
    // Do any additional setup after loading the view.
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    CGPoint point = [[touches anyObject] locationInView:self.view];
    if (point.y> [UIScreen mainScreen].bounds.size.height/2) {
        UINavigationController *na = [[UINavigationController alloc] initWithRootViewController:[UIViewController new]];
        [na pushViewController:[ViewControllerA new] animated:YES];
        [self presentViewController:na animated:YES completion:nil];
    }else{
        [arc4random()%2==0?self.navigationController:self dismissViewControllerAnimated:YES completion:nil];
    }
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
