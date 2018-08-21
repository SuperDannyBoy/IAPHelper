//
//  IAPHelper.m
//
//  Original Created by Ray Wenderlich on 2/28/11.
//  Created by saturngod on 7/9/12.
//  Copyright 2011 Ray Wenderlich. All rights reserved.
//

#import "IAPHelper.h"
#import "NSString+Base64.h"
#import "SFHFKeychainUtils.h"

#if ! __has_feature(objc_arc)
#error You need to either convert your project to ARC or add the -fobjc-arc compiler flag to IAPHelper.m.
#endif


@interface IAPHelper()

@property (nonatomic,copy) IAPBuyProductCompleteResponseBlock buyProductCompleteBlock;
@property (nonatomic,copy) IAPProductsResponseBlock requestProductsBlock;
@property (nonatomic,copy) resoreProductsCompleteResponseBlock restoreCompletedBlock;
@property (nonatomic,copy) checkReceiptCompleteResponseBlock checkReceiptCompleteBlock;

@property (nonatomic,strong) NSMutableData* receiptRequestData;

@end

@implementation IAPHelper

- (void)dealloc {
    if ([SKPaymentQueue defaultQueue]) {
        [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
    }
}

- (instancetype)initWithProductIdentifiers:(NSSet *)productIdentifiers onCompletion:(IAPBuyProductCompleteResponseBlock)completion {
    if ((self = [super init])) {
        
        // Store product identifiers
        _productIdentifiers = productIdentifiers;
        
        self.buyProductCompleteBlock = completion;
        
        // Check for previously purchased products
        NSMutableSet * purchasedProducts = [NSMutableSet set];
        for (NSString * productIdentifier in _productIdentifiers) {
            
            BOOL productPurchased = NO;
            
            NSString* password = [SFHFKeychainUtils getPasswordForUsername:productIdentifier andServiceName:@"IAPHelper" error:nil];
            if ([password isEqualToString:@"YES"]) {
                productPurchased = YES;
            }
            
            if (productPurchased) {
                [purchasedProducts addObject:productIdentifier];  
            }
        }
        if ([SKPaymentQueue defaultQueue]) {
            [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
            self.purchasedProducts = purchasedProducts;
        }
    }
    return self;
}

- (BOOL)isPurchasedProductsIdentifier:(NSString*)productID {

    BOOL productPurchased = NO;
    
    NSString* password = [SFHFKeychainUtils getPasswordForUsername:productID andServiceName:@"IAPHelper" error:nil];
    if ([password isEqualToString:@"YES"]) {
        productPurchased = YES;
    }
    return productPurchased;
}

- (void)requestProductsWithCompletion:(IAPProductsResponseBlock)completion {
    self.request = [[SKProductsRequest alloc] initWithProductIdentifiers:_productIdentifiers];
    _request.delegate = self;
    self.requestProductsBlock = completion;
    
    [_request start];
}

- (void)restoreProductsWithCompletion:(resoreProductsCompleteResponseBlock)completion {
    self.restoreCompletedBlock = completion;
    if ([SKPaymentQueue defaultQueue]) {
        [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    } else {
        NSLog(@"Cannot get the default Queue");
    }
}

#pragma mark - handle
- (void)recordTransaction:(SKPaymentTransaction *)transaction {    
    // TODO: Record the transaction on the server side...    
}

- (void)provideContentWithTransaction:(SKPaymentTransaction *)transaction {
    
    NSString* productIdentifier = @"";
    
    if (transaction.originalTransaction) {
        productIdentifier = transaction.originalTransaction.payment.productIdentifier;
    } else {
        productIdentifier = transaction.payment.productIdentifier;
    }
    
    //check productIdentifier exist or not
    //it can be possible nil
    if (productIdentifier) {
        [SFHFKeychainUtils storeUsername:productIdentifier andPassword:@"YES" forServiceName:@"IAPHelper" updateExisting:YES error:nil];
        [_purchasedProducts addObject:productIdentifier];
    }
}

- (void)provideContent:(NSString *)productIdentifier {
    [SFHFKeychainUtils storeUsername:productIdentifier andPassword:@"YES" forServiceName:@"IAPHelper" updateExisting:YES error:nil];
    
    [_purchasedProducts addObject:productIdentifier];
}

- (void)clearSavedPurchasedProducts {
    for (NSString * productIdentifier in _productIdentifiers) {
        [self clearSavedPurchasedProductByID:productIdentifier];
    }
}
- (void)clearSavedPurchasedProductByID:(NSString*)productIdentifier {
    [SFHFKeychainUtils deleteItemForUsername:productIdentifier andServiceName:@"IAPHelper" error:nil];
    [_purchasedProducts removeObject:productIdentifier];
}

#pragma mark - 获取内购产品价格
- (NSString *)getLocalePrice:(SKProduct *)product {
    if (product) {
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        [formatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
        [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        [formatter setLocale:product.priceLocale];
        
        return [formatter stringFromNumber:product.price];
    }
    return @"";
}

#pragma mark 交易完成，进行后续处理
- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    NSLog(@"-----交易完成，进行后续处理--------");
    [self recordTransaction: transaction];
    
    if ([SKPaymentQueue defaultQueue]) {
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    }
    
    if (_buyProductCompleteBlock) {
        _buyProductCompleteBlock(transaction);
    }
}

#pragma mark 已经购买过该商品，进行后续处理
- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    NSLog(@"-----已经购买过该商品，进行后续处理--------");
    [self recordTransaction: transaction];
    [self provideContentWithTransaction:transaction];
    
    if ([SKPaymentQueue defaultQueue]) {
        [[SKPaymentQueue defaultQueue] finishTransaction: transaction];

        if (_buyProductCompleteBlock) {
            _buyProductCompleteBlock(transaction);
        }
    }
}

#pragma mark 交易失败，进行后续处理
- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    NSLog(@"-----交易失败，进行后续处理--------");
    if (transaction.error.code != SKErrorPaymentCancelled) {
        NSLog(@"Transaction error: %@ %ld", transaction.error.localizedDescription,(long)transaction.error.code);
    }

    if ([SKPaymentQueue defaultQueue]) {
        [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
        if (_buyProductCompleteBlock) {
            _buyProductCompleteBlock(transaction);
        }
    }
}

#pragma mark - 购买产品
- (void)buyProduct:(SKProduct *)productIdentifier applicationUserName:(NSString *)userName {
    self.restoreCompletedBlock = nil;
    SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:productIdentifier];
    payment.applicationUsername = userName;
    
    if ([SKPaymentQueue defaultQueue]) {
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
}

- (void)buyProduct:(SKProduct *)productIdentifier {
    [self buyProduct:productIdentifier applicationUserName:nil];
}

#pragma mark - SKProductsRequestDelegate
#pragma mark 收到的产品信息
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    NSLog(@"-----------收到产品反馈信息--------------");
    NSArray *myProduct = response.products;
    NSLog(@"产品Product ID:%@",response.invalidProductIdentifiers);
    NSLog(@"产品付费数量: %d", (int)[myProduct count]);
    // populate UI
//    for (SKProduct *product in myProduct) {
//        NSLog(@"product info");
//        NSLog(@"SKProduct 描述信息%@", [product description]);
//        NSLog(@"产品标题 %@" , product.localizedTitle);
//        NSLog(@"产品描述信息: %@" , product.localizedDescription);
//        NSLog(@"价格: %@" , product.price);
//        NSLog(@"Product id: %@" , product.productIdentifier);
//    }
    self.products = response.products;
    self.request = nil;
    
    if (_requestProductsBlock) {
        _requestProductsBlock (request,response, nil);
        _requestProductsBlock = nil;
    }
}

#pragma mark 弹出错误信息
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"-------弹出错误信息----------");
    self.requestProductsBlock(self.request, nil, error);
    self.requestProductsBlock = nil;
}

