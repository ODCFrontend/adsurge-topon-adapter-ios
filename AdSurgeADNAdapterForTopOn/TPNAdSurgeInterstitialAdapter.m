//
//  TPNAdSurgeInterstitialAdapter.m
//  iOSDemo
//

#import "TPNAdSurgeInterstitialAdapter.h"
#import "TPNAdSurgeInterstitialDelegate.h"

@interface TPNAdSurgeInterstitialAdapter ()

@property (nonatomic, strong) TPNAdSurgeInterstitialDelegate *interstitialDelegate;
@property (nonatomic, strong) AdSurgeInterstitialAd *interstitialAd;

@end

@implementation TPNAdSurgeInterstitialAdapter

#pragma mark - lazy

- (TPNAdSurgeInterstitialDelegate *)interstitialDelegate {
    if (_interstitialDelegate == nil) {
        _interstitialDelegate = [[TPNAdSurgeInterstitialDelegate alloc] init];
        _interstitialDelegate.adStatusBridge = self.adStatusBridge;
    }
    return _interstitialDelegate;
}

#pragma mark - Ad load

- (void)loadADWithArgument:(ATAdMediationArgument *)argument {
    NSString *adUnitID = [self adUnitIDWithArgument:argument];
    if (adUnitID.length == 0) {
        NSError *error = [NSError errorWithDomain:kTPNAdSurgeAdapterErrorDomain
                                             code:ATAdErrorCodeInvalidInputEncountered
                                         userInfo:@{NSLocalizedDescriptionKey:@"AdSurge interstitial unitId is empty, please configure `unitId` on the TopOn dashboard."}];
        [self.adStatusBridge atOnAdLoadFailed:error adExtra:nil];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        self.interstitialAd = [[AdSurgeInterstitialAd alloc] initWithAdUnitIdentifier:adUnitID];
        self.interstitialAd.delegate = self.interstitialDelegate;

        AdSurgeAdConfig *config = [self adConfigWithArgument:argument adFormat:AdSurgeAdFormat.interstitial];
        [self.interstitialAd loadAd:config];
    });
}

#pragma mark - Ad show

- (void)showInterstitialInViewController:(UIViewController *)viewController {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.interstitialAd.isValid == NO) {
            NSError *error = [NSError errorWithDomain:kTPNAdSurgeAdapterErrorDomain
                                                 code:ATAdErrorCodeADOfferNotFound
                                             userInfo:@{NSLocalizedDescriptionKey:@"AdSurge interstitial ad is not valid."}];
            [self.adStatusBridge atOnAdShowFailed:error extra:nil];
            return;
        }
        [self.interstitialAd showAdFromRootViewController:viewController];
    });
}

#pragma mark - Ad ready

- (BOOL)adReadyInterstitialWithInfo:(NSDictionary *)info {
    return self.interstitialAd != nil && self.interstitialAd.isValid;
}

- (id)getAdObject {
    return self.interstitialAd;
}

#pragma mark - C2S win / loss

- (void)didReceiveBidResult:(ATBidWinLossResult *)result {
    [TPNAdSurgeBaseAdapter sendBidResult:result
                               forAd:self.interstitialDelegate.loadedAd
                       placementType:AdSurgePlacementTypeInterstitial];
}

@end
