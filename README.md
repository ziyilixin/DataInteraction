# DataInteraction
原生(Objective-C)与H5页面的交互



##WKWebView注册方法

```objc
//注册一个调用相机的方法
[configuration.userContentController addScriptMessageHandler:self name:@"getImageByCamera"];
//注册一个调用位置的方法
[configuration.userContentController addScriptMessageHandler:self name:@"getLocation"];
//注册一个获取网络类型的方法
[configuration.userContentController addScriptMessageHandler:self name:@"getNetworkInfo"];
//注册一个关闭页面的方法
[configuration.userContentController addScriptMessageHandler:self name:@"closeWindow"];
```

```objc
#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    NSLog(@"------name:%@\\\\n body:%@\\\\n",message.name,message.body);
    
    if ([message.name isEqualToString:@"getImageByCamera"]) {//拍照
        HJBFunction *function = [HJBFunction sharedManager];
        [function useCameraWithViewController:self finish:^(UIImage *image) {
            if (image != nil) {
                //处理图片大小、尺寸
                UIImage *picImage = [UIImage imageWithData:[self compressImageWithImage:image aimHeigth:750 aimLength:280*1024 accuracyOfLength:1024]];

                NSMutableDictionary *result = [NSMutableDictionary dictionary];
                result[@"code"] = @"0";

                // 压缩一下图片再上传
                NSData *imgData = UIImageJPEGRepresentation(picImage, 0.8);
                NSString *encodedImageStr = [imgData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
                [self removeSpaceAndNewline:encodedImageStr];
                NSString *imageString = [self removeSpaceAndNewline:encodedImageStr];

                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                dict[@"image"] = [NSString stringWithFormat:@"data:image/jpeg;base64,%@",imageString];
                result[@"data"] = dict;

                NSString *imageStr = [self JSonDataWithDitionary:result];
                NSString *jsStr = [NSString stringWithFormat:@"%@('%@')",message.body[@"callback"],[self removeSpaceAndNewline:imageStr]];
                [self.webView evaluateJavaScript:jsStr completionHandler:^(id _Nullable result, NSError * _Nullable error) {
                    NSLog(@"result = %@,error = %@",result,error);
                }];
            }
        } failure:^(NSError *error) {

        }];
    }
    else if ([message.name isEqualToString:@"getLocation"]) {//定位
        HJBFunction *function = [HJBFunction  sharedManager];
        [function useLocationWithViewController:self finish:^(NSDictionary *result) {
            NSMutableDictionary *params = [NSMutableDictionary dictionary];
            params[@"code"] = @"0";
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            dict[@"longitude"] = result[@"longitude"];
            dict[@"latitude"] = result[@"latitude"];
            params[@"data"] = dict;
            NSString *addreessStr = [self JSonDataWithDitionary:params];
            NSString *jsStr = [NSString stringWithFormat:@"%@('%@')",message.body[@"callback"],[self removeSpaceAndNewline:addreessStr]];
            [self.webView evaluateJavaScript:jsStr completionHandler:^(id _Nullable result, NSError * _Nullable error) {
                NSLog(@"result = %@,error = %@",result,error);
            }];
        }];
    }
    else if ([message.name isEqualToString:@"getNetworkInfo"]) {//获取网络类型
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        if ([self.netWorkType isEqualToString:@"网络不可用"] || [self.netWorkType isEqualToString:@"未知网络"]) {
            params[@"code"] = @"5";
            dict[@"networkType"] = self.netWorkType;
        }
        else {
            params[@"code"] = @"0";
            dict[@"networkType"] = self.netWorkType;
        }
        params[@"data"] = dict;
        NSString *networkStr = [self  JSonDataWithDitionary:params];
        NSString *jsStr = [NSString stringWithFormat:@"%@('%@')",message.body[@"callback"],[self removeSpaceAndNewline:networkStr]];
        [self.webView evaluateJavaScript:jsStr completionHandler:^(id _Nullable result, NSError * _Nullable error) {
            NSLog(@"result = %@,error = %@",result,error);
        }];
    }
    else if ([message.name isEqualToString:@"closeWindow"]) {//关闭webView
        [self.navigationController popViewControllerAnimated:YES];
    }
}
```

##获取手机拍照、定位方法、获取网络类型

```objc
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
```

```objc
/**
 *  调用地图
 *  @param viewController 控制器
 *  @param finishBlock    完成回掉
 */
- (void)useLocationWithViewController:(UIViewController *)viewController finish:(void (^)(NSDictionary *result))finishBlock;
```

```objc
/**
* 获取网络类型
*/
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kNetWorkReachabilityChangedNotification object:nil];
    
    HLNetWorkReachability *reachability = [HLNetWorkReachability reachabilityWithHostName:@"www.baidu.com"];
    self.hostReachability = reachability;
    [reachability startNotifier];
    
    return YES;
}

- (void)reachabilityChanged:(NSNotification *)notification
{
    HLNetWorkReachability *curReach = [notification object];
    HLNetWorkStatus netStatus = [curReach currentReachabilityStatus];
    switch (netStatus) {
        case HLNetWorkStatusNotReachable:
            NSLog(@"网络不可用");
            break;
        case HLNetWorkStatusUnknown:
            NSLog(@"未知网络");
            break;
        case HLNetWorkStatusWWAN2G:
            NSLog(@"2G网络");
            break;
        case HLNetWorkStatusWWAN3G:
            NSLog(@"3G网络");
            break;
        case HLNetWorkStatusWWAN4G:
            NSLog(@"4G网络");
            break;
        case HLNetWorkStatusWiFi:
            NSLog(@"WiFi");
            break;
            
        default:
            break;
    }
}
```
