//
//  HJBFunction.m
//  HJBBaseASC
//
//  Created by 小明 on 15/12/16.
//  Copyright © 2015年 hjb. All rights reserved.
//

//初始化捕捉设备（AVCaptureDevice），类型为AVMediaTypeVideo
#define Kdevice [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo]
//用captureDevice创建输入流
#define Kinput [AVCaptureDeviceInput deviceInputWithDevice:Kdevice error:&error]

#import "HJBFunction.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreLocation/CoreLocation.h>

@interface HJBFunction ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate, CLLocationManagerDelegate>
{
    CLGeocoder *_geocoder;               /**地理位置反编码*/
    CLLocationManager *_locationManager; /**定位启动对象*/
    CLLocationCoordinate2D _coordinate;
}
@property(strong, nonatomic) UIImagePickerController *pickerVC; /**相册，相机对象*/
@end

@implementation HJBFunction

static id instance;
+ (instancetype)sharedManager {
    //实例只被创建一次
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];  //调用alloc
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
}

//[HMPerson alloc] 底层就是调用下面的方法来分配内存空间
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [super allocWithZone:zone];
    });
    return instance;
}

- (id)copyWithZone:(struct _NSZone *)zone {
    return instance;
}

#pragma mark - 调用摄像头和相册
- (void)
useCameraAndGalleryWithViewController:(UIViewController *)viewController
finish:(void (^)(UIImage *image))finishBlock
failure:(void (^)(NSError *error))failureBlock {
    //弹出选择视图
    UIAlertController *alertVC = [UIAlertController
                                  alertControllerWithTitle:@"请选择"
                                  message:@""
                                  preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *action1 = [UIAlertAction
                              actionWithTitle:@"相册"
                              style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction *_Nonnull action) {
                                  //选择事件
                                  //实例调用相册的方法
                                  [self useGalleryWithViewController:viewController];
                                  //返回结果，并判断
                                  self.imageBlock = ^(UIImage *image) {
                                      
                                      if (image != nil) {
                                          finishBlock(image);
                                      } else {
                                          //错误信息
                                          NSError *error =
                                          [NSError errorWithDomain:@"选取图片失败"
                                                              code:100
                                                          userInfo:@{
                                                                     @"key" : @"未选中照片"
                                                                     }];
                                          
                                          failureBlock(error);
                                      }
                                      
                                  };
                                  
                              }];
    
    UIAlertAction *action2 = [UIAlertAction
                              actionWithTitle:@"拍照"
                              style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction *_Nonnull action) {
                                  //调用相机
                                  [self useCameraWithViewController:viewController];
                                  //返回结果，并判断
                                  self.imageBlock = ^(UIImage *image) {
                                      if (image != nil) {
                                          finishBlock(image);
                                      } else {
                                          //错误信息
                                          NSError *error =
                                          [NSError errorWithDomain:@"选取图片失败"
                                                              code:100
                                                          userInfo:@{
                                                                     @"key" : @"未选中照片"
                                                                     }];
                                          
                                          failureBlock(error);
                                      }
                                      
                                  };
                                  
                              }];
    UIAlertAction *action3 =
    [UIAlertAction actionWithTitle:@"取消"
                             style:UIAlertActionStyleCancel
                           handler:^(UIAlertAction *_Nonnull action){
                               
                           }];
    
    [alertVC addAction:action1];
    [alertVC addAction:action2];
    [alertVC addAction:action3];
    
    [viewController presentViewController:alertVC animated:YES completion:nil];
}

