//
//  TBTestIAPViewController.m
//  Toubao
//
//  Created by SuperDanny on 2018/8/17.
//  Copyright © 2018年 betsystem. All rights reserved.
//

#import "TBTestIAPViewController.h"

@interface TBTestIAPViewController ()

@property (nonatomic, strong) UIButton *payBtn;

@end

@implementation TBTestIAPViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor cyanColor];
    
    NSArray *arr = @[@"购买套餐一",
                     @"购买套餐二",
                     @"购买套餐三",
                     @"购买套餐四",
                     @"购买套餐五"];
    for (NSUInteger i=0; i<5; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.tag = i;
        btn.frame = CGRectMake(0, i*(50+20), 200, 50);
//        btn.center = CGPointMake([UIScreen mainScreen].bounds.size.width/2, [UIScreen mainScreen].bounds.size.height/2);
        [btn setTitle:arr[i] forState:UIControlStateNormal];
        [btn setTintColor:[UIColor blackColor]];
        btn.layer.masksToBounds = YES;
        btn.layer.cornerRadius = 5;
        btn.layer.borderWidth = 1;
        btn.layer.borderColor = [UIColor blackColor].CGColor;
        [self.view addSubview:btn];
        [btn addTarget:self action:@selector(payClick:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)payClick:(UIButton *)btn {
    NSArray *arr = @[@"com.zhongao.HaoLuTui01",
                     @"com.zhongao.HaoLuTui02",
                     @"com.zhongao.HaoLuTui03",
                     @"com.zhongao.HaoLuTui04",
                     @"com.zhongao.HaoLuTui05"];
    if (btn.tag<5) {
        [self payClickProductWithId:arr[btn.tag]];
    }
}

- (void)payClickProductWithId:(NSString *)productId {
    if (productId.length == 0) {
        [MBProgressHUD showTips:@"暂无可购买套餐"];
        return;
    }
    NSString *orderNO = @"NO20180820143836";
    
    // 请求商品信息
    [[IAPShare sharedHelper].iap requestProductsWithCompletion:^(SKProductsRequest *request, SKProductsResponse *response, NSError *error) {
         if(response.products.count > 0) {
             //遍历所有线上可内购产品，找到用户真正需要支付的商品
             SKProduct *buyProduct;
             for (SKProduct *product in response.products) {
                 if ([product.productIdentifier isEqualToString:productId]) {
                     buyProduct = product;
                 }
             }
             if (!buyProduct) {
                 [MBProgressHUD showTips:@"暂无可购买套餐"];
                 return;
             }
             [[IAPShare sharedHelper].iap buyProduct:buyProduct applicationUserName:orderNO];
         } else {
             //  ..未获取到商品
             NSLog(@"..未获取到商品");
             [MBProgressHUD showTips:@"暂无可购买套餐"];
         }
     }];
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
