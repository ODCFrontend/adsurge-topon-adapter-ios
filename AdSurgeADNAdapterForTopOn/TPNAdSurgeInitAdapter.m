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

- (NSString *)appIDWithInitArgument:(ATAdInitArgument *)adInitArgument {
    id appID = adInitArgument.serverContentDic[kTPNAdSurgeServerAppIDKey];
    if ([appID isKindOfClass:[NSNumber class]]) {
        appID = [appID stringValue];
    }
    if ([appID isKindOfClass:[NSString class]] && [(NSString *)appID length] > 0) {
        return appID;
    }
    return @"";
}


@end