#pragma mark - SKPaymentTransactionObserver
#pragma mark 监听购买结果
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
            default:
                break;
        }
    }
}

#pragma mark 恢复交易失败，回调此方法
- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    NSLog(@"Transaction error: %@ %ld", error.localizedDescription,(long)error.code);
    if (_restoreCompletedBlock) {
        _restoreCompletedBlock(queue,error);
    }
}

#pragma mark 在支付队列处理完所有可恢复的交易后调用此方法
- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    for (SKPaymentTransaction *transaction in queue.transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStateRestored: {
                [self recordTransaction: transaction];
                [self provideContentWithTransaction:transaction];
            }
            default:
                break;
        }
    }
    
    if (_restoreCompletedBlock) {
        _restoreCompletedBlock(queue,nil);
    }
}

#pragma mark - 本地验证收据，建议在服务器端进行校验
- (void)checkReceipt:(NSData*)receiptData onCompletion:(checkReceiptCompleteResponseBlock)completion {
    [self checkReceipt:receiptData AndSharedSecret:nil onCompletion:completion];
}

- (void)checkReceipt:(NSData*)receiptData AndSharedSecret:(NSString*)secretKey onCompletion:(checkReceiptCompleteResponseBlock)completion {
    
    self.checkReceiptCompleteBlock = completion;

    NSError *jsonError = nil;
    NSString *receiptBase64 = [NSString base64StringFromData:receiptData length:[receiptData length]];


    NSData *jsonData = nil;

    if (secretKey !=nil && ![secretKey isEqualToString:@""]) {
        
        jsonData = [NSJSONSerialization dataWithJSONObject:@{@"receipt-data": receiptBase64,
                                                             @"password": secretKey}
                                                   options:NSJSONWritingPrettyPrinted
                                                     error:&jsonError];
        
    } else {
        jsonData = [NSJSONSerialization dataWithJSONObject:@{@"receipt-data": receiptBase64}
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&jsonError
                        ];
    }


//    NSString* jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    NSURL *requestURL = nil;
    if (_production) {
        requestURL = [NSURL URLWithString:@"https://buy.itunes.apple.com/verifyReceipt"];
    } else {
        requestURL = [NSURL URLWithString:@"https://sandbox.itunes.apple.com/verifyReceipt"];
    }

    NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:requestURL];
    [req setHTTPMethod:@"POST"];
    [req setHTTPBody:jsonData];

    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    if (conn) {
        self.receiptRequestData = [[NSMutableData alloc] init];
    } else {
        NSError* error = nil;
        NSMutableDictionary* errorDetail = [[NSMutableDictionary alloc] init];
        [errorDetail setValue:@"Can't create connection" forKey:NSLocalizedDescriptionKey];
        error = [NSError errorWithDomain:@"IAPHelperError" code:100 userInfo:errorDetail];
        if (_checkReceiptCompleteBlock) {
            _checkReceiptCompleteBlock(nil,error);
        }
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"Cannot transmit receipt data. %@",[error localizedDescription]);
    
    if (_checkReceiptCompleteBlock) {
        _checkReceiptCompleteBlock(nil,error);
    }
    
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self.receiptRequestData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.receiptRequestData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSString *response = [[NSString alloc] initWithData:self.receiptRequestData encoding:NSUTF8StringEncoding];
    
    if (_checkReceiptCompleteBlock) {
        _checkReceiptCompleteBlock(response,nil);
    }
}

@end
