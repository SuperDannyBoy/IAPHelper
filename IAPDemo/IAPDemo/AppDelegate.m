//
//  AppDelegate.m
//  IAPDemo
//
//  Created by SuperDanny on 2018/8/21.
//  Copyright © 2018年 MacauIT. All rights reserved.
//

#import "AppDelegate.h"
#import "IAPShare.h"
#import "NSString+Base64.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    //内购初始化
    [self iap];
    
    return YES;
}

- (void)iap {
    if (![IAPShare sharedHelper].iap) {
        typeof(self) __weak weakSelf = self;
        // 初始化内购产品
        NSSet *dataSet = [[NSSet alloc] initWithObjects:
                          @"产品id",
                          @"产品id",nil];
        [IAPShare sharedHelper].iap = [[IAPHelper alloc] initWithProductIdentifiers:dataSet onCompletion:^(SKPaymentTransaction *transcation) {
            if (transcation.error) {
            } else if (transcation.transactionState == SKPaymentTransactionStatePurchased) {
                NSDictionary *dic = [JNKeychain loadValueForKey:kIAPKeychain];
                NSString *transactionIdentifier = [self filterNULLValue:transcation.transactionIdentifier];
                NSString *tempOrderNo = dic[transactionIdentifier];
                
                NSLog(@"购买成功苹果交易id：%@  产品id：%@  订单号：%@", transcation.transactionIdentifier, transcation.payment.productIdentifier, tempOrderNo);
                
                if (tempOrderNo.length == 0) {
//                    [MBProgressHUD showError:@"支付异常，请稍等再试"];
                    [[[UIAlertView alloc] initWithTitle:@"支付异常，请稍等再试" message:nil delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
                    return;
                }
                
                //这个 receipt 就是内购成功 苹果返回的收据。appStoreReceiptURL是iOS7.0增加的，购买交易完成后，会将凭据存放在该地址
                NSData *receipt = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]];
                //将receipt base64加密，把加密的收据 和 产品id，一起发送到app服务器
                NSString *receiptBase64 = [NSString base64StringFromData:receipt length:[receipt length]];
                //方式一：本地校验（不推荐，因为越狱机容易拦截验证，伪装成支付成功）
//                [[IAPShare sharedHelper].iap checkReceipt:receipt AndSharedSecret:@"App 专用共享密钥" onCompletion:^(NSString *response, NSError *error) {
//                    NSLog(@"%@==%@", response, error.localizedDescription);
//                }];
                //方式二：服务器校验（推荐方式，将 receipt-data base64加密，然后和订单号一起传给服务器）
                [weakSelf requestCheckReceiptWithBase64:receiptBase64 orderNO:tempOrderNo transaction:transcation];
            } else if (transcation.transactionState == SKPaymentTransactionStateFailed) {
                if (transcation.error.code == SKErrorPaymentCancelled) {
                } else if (transcation.error.code == SKErrorClientInvalid) {
                } else if (transcation.error.code == SKErrorPaymentInvalid) {
                } else if (transcation.error.code == SKErrorPaymentNotAllowed) {
                } else if (transcation.error.code == SKErrorStoreProductNotAvailable) {
                } else {
                }
            }
        }];
    }
}

// 使用这句话的原因，是为了避免使用数据的时候出现空或者其他的，导致闪退
- (NSString *)filterNULLValue:(NSString *)string {
    
    NSString * newStr = [NSString stringWithFormat:@"%@",string];
    if ([newStr isKindOfClass:[NSNull class]] ||
        newStr == nil ||
        [newStr isEqualToString:@"(null)"]||
        [newStr isEqualToString:@""] ||
        [newStr isEqualToString:@"null"] ||
        [newStr isEqualToString:@"<null>"]) {
        newStr = @"";
    }
    return newStr;
}

#pragma mark - Request
#pragma mark 二次验证内购凭证
- (void)requestCheckReceiptWithBase64:(NSString *)receiptBase64 orderNO:(NSString *)orderNO transaction:(SKPaymentTransaction *)transaction {
    if (receiptBase64.length==0 || [self filterNULLValue:orderNO].length==0) {
        if ([SKPaymentQueue defaultQueue]) {
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        }
        return;
    }
//    NSDictionary *param = @{@"OrderNo" : [self filterNULLValue:orderNO],
//                            @"Data" : receiptBase64};
    //发送请求，不管请求之后验证成功还是失败，都需要结束交易队列
//    [OBRManager requestUrl:kOBRequestUrl methodName:@"PayMentManage_IOSExchange_InsertWithCard" paramter:param showHud:YES success:^(NSDictionary *dic) {
//        NSString *flag = [Tools filterNULLValue:dic[@"Flag"]];
//        if ([flag isEqualToString:@"1"]) {
//            //发起通知刷新
//            [weakSelf pushResultNotification:YES];
//        } else {
//            [weakSelf pushResultNotification:NO];
//            //            [MBProgressHUD showError:dic[@"Decription"]];
//        }
//        NSLog(@"验证完毕之后，结束交易队列");
//        if ([SKPaymentQueue defaultQueue]) {
//            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
//        }
//    } failed:^(NSError *error) {
//        [MBProgressHUD showError:error.localizedDescription];
//    }];
}

@end
