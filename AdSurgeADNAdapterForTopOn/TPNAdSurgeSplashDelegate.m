//
//  TPNAdSurgeSplashDelegate.m
//  iOSDemo
//

#import "TPNAdSurgeSplashDelegate.h"
#import "TPNAdSurgeBaseAdapter.h"

@implementation TPNAdSurgeSplashDelegate

#pragma mark - AdSurgeAppOpenAdDelegate

/// Ad is cached and ready to show.
- (void)didLoadAd:(AdSurgeAd *)ad {
    self.loadedAd = ad;
    [self.adStatusBridge atOnSplashAdLoadedExtra:[TPNAdSurgeBaseAdapter c2sInfoWithRevenue:ad.revenue]];
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
}

/// Ad closed.
- (void)didHideAd:(AdSurgeAd *)ad {
    [self.adStatusBridge atOnAdWillClosed:nil];
    [self.adStatusBridge atOnAdClosed:nil];
}

/// Ad clicked.
- (void)didClickAd:(AdSurgeAd *)ad {
    [self.adStatusBridge atOnAdClick:nil];
}

/// Impression level revenue.
- (void)didPayRevenueForAd:(AdSurgeAd *)ad {
    [self.adStatusBridge atOnAdDidRevenue:@{@"revenue":@(ad.revenue),
                                            @"creative_id":ad.creativeId ?: @""}];
}

@end