- (void)
useCameraWithViewController:(UIViewController *)viewController
finish:(void (^)(UIImage *image))finishBlock
failure:(void (^)(NSError *error))failureBlock
{
    //    //弹出选择视图
    //    UIAlertController *alertVC = [UIAlertController
    //                                  alertControllerWithTitle:@"上传图片"
    //                                  message:@""
    //                                  preferredStyle:UIAlertControllerStyleActionSheet];
    //
    //    UIAlertAction *action = [UIAlertAction
    //                              actionWithTitle:@"拍照"
    //                              style:UIAlertActionStyleDefault
    //                              handler:^(UIAlertAction *_Nonnull action) {
    //调用相机
    [self useCameraWithViewController:viewController];
    //返回结果，并判断
    self.imageBlock = ^(UIImage *image) {
        if (image != nil) {
            finishBlock(image);
        } else {
            //错误信息
            NSError *error =
            [NSError errorWithDomain:@"选取图片失败"
                                code:100
                            userInfo:@{
                                       @"key" : @"未选中照片"
                                       }];
            
            failureBlock(error);
        }
        
    };
    //
    //                              }];
    //    UIAlertAction *action2 =
    //    [UIAlertAction actionWithTitle:@"取消"
    //                             style:UIAlertActionStyleCancel
    //                           handler:^(UIAlertAction *_Nonnull action){
    //
    //                           }];
    //
    //    [alertVC addAction:action];
    //    [alertVC addAction:action2];
    //
    //    [viewController presentViewController:alertVC animated:YES completion:nil];
}

#pragma mark 调用相册的方法
- (void)useGalleryWithViewController:(UIViewController *)viewController {
    // 1.创建相册控制器
    if (_pickerVC == nil) {
        _pickerVC = [[UIImagePickerController alloc] init];
    }
    _pickerVC.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    // 设置媒体类型
    _pickerVC.mediaTypes = @[ @"public.movie", @"public.image" ];
    _pickerVC.delegate = self;
    
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    
    NSArray * subViews = [window subviews];
    
    for (UIView *view in subViews) {
        if ([view isKindOfClass:[UIImageView class]]) {
            UIImageView *imageView = (UIImageView *)view;
            imageView.image = nil;
        }
    }
    // 通过模态视图弹出相册（绝对不能使用导航控制器push）
    [viewController presentViewController:_pickerVC animated:YES completion:nil];
}
#pragma mark 调用相机的方法
- (void)useCameraWithViewController:(UIViewController *)viewController {
    if ([UIImagePickerController
         isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear] ||
        [UIImagePickerController
         isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]) {
            // 当前设备有摄像头
            // 1.创建相册控制器
            NSError *error;
            if (Kinput != nil) {
                if (_pickerVC == nil) {
                    _pickerVC = [[UIImagePickerController alloc] init];
                }
                _pickerVC.sourceType = UIImagePickerControllerSourceTypeCamera;
                // 设置媒体类型
                //      _pickerVC.mediaTypes = @[ @"public.movie", @"public.image" ];
                _pickerVC.mediaTypes = @[@"public.image" ];
                
                _pickerVC.delegate = self;
                // 通过模态视图弹出相册（绝对不能使用导航控制器push）
                
                [viewController presentViewController:_pickerVC
                                             animated:YES
                                           completion:nil];
                
            }
            else {
                UIAlertController *alert = [UIAlertController
                                            alertControllerWithTitle:@"提示"
                                            message:@"请在iPhone的\"设置-隐私-"
                                            @"相机\"选项中,"
                                            @"允许本程序访问您的相机"
                                            preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction
                                  actionWithTitle:@"确定"
                                  style:UIAlertActionStyleDestructive
                                  handler:^(UIAlertAction *_Nonnull action) {
                                      if ([[UIApplication sharedApplication]
                                           canOpenURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]]) {
                                          [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                                      } else {
                                          NSLog(@"error");
                                      }
                                  }]];
                [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                                          style:UIAlertActionStyleCancel
                                                        handler:nil]];
                
                [viewController presentViewController:alert animated:YES completion:nil];
            }
            
        }
    else {
        [self alertViewWithTitle:@"提示"
                         message:@"此设备没有摄像头"
                     buttonTitle:@"确定"];
    }
}

