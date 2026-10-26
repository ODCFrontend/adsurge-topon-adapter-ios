//
//  TPNAdSurgeSplashAdapter.m
//  iOSDemo
//

#import "TPNAdSurgeSplashAdapter.h"
#import "TPNAdSurgeSplashDelegate.h"

@interface TPNAdSurgeSplashAdapter ()

@property (nonatomic, strong) TPNAdSurgeSplashDelegate *splashDelegate;
@property (nonatomic, strong) AdSurgeAppOpenAd *appOpenAd;

@end

@implementation TPNAdSurgeSplashAdapter

#pragma mark - lazy

- (TPNAdSurgeSplashDelegate *)splashDelegate {
    if (_splashDelegate == nil) {
        _splashDelegate = [[TPNAdSurgeSplashDelegate alloc] init];
        _splashDelegate.adStatusBridge = self.adStatusBridge;
    }
    return _splashDelegate;
}

#pragma mark - Ad load

- (void)loadADWithArgument:(ATAdMediationArgument *)argument {
    NSString *adUnitID = [self adUnitIDWithArgument:argument];
    if (adUnitID.length == 0) {
        NSError *error = [NSError errorWithDomain:kTPNAdSurgeAdapterErrorDomain
                                             code:ATAdErrorCodeInvalidInputEncountered
                                         userInfo:@{NSLocalizedDescriptionKey:@"AdSurge app open unitId is empty, please configure `unitId` on the TopOn dashboard."}];
        [self.adStatusBridge atOnAdLoadFailed:error adExtra:nil];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        self.appOpenAd = [[AdSurgeAppOpenAd alloc] initWithAdUnitIdentifier:adUnitID];
        self.appOpenAd.delegate = self.splashDelegate;

        // App open ads are muted by default on the AdSurge side.
        AdSurgeAdConfig *config = [self adConfigWithArgument:argument adFormat:AdSurgeAdFormat.appOpen];
        [self.appOpenAd loadAd:config];
    });
}

#pragma mark - Ad show

- (void)showSplashAdInWindow:(UIWindow *)window
            inViewController:(UIViewController *)inViewController
                   parameter:(NSDictionary *)parameter {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *rootVC = inViewController ?: window.rootViewController;
        if (self.appOpenAd.isValid == NO || rootVC == nil) {
            NSError *error = [NSError errorWithDomain:kTPNAdSurgeAdapterErrorDomain
                                                 code:ATAdErrorCodeADOfferNotFound
                                             userInfo:@{NSLocalizedDescriptionKey:@"AdSurge app open ad is not valid or the root view controller is nil."}];
            [self.adStatusBridge atOnAdShowFailed:error extra:nil];
            return;
        }
        [self.appOpenAd showAdFromRootViewController:rootVC];
    });
}

#pragma mark - Ad ready

- (BOOL)adReadySplashWithInfo:(NSDictionary *)info {
    return self.appOpenAd != nil && self.appOpenAd.isValid;
}

- (id)getAdObject {
    return self.appOpenAd;
}

#pragma mark - C2S win / loss

- (void)didReceiveBidResult:(ATBidWinLossResult *)result {
    [TPNAdSurgeBaseAdapter sendBidResult:result
                               forAd:self.splashDelegate.loadedAd
                       placementType:AdSurgePlacementTypeAppOpen];
}

@end
