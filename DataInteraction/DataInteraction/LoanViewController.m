
#define kSCreenWidth [UIScreen mainScreen].bounds.size.width
#define kSCreenHeight [UIScreen mainScreen].bounds.size.height

#define HJBHeadViewBGColor UIColorFromRGB(0x66aafd)
#define HJBTableViewBGColor UIColorFromRGB(0xeff1f4)
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]


#import "LoanViewController.h"
#import <WebKit/WebKit.h>
#import <CoreLocation/CLLocationManager.h>
#import "HJBFunction.h"
#import "HLNetWorkReachability.h"

@interface LoanViewController ()<WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler>
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) NSString *netWorkType;
@end

@implementation LoanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //添加webView
    [self createWebView];
    
    //添加进度条
    [self createProgressView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kNetWorkReachabilityChangedNotification object:nil];
}

- (void)createWebView
{
    WKUserContentController *userVC = [[WKUserContentController alloc] init];
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.userContentController = userVC;
    
    //注册一个调用相机的方法
    [configuration.userContentController addScriptMessageHandler:self name:@"getImageByCamera"];
    //注册一个调用位置的方法
    [configuration.userContentController addScriptMessageHandler:self name:@"getLocation"];
    //注册一个获取网络类型的方法
    [configuration.userContentController addScriptMessageHandler:self name:@"getNetworkInfo"];
    //注册一个关闭页面的方法
    [configuration.userContentController addScriptMessageHandler:self name:@"closeWindow"];
    
    WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, kSCreenWidth, kSCreenHeight) configuration:configuration];
    webView.navigationDelegate = self;
    webView.UIDelegate = self;
    NSURL *url = [[NSURL alloc] initFileURLWithPath:self.urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [webView loadRequest:request];
    self.webView = webView;
    
    //修改UserAgent
    [self.webView evaluateJavaScript:@"navigator.userAgent" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        NSString *userAgent = result;
        NSString *newUserAgent = [userAgent stringByAppendingString:@" HJBAPP/4.0.13"];
        NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:newUserAgent,@"UserAgent",nil];
        [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self.webView setCustomUserAgent:newUserAgent];
    }];
    
    [self.view addSubview:self.webView];
}

