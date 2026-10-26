//
//  TPNAdSurgeBannerDelegate.m
//  iOSDemo
//

#import "TPNAdSurgeBannerDelegate.h"
#import "TPNAdSurgeBaseAdapter.h"

@implementation TPNAdSurgeBannerDelegate

#pragma mark - AdSurgeBannerAdDelegate

/// Ad loaded, the banner renders itself inside `AdSurgeBannerAdView`.
- (void)didLoadAd:(AdSurgeAd *)ad {
    self.loadedAd = ad;
    // Hand the third party banner view back to the TopOn SDK.
    [self.adStatusBridge atOnBannerAdLoadedWithView:self.bannerView
                                            adExtra:[TPNAdSurgeBaseAdapter c2sInfoWithRevenue:ad.revenue]];
}

/// Ad load failed.
- (void)didFailToLoadAdForAdUnitIdentifier:(NSString *)adUnitIdentifier withError:(AdSurgeError *)error {
    [self.adStatusBridge atOnAdLoadFailed:[TPNAdSurgeBaseAdapter errorWithAdSurgeError:error] adExtra:nil];
}

/// Banner hidden.
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
    // The AdSurge banner does not expose a dedicated "displayed" callback, the revenue
    // event is fired on impression, so the show event is reported here.
    [self.adStatusBridge atOnAdShow:nil];
    [self.adStatusBridge atOnAdDidRevenue:@{@"revenue":@(ad.revenue),
                                            @"creative_id":ad.creativeId ?: @""}];
}

@end
