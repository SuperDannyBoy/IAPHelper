//
//  IAPHelper.h
//
//  Original Created by Ray Wenderlich on 2/28/11.
//  Created by saturngod on 7/9/12.
//  Copyright 2011 Ray Wenderlich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StoreKit/StoreKit.h"


typedef void (^IAPProductsResponseBlock)(SKProductsRequest* request , SKProductsResponse* response, NSError *error);

typedef void (^IAPBuyProductCompleteResponseBlock)(SKPaymentTransaction* transcation);

typedef void (^checkReceiptCompleteResponseBlock)(NSString* response,NSError* error);

typedef void (^resoreProductsCompleteResponseBlock) (SKPaymentQueue* payment,NSError* error);

@interface IAPHelper : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>

@property (nonatomic,strong) NSSet *productIdentifiers;
@property (nonatomic,strong) NSArray * products;
@property (nonatomic,strong) NSMutableSet *purchasedProducts;
@property (nonatomic,strong) SKProductsRequest *request;
///是否是生产环境，如果校验步骤在服务器时，可不用设置改属性
@property (nonatomic) BOOL production;

///init With Product Identifiers And Completion block
- (instancetype)initWithProductIdentifiers:(NSSet *)productIdentifiers onCompletion:(IAPBuyProductCompleteResponseBlock)completion;

///get Products List
- (void)requestProductsWithCompletion:(IAPProductsResponseBlock)completion;

///Buy Product
- (void)buyProduct:(SKProduct *)productIdentifier;
- (void)buyProduct:(SKProduct *)productIdentifier applicationUserName:(NSString *)userName;

///restore Products
- (void)restoreProductsWithCompletion:(resoreProductsCompleteResponseBlock)completion;

///check isPurchased or not
- (BOOL)isPurchasedProductsIdentifier:(NSString*)productID;

///check receipt but recommend to use in server side instead of using this function
- (void)checkReceipt:(NSData*)receiptData onCompletion:(checkReceiptCompleteResponseBlock)completion;

- (void)checkReceipt:(NSData*)receiptData AndSharedSecret:(NSString*)secretKey onCompletion:(checkReceiptCompleteResponseBlock)completion;


///saved purchased product
- (void)provideContentWithTransaction:(SKPaymentTransaction *)transaction;

- (void)provideContent:(NSString *)productIdentifier __deprecated_msg("use provideContentWithTransaction: instead.");

///clear the saved products
- (void)clearSavedPurchasedProducts;
- (void)clearSavedPurchasedProductByID:(NSString*)productIdentifier;


///Get The Price with local currency
- (NSString *)getLocalePrice:(SKProduct *)product;

@end
