//
//  HJBFunction.h
//  HJBBaseASC
//
//  Created by 小明 on 15/12/16.
//  Copyright © 2015年 hjb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (^ImageBlock)(UIImage *image);          /**返回图片*/
typedef void (^LocationBlock)(NSMutableDictionary *addDic); /**返回字典*/

@interface HJBFunction : NSObject
@property (copy, nonatomic) ImageBlock imageBlock;
@property (copy, nonatomic) LocationBlock locationBlock;

/**
 *  HJBFunction单例对象
 *
 *  @return HJBFunction单例
 */
+ (instancetype)sharedManager;

/**
 *  调用摄像头和相册的方法
 *
 *  @param viewController 当前控制器
 *  @param finishBlock    调用成功后回调
 *  @param failureBlock   调用失败后回调
 */
- (void)
useCameraAndGalleryWithViewController:(UIViewController *)viewController
finish:(void (^)(UIImage *image))finishBlock
failure:(void (^)(NSError *error))failureBlock;

/**
 *  调用摄像头的方法
 *
 *  @param viewController 当前控制器
 *  @param finishBlock    调用成功后回调
 *  @param failureBlock   调用失败后回调
 */
- (void)
useCameraWithViewController:(UIViewController *)viewController
finish:(void (^)(UIImage *image))finishBlock
failure:(void (^)(NSError *error))failureBlock;

/**
 *  调用地图
 *  @param viewController 控制器
 *  @param finishBlock    完成回掉
 */
- (void)useLocationWithViewController:(UIViewController *)viewController finish:(void (^)(NSDictionary *result))finishBlock;

@end