- (void)createProgressView
{
    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.progressView.frame = CGRectMake(0, 65, kSCreenWidth, 1);
    self.progressView.progress = 0.1f;
    self.progressView.progressTintColor = HJBHeadViewBGColor;
    self.progressView.trackTintColor = HJBTableViewBGColor;
    [self.progressView setProgress:0.0 animated:YES];
    [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    [self.webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
    [self.webView addSubview:self.progressView];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        if (object == self.webView) {
            [self.progressView setAlpha:1.0f];
            [self.progressView setProgress:self.webView.estimatedProgress animated:YES];
            
            if (self.webView.estimatedProgress >= 1.0f) {
                [UIView animateWithDuration:0.3 delay:0.3 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    [self.progressView setAlpha:0.0f];
                } completion:^(BOOL finished) {
                    [self.progressView setProgress:0.0f animated:YES];
                }];
            }
        }
        else {
            [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        }
    }
    else if ([keyPath isEqualToString:@"title"]) {
        self.title = self.webView.title;
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
    decisionHandler(WKNavigationResponsePolicyAllow);
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation
{
    if ([CLLocationManager locationServicesEnabled] && ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined)) {
        
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
        [self presentViewController:alert animated:YES completion:nil];
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
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation
{
    
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation
{
    
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation
{
    
}

- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    
}

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView API_AVAILABLE(macosx(10.11), ios(9.0))
{
    
}

#pragma mark - WKUIDelegate

- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures
{
    return nil;
}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示"
                                                                             message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                          completionHandler();
                                                      }]];
    [self presentViewController:alertController animated:YES completion:^{}];
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示"
                                                                             message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                          completionHandler(YES);
                                                      }]];
    [self presentViewController:alertController animated:YES completion:^{}];
}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable result))completionHandler
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:prompt
                                                                             message:defaultText
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                          completionHandler(@"");
                                                      }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消"
                                                        style:UIAlertActionStyleCancel
                                                      handler:^(UIAlertAction *action){
                                                          completionHandler(@"");
                                                      }]];
    [self presentViewController:alertController animated:YES completion:^{}];
}

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
    else if ([message.name isEqualToString:@"getNetworkInfo"]) {
        
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
    else if ([message.name isEqualToString:@"closeWindow"]) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

//转换JsonString
- (NSString *)JSonDataWithDitionary:(NSDictionary *)jsonString
{
    NSString * string = @"{}";
    if (jsonString) {
        NSError * error;
        NSData * jsonData = [NSJSONSerialization dataWithJSONObject:jsonString options:NSJSONWritingPrettyPrinted error:&error];
        //change
        if (!jsonData) {
            NSLog(@"Got an error: %@", error);
        } else {
            string = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
    }
    return string;
}

/**
 *  压缩图片质量，返回值为可直接转化成UIImage对象的NSData对象
 *  aimLength: 目标大小，单位：字节（b）
 *  accuracyOfLength: 压缩控制误差范围(+ / -)，本方法虽然给出了误差范围，但实际上很难确定一张图片是否能压缩到误差范围内，无法实现精确压缩。
 */
- (NSData *)compressImageWithImage:(UIImage *)image aimHeigth:(CGFloat)height aimLength:(NSInteger)length accuracyOfLength:(NSInteger)accuracy{
    UIImage * newImage = [self imageWithImage:image scaledToSize:CGSizeMake(height *image.size.width / image.size.height, height)];
    NSData  *data = UIImageJPEGRepresentation(newImage, 1);
    NSInteger imageDataLen = [data length];
    
    if (imageDataLen <= length + accuracy) {
        return data;
    }
    else{
        NSData * imageData = UIImageJPEGRepresentation( newImage, 0.99);
        if (imageData.length < length + accuracy) {
            return imageData;
        }
        
        CGFloat maxQuality = 1.0;
        CGFloat minQuality = 0.0;
        int flag = 0;
        
        while (1) {
            CGFloat midQuality = (maxQuality + minQuality)/2;
            if (flag == 6) {
                NSLog(@"************* %ld ******** %f *************",UIImageJPEGRepresentation(newImage, minQuality).length,minQuality);
                return UIImageJPEGRepresentation(newImage, minQuality);
            }
            flag ++;
            
            NSData * imageData = UIImageJPEGRepresentation(newImage, midQuality);
            NSInteger len = imageData.length;
            
            if (len > length+accuracy) {
                NSLog(@"-----%d------%f------%ld-----",flag,midQuality,len);
                maxQuality = midQuality;
                continue;
            }
            else if (len < length-accuracy){
                NSLog(@"-----%d------%f------%ld-----",flag,midQuality,len);
                minQuality = midQuality;
                continue;
            }
            else {
                NSLog(@"-----%d------%f------%ld--end",flag,midQuality,len);
                return imageData;
                break;
            }
        }
    }
}

//对图片尺寸进行压缩--
- (UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize
{
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (void)reachabilityChanged:(NSNotification *)notification
{
    HLNetWorkReachability *curReach = [notification object];
    HLNetWorkStatus netStatus = [curReach currentReachabilityStatus];
    switch (netStatus) {
        case HLNetWorkStatusNotReachable:
            self.netWorkType = @"网络不可用";
            break;
        case HLNetWorkStatusUnknown:
            self.netWorkType = @"未知网络";
            break;
        case HLNetWorkStatusWWAN2G:
            self.netWorkType = @"GPRS";
            break;
        case HLNetWorkStatusWWAN3G:
            self.netWorkType = @"3G";
            break;
        case HLNetWorkStatusWWAN4G:
            self.netWorkType = @"4G";
            break;
        case HLNetWorkStatusWiFi:
            self.netWorkType = @"WIFI";
            break;
        default:
            break;
    }
}

- (NSString *)removeSpaceAndNewline:(NSString *)str
{
    NSString *temp = [str stringByReplacingOccurrencesOfString:@" " withString:@""];
    temp = [temp stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    temp = [temp stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    return temp;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNetWorkReachabilityChangedNotification object:nil];
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
    [self.webView removeObserver:self forKeyPath:@"title"];
    
    [self.webView.configuration.userContentController removeScriptMessageHandlerForName:@"getImageByCamera"];
    [self.webView.configuration.userContentController removeScriptMessageHandlerForName:@"getLocation"];
    [self.webView.configuration.userContentController removeScriptMessageHandlerForName:@"getNetworkInfo"];
    [self.webView.configuration.userContentController removeScriptMessageHandlerForName:@"closeWindow"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    self.webView = nil;
}

@end
