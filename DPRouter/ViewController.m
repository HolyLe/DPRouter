//
//  ViewController.m
//  DPRouter
//
//  Created by 麻小亮 on 2019/6/4.
//  Copyright © 2019 麻小亮. All rights reserved.
//

#import "ViewController.h"
#import "JumpCommon.h"
#import "ViewControllerA.h"
@interface DPRouteDataModel : NSObject
@property (nonatomic, copy) NSString * text;
@property (nonatomic, copy) NSString * classString;

@end

@implementation DPRouteDataModel
+ (DPRouteDataModel *)text:(NSString *)text classString:(NSString *)classString{
    DPRouteDataModel *model = [DPRouteDataModel new];
    model.text = text;
    model.classString = classString;
    return model;
}
@end

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (nonatomic, strong) UITableView * tableView;
@property (nonatomic, strong) NSMutableArray <DPRouteDataModel *>* dataSource;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Router功能";
    _dataSource = [NSMutableArray array];
    
    [_dataSource addObject:[DPRouteDataModel text:@"不同业务跳转" classString:@"JumpRoute"]];
    [_dataSource addObject:[DPRouteDataModel text:@"映射" classString:@"JumpMapping"]];
    [_dataSource addObject:[DPRouteDataModel text:@"预存处消息" classString:@"SaveDataPre"]];
    [_dataSource addObject:[DPRouteDataModel text:@"消息传递与接收" classString:@"Message"]];
    [self tableView];
    
    // Do any additional setup after loading the view.
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    CGPoint point = [[touches anyObject] locationInView:self.view];
    if (point.y> [UIScreen mainScreen].bounds.size.height/2) {
        [self presentViewController:[ViewControllerA new] animated:YES completion:nil];
    }else{
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - 代理 -

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = self.dataSource[indexPath.row].text;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    JumpCommon *common = [NSClassFromString(self.dataSource[indexPath.row].classString) new];
    [common jumpMethod];
}




//懒加载
- (UITableView *)tableView{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:[UIScreen mainScreen].bounds style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
        [self.view addSubview:_tableView];
    }
    return _tableView;
}




@end
