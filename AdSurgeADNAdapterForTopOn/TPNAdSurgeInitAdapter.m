//
//  TPNAdSurgeInitAdapter.m
//  iOSDemo
//

#import "TPNAdSurgeInitAdapter.h"
#import "TPNAdSurgeBaseAdapter.h"

@implementation TPNAdSurgeInitAdapter

#pragma mark - Init AdSurge SDK

/// Initialize the AdSurge ADN SDK.
/// - Parameter adInitArgument: config delivered by the TopOn server + local passthrough info.
- (void)initWithInitArgument:(ATAdInitArgument *)adInitArgument {
    // App ID delivered by the TopOn dashboard, there is no local fallback.
    NSString *appID = [self appIDWithInitArgument:adInitArgument];
    if (appID.length == 0) {
        NSError *error = [NSError errorWithDomain:kTPNAdSurgeAdapterErrorDomain
                                             code:ATAdErrorCodeInvalidInputEncountered
                                         userInfo:@{NSLocalizedDescriptionKey:@"AdSurge appid is empty, please configure `appid` on the TopOn dashboard."}];
        [self notificationNetworkInitFail:error];
        return;
    }

    // Privacy settings, mapped from the values the developer set through the TopOn SDK.
    AdSurgePrivacyConfiguration *privacy = [AdSurgePrivacyConfiguration configuration];
    // COPPA, age restricted user.
    privacy.ageRestrictedUser = @(adInitArgument.complyWithCOPPA ? 1 : 0);
    // CCPA, do not sell / share personal information.
    privacy.doNotSell = @(adInitArgument.complyWithCCPA ? 1 : 0);
    // GDPR, user consent for data processing.
    privacy.userConsent = @(adInitArgument.limitGdpr ? 0 : 1);
    // Personalized ads switch.
    privacy.nonPersonalizedAds = @((adInitArgument.personalizedAdState == ATNonpersonalizedAdStateType || adInitArgument.limitGdprConsent) ? 1 : 0);

    AdSurgeSDKConfig *config = [AdSurgeSDKConfig new];
    config.appId = appID;

    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[AdSurgeAdSdk shared] initializeWithConfig:config completionHandler:^(BOOL success, AdSurgeError * _Nullable error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf == nil) { return; }

            if (success) {
                [strongSelf notificationNetworkInitSuccess];
            } else {
                NSError *initError = [NSError errorWithDomain:kTPNAdSurgeAdapterErrorDomain
                                                         code:error.code
                                                     userInfo:@{NSLocalizedDescriptionKey:error.message ?: @"AdSurge SDK initialize failed."}];
                [strongSelf notificationNetworkInitFail:initError];
            }
        }];
    });
}

#pragma mark - Version

/// AdSurge SDK version.
- (nullable NSString *)sdkVersion {
    return AdSurgeAdSdkVersion;
}

/// Adapter version.
- (nullable NSString *)adapterVersion {
    return kTPNAdSurgeAdapterVersion;
}

#pragma mark - Private

/// 读取后台下发的 AdSurge App ID。
/// 后台填写风格不统一（`appid` / `appId` / `app_id`），这里按别名依次兜底，
/// 避免因为 NSDictionary 的 key 大小写敏感而误报 "appid is empty"。
- (NSString *)appIDWithInitArgument:(ATAdInitArgument *)adInitArgument {
    NSDictionary *serverDic = adInitArgument.serverContentDic;
    if (![serverDic isKindOfClass:[NSDictionary class]]) { return @""; }

    NSArray<NSString *> *aliasKeys = @[@"appId", @"appid", @"app_id", @"appID", @"APPID"];
    for (NSString *key in aliasKeys) {
        id value = serverDic[key];
        if ([value isKindOfClass:[NSNumber class]]) {
            value = [(NSNumber *)value stringValue];
        }
        if (![value isKindOfClass:[NSString class]]) { continue; } // NSNull / 容器类型一律跳过
        // 后台复制粘贴容易带首尾空格，trim 一下，否则同样会被当成已配置却请求失败。
        NSString *appID = [(NSString *)value stringByTrimmingCharactersInSet:
                           [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (appID.length > 0) { return appID; }
    }
    return @"";
}



@end