#pragma mark -UIImagePickerControllerDelegate
// 选择照片调用的协议方法
- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info {
    // 获取点击的图片
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    //保存图片到相册
    if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
        if (image != nil) {
            UIImageWriteToSavedPhotosAlbum(image, self, nil, nil);
        }
    }
    
    _imageBlock(image);
    // 关闭当前相册
    [picker dismissViewControllerAnimated:YES completion:nil];
}
// 点击取消按钮调用的协议方法()
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 提示视图（实例方法）
- (void)alertViewWithTitle:(NSString *)title
                   message:(NSString *)message
               buttonTitle:(NSString *)buttonTitle {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:nil
                                          otherButtonTitles:buttonTitle, nil];
    
    [alert show];
}

#pragma mark - 获取用户地理位置
- (void)useLocationWithViewController:(UIViewController *)viewController finish:(void (^)(NSDictionary *result))finishBlock {
    
    if ([CLLocationManager locationServicesEnabled] && ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined)) {
        
        if (_geocoder == nil) {
            _geocoder = [[CLGeocoder alloc] init];
        }
        // 2.开启定位服务
        
        if (_locationManager == nil) {
            _locationManager = [[CLLocationManager alloc] init];
        }
        // 设置代理对象
        _locationManager.delegate = self;
        // 配置精确度
        [_locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
        // iOS8.0需要如需服务
        if ([_locationManager
             respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [_locationManager requestAlwaysAuthorization];
        }
        CLLocationDistance distance = 10.0;  //十米定位一次
        
        _locationManager.distanceFilter = distance;
        // 开启定位
        [_locationManager startUpdatingLocation];
        
        self.locationBlock = ^(NSDictionary *addDic) {
            finishBlock(addDic);
        };
    }
    else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied){//用户拒绝该应用使用定位服务，或是定位服务总开关处于关闭状态
        UIAlertController *alert = [UIAlertController
                                    alertControllerWithTitle:@"提示"
                                    message:@"请在iPhone的\"设置-隐私-"
                                    @"定位服务\"选项中,"
                                    @"允许本程序访问您的位置"
                                    preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction
                          actionWithTitle:@"确定"
                          style:UIAlertActionStyleDestructive
                          handler:^(UIAlertAction *_Nonnull action) {
                              
                              if ([[UIApplication sharedApplication]
                                   canOpenURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]]) {
                                  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                              } else {
                                  NSLog(@"error");
                              }
                          }]];
                    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
                    }]];
        [viewController presentViewController:alert animated:YES completion:nil];
    }
    else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted){//无法使用定位服务，该状态用户无法改变
        UIAlertController *alert = [UIAlertController
                                    alertControllerWithTitle:@"提示"
                                    message:@"该设备无法使用定位服务"
                                    preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction
                          actionWithTitle:@"确定"
                          style:UIAlertActionStyleDestructive
                          handler:^(UIAlertAction *_Nonnull action) {
                              
                          }]];
        [viewController presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations {
    // 1.停止定位
    [_locationManager stopUpdatingLocation];
    
    // 2.获取位置对象
    CLLocation *location = [locations lastObject];
    _coordinate = location.coordinate;
    NSMutableDictionary *addDic = [NSMutableDictionary dictionary];
    addDic[@"longitude"] = [NSString stringWithFormat:@"%f",_coordinate.longitude];
    addDic[@"latitude"] = [NSString stringWithFormat:@"%f",_coordinate.latitude];
    self.locationBlock(addDic);
    //  [self getAddressByLatitude:_coordinate.latitude
    //                   longitude:_coordinate.longitude];
}

//#pragma mark 根据坐标取得地名
//- (void)getAddressByLatitude:(CLLocationDegrees)latitude
//                   longitude:(CLLocationDegrees)longitude {
//  //反地理编码
//  CLLocation *location =
//      [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
//  [_geocoder reverseGeocodeLocation:location
//                  completionHandler:^(NSArray *placemarks, NSError *error) {
//                    CLPlacemark *placemark = [placemarks firstObject];
//
//                    self.locationBlock(placemark.addressDictionary);
//
//                  }];
//}

@end
