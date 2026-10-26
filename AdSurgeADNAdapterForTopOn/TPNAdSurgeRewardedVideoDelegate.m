//
//  TPNAdSurgeRewardedVideoDelegate.m
//  iOSDemo
//

#import "TPNAdSurgeRewardedVideoDelegate.h"
#import "TPNAdSurgeBaseAdapter.h"

@implementation TPNAdSurgeRewardedVideoDelegate

#pragma mark - AdSurgeRewardedAdDelegate

/// Ad is cached and ready to show.
- (void)didLoadAd:(AdSurgeAd *)ad {
    self.loadedAd = ad;
    [self.adStatusBridge atOnRewardedAdLoadedExtra:[TPNAdSurgeBaseAdapter c2sInfoWithRevenue:ad.revenue]];
}

/// Ad load failed.
- (void)didFailToLoadAdForAdUnitIdentifier:(NSString *)adUnitIdentifier withError:(AdSurgeError *)error {
    [self.adStatusBridge atOnAdLoadFailed:[TPNAdSurgeBaseAdapter errorWithAdSurgeError:error] adExtra:nil];
}

/// Display started, `error` is non-nil when the show failed.
- (void)didDisplayAd:(AdSurgeAd *)ad withError:(AdSurgeError *)error {
    if (error != nil) {
        [self.adStatusBridge atOnAdShowFailed:[TPNAdSurgeBaseAdapter errorWithAdSurgeError:error] extra:nil];
        return;
    }
    [self.adStatusBridge atOnAdShow:nil];
    [self.adStatusBridge atOnAdVideoStart:nil];
}

/// Ad closed.
- (void)didHideAd:(AdSurgeAd *)ad {
    [self.adStatusBridge atOnAdVideoEnd:nil];
    [self.adStatusBridge atOnAdWillClosed:nil];
    [self.adStatusBridge atOnAdClosed:nil];
}

/// Ad clicked.
- (void)didClickAd:(AdSurgeAd *)ad {
    [self.adStatusBridge atOnAdClick:nil];
}

/// User earned the reward.
- (void)didRewardUserForAd:(AdSurgeAd *)ad withReward:(AdSurgeReward *)reward {
    [self.adStatusBridge atOnRewardedVideoAdRewarded];
}

/// Impression level revenue.
- (void)didPayRevenueForAd:(AdSurgeAd *)ad {
    [self.adStatusBridge atOnAdDidRevenue:@{@"revenue":@(ad.revenue),
                                            @"creative_id":ad.creativeId ?: @""}];
}

@end
