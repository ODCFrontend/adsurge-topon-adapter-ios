//
//  TPNAdSurgeRewardedAdapter.m
//  iOSDemo
//

#import "TPNAdSurgeRewardedAdapter.h"
#import "TPNAdSurgeRewardedVideoDelegate.h"

@interface TPNAdSurgeRewardedAdapter ()

@property (nonatomic, strong) TPNAdSurgeRewardedVideoDelegate *rewardedVideoDelegate;
@property (nonatomic, strong) AdSurgeRewardedAd *rewardedAd;

@end

@implementation TPNAdSurgeRewardedAdapter

#pragma mark - lazy

- (TPNAdSurgeRewardedVideoDelegate *)rewardedVideoDelegate {
    if (_rewardedVideoDelegate == nil) {
        _rewardedVideoDelegate = [[TPNAdSurgeRewardedVideoDelegate alloc] init];
        _rewardedVideoDelegate.adStatusBridge = self.adStatusBridge;
    }
    return _rewardedVideoDelegate;
}

#pragma mark - Ad load

- (void)loadADWithArgument:(ATAdMediationArgument *)argument {
    NSString *adUnitID = [self adUnitIDWithArgument:argument];
    if (adUnitID.length == 0) {
        NSError *error = [NSError errorWithDomain:kTPNAdSurgeAdapterErrorDomain
                                             code:ATAdErrorCodeInvalidInputEncountered
                                         userInfo:@{NSLocalizedDescriptionKey:@"AdSurge rewarded video unitId is empty, please configure `unitId` on the TopOn dashboard."}];
        [self.adStatusBridge atOnAdLoadFailed:error adExtra:nil];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        self.rewardedAd = [[AdSurgeRewardedAd alloc] initWithAdUnitIdentifier:adUnitID];
        self.rewardedAd.delegate = self.rewardedVideoDelegate;

        AdSurgeAdConfig *config = [self adConfigWithArgument:argument adFormat:AdSurgeAdFormat.rewarded];
        [self.rewardedAd loadAd:config];
    });
}

#pragma mark - Ad show

- (void)showRewardedVideoInViewController:(UIViewController *)viewController {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.rewardedAd.isValid == NO) {
            NSError *error = [NSError errorWithDomain:kTPNAdSurgeAdapterErrorDomain
                                                 code:ATAdErrorCodeADOfferNotFound
                                             userInfo:@{NSLocalizedDescriptionKey:@"AdSurge rewarded video ad is not valid."}];
            [self.adStatusBridge atOnAdShowFailed:error extra:nil];
            return;
        }
        [self.rewardedAd showAdFromRootViewController:viewController];
    });
}

#pragma mark - Ad ready

- (BOOL)adReadyRewardedWithInfo:(NSDictionary *)info {
    return self.rewardedAd != nil && self.rewardedAd.isValid;
}

- (id)getAdObject {
    return self.rewardedAd;
}

#pragma mark - C2S win / loss

- (void)didReceiveBidResult:(ATBidWinLossResult *)result {
    [TPNAdSurgeBaseAdapter sendBidResult:result
                               forAd:self.rewardedVideoDelegate.loadedAd
                       placementType:AdSurgePlacementTypeRewardedVideo];
}

@end
