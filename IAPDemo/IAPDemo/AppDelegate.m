//
//  AppDelegate.m
//  IAPDemo
//
//  Created by SuperDanny on 2018/8/21.
//  Copyright © 2018年 MacauIT. All rights reserved.
//

#import "AppDelegate.h"
#import "IAPShare.h"

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
                NSLog(@"购买成功产品id：%@  订单号：%@", transcation.payment.productIdentifier, transcation.payment.applicationUsername);
                // 这个 receipt 就是内购成功 苹果返回的收据。appStoreReceiptURL是iOS7.0增加的，购买交易完成后，会将凭据存放在该地址
                NSData *receipt = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]];
                //将receipt base64加密，把加密的收据 和 产品id，一起发送到app服务器
                NSString *receiptBase64 = [receipt base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
//                [NSString base64StringFromData:receipt length:[receipt length]];
                //方式一：本地校验（不推荐，因为越狱机容易拦截验证，伪装成支付成功）
                [[IAPShare sharedHelper].iap checkReceipt:receipt AndSharedSecret:@"App 专用共享密钥" onCompletion:^(NSString *response, NSError *error) {
                    NSLog(@"%@==%@", response, error.localizedDescription);
                }];
                //方式二：服务器校验（将 receipt-data base64加密，然后和订单号一起传给服务器）
//                [weakSelf requestCheckReceiptWithBase64:receiptBase64 orderNO:transcation.payment.applicationUsername];
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

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
