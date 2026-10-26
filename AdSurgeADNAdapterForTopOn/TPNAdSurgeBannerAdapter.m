//
//  TPNAdSurgeBannerAdapter.m
//  iOSDemo
//

#import "TPNAdSurgeBannerAdapter.h"
#import "TPNAdSurgeBannerDelegate.h"

@interface TPNAdSurgeBannerAdapter ()

@property (nonatomic, strong) TPNAdSurgeBannerDelegate *bannerDelegate;
@property (nonatomic, strong) AdSurgeBannerAdView *bannerView;

@end

@implementation TPNAdSurgeBannerAdapter

#pragma mark - lazy

- (TPNAdSurgeBannerDelegate *)bannerDelegate {
    if (_bannerDelegate == nil) {
        _bannerDelegate = [[TPNAdSurgeBannerDelegate alloc] init];
        _bannerDelegate.adStatusBridge = self.adStatusBridge;
    }
    return _bannerDelegate;
}

#pragma mark - Ad load

- (void)loadADWithArgument:(ATAdMediationArgument *)argument {
    NSString *adUnitID = [self adUnitIDWithArgument:argument];
    if (adUnitID.length == 0) {
        NSError *error = [NSError errorWithDomain:kTPNAdSurgeAdapterErrorDomain
                                             code:ATAdErrorCodeInvalidInputEncountered
                                         userInfo:@{NSLocalizedDescriptionKey:@"AdSurge banner unitId is empty, please configure `unitId` on the TopOn dashboard."}];
        [self.adStatusBridge atOnAdLoadFailed:error adExtra:nil];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        // AdSurge 1.9.0 picks the banner size automatically, `AdSurgeAdConfig.adSize` is read only,
        // so the size delivered by TopOn is only used for the initial frame.
        CGSize bannerSize = CGSizeMake(320, 50);
        if (!CGSizeEqualToSize(argument.bannerSize, CGSizeZero)) {
            bannerSize = argument.bannerSize;
        }

        self.bannerView = [[AdSurgeBannerAdView alloc] initWithAdUnitIdentifier:adUnitID];
        self.bannerView.frame = CGRectMake(0, 0, bannerSize.width, bannerSize.height);
        // `viewController` must be set before loading, otherwise the load fails.
        self.bannerView.viewController = argument.viewController ?: [UIApplication sharedApplication].keyWindow.rootViewController;
        self.bannerView.delegate = self.bannerDelegate;

        self.bannerDelegate.bannerView = self.bannerView;

        AdSurgeAdConfig *config = [self adConfigWithArgument:argument adFormat:AdSurgeAdFormat.banner];
        [self.bannerView loadAd:config];
    });
}

#pragma mark - Show

/// AdSurge renders the banner inside its own view, so no extra show call is needed.
- (BOOL)callShowBannerView {
    return NO;
}

- (UIView *)getBannerView {
    return self.bannerView;
}

- (id)getAdObject {
    return self.bannerView;
}

#pragma mark - C2S win / loss

- (void)didReceiveBidResult:(ATBidWinLossResult *)result {
    [TPNAdSurgeBaseAdapter sendBidResult:result
                               forAd:self.bannerDelegate.loadedAd
                       placementType:AdSurgePlacementTypeBanner];
}

@end
