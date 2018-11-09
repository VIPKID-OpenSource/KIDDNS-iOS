# KIDDNS

[![CI Status](https://img.shields.io/travis/yiyangest/KIDDNS.svg?style=flat)](https://travis-ci.org/yiyangest/KIDDNS)
[![Version](https://img.shields.io/cocoapods/v/KIDDNS.svg?style=flat)](https://cocoapods.org/pods/KIDDNS)
[![License](https://img.shields.io/cocoapods/l/KIDDNS.svg?style=flat)](https://cocoapods.org/pods/KIDDNS)
[![Platform](https://img.shields.io/cocoapods/p/KIDDNS.svg?style=flat)](https://cocoapods.org/pods/KIDDNS)

KIDDNS是一个基于`NSURLProtocol`的HTTPDNS库，底层依托于阿里云的HTTPDNS服务，能够有效的避免DNS污染等问题，加速app中的网络请求。能够覆盖常见的HTTP及HTTPS场景，并且也兼容了HTTPS中的SNI场景。由于采用了`NSURLProtocol`，能够做到对业务方近乎无感的接入，只需简单配置，即可开始享受HTTPDNS的加速。

有关底层阿里云的HTTPDNS服务的使用及原理请参考[阿里云官方文档](https://help.aliyun.com/document_detail/30141.html?spm=a2c4g.11186623.6.580.25367797Vze70z)。

## 安装

KIDDNS is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'KIDDNS'
```

Podfile中需要添加VIPKID的Spec源，以及阿里云的Spec源

```ruby
source "https://github.com/VIPKID-OpenSource/Specs"
source "https://github.com/aliyun/aliyun-specs"
```

## 前提条件

需要拥有阿里云账号，并创建了开通HTTPDNS服务的应用。且阿里云控制台中配置好了app里需要开通HTTPDNS服务的域名。

## 使用方法

通过`CocoaPods`将`KIDDNS`库集成到工程后，只需简单配置，即可开始使用.

使用配置项初始化`HTTPDNS`服务，配置项包含阿里云应用的appId和appKey, 以及app需要预解析的域名列表。

```objc
NSArray<NSString *> *presolvedHostlist = @[@"api.abc.com", @"gateway.abc.com"];
KIDDNSConfig *config = [KIDDNSConfig new];
config.accountId = 100000;
config.key = @"your app key";
config.presolvedHosts = presolvedHostlist;
[[DNSCenter defaultCenter] initializeDNSServiceWithConfig:config];
```

*建议将初始化服务放在`didFinishLauch`中，尽可能放在网络请求之前。*

在app内部，你也可以针对某域名设置黑名单或者白名单，其规则是：
* 如果域名在黑名单内，则该域名相关的请求不会走`HTTPDNS`服务；
* 如果域名不在黑名单内，而在白名单内，则该域名相关的请求会尝试走`HTTPDNS`服务；
* 如果域名既不在黑名单内，且不在白名单内，并且白名单不为空，则该域名相关请求不走`HTTPDNS`服务；
* 如果域名既不在黑名单内，且不在白名单内，且白名单为空，则该域名相关请求会尝试走`HTTPDNS`服务；

黑白名单均是域名列表，支持正则匹配。

```objc
[DNSCenter defaultCenter].whiteList = @[@".vipkid.com.cn",@"api.abc.com"];
```

当app不需要`KIDDNS`服务运行时，也可以通过`automaticDNS`属性关闭KIDDNS服务。关闭之后KIDDNS中的`NSURLProtocol`就不再起作用。

```objc
[DNSCenter defaultCenter].automaticDNS = NO;
```

初始化`KIDDNS`服务之后，`automaticDNS`默认开启。

在`KIDDNS`服务开启的情况下，每个经过KIDDNS服务的请求都会被记录其是否走了`HTTPDNS`服务，以及是否最终成功。接入方如果关心这类记录，可以实现一个遵循`KIDDNSLogger`协议的日志类，并将该类添加到`KIDDNS`的日志服务中。*KIDDNS本身并不保存这些记录，请求结束后，记录即被销毁。*

```objc
@interface KIDLogger : NSObject<KIDDNSLogger>

@end

@implementation KIDLogger

- (void)logLevel:(KIDDNSLogLevel)level result:(KIDDNSResult *)result
{
    NSLog(@"[DNSLog][%@] result: %@", @(level), result);
}

@end

...


[[DNSCenter defaultCenter] addLogger:[KIDLogger new]];

```

## 容错重试

KIDDNS在底层拿到了请求域名的IP后，才会对请求进行拦截并进行重写。如果使用IP的方式进行网络请求而导致请求失败，KIDDNS会尝试使用原域名的方式再发起一次网络请求，如果仍然失败，则请求最终以失败结束，如果请求成功，则对请求发起方来说，请求依然成功，对中间的失败过程无感。

## 注意事项

*注意: 由于WKWebView页面及Cookie在HTTPDNS场景中很难处理，因此对于WebView请求KIDDNS并没有进行处理，仍然将使用系统默认的DNS服务*

## Author

yiyangest, y31210@gmail.com

## License

KIDDNS is available under the MIT license. See the LICENSE file for more info.
