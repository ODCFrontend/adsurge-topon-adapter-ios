//
//  TPNAdSurgeNativeAdapter.m
//  iOSDemo
//

#import "TPNAdSurgeNativeAdapter.h"
#import "TPNAdSurgeNativeDelegate.h"

@interface TPNAdSurgeNativeAdapter ()

@property (nonatomic, strong) TPNAdSurgeNativeDelegate *nativeDelegate;
@property (nonatomic, strong) AdSurgeNativeAd *nativeAd;

@end

@implementation TPNAdSurgeNativeAdapter

#pragma mark - lazy

- (TPNAdSurgeNativeDelegate *)nativeDelegate {
    if (_nativeDelegate == nil) {
        _nativeDelegate = [[TPNAdSurgeNativeDelegate alloc] init];
        _nativeDelegate.adStatusBridge = self.adStatusBridge;
    }
    return _nativeDelegate;
}

#pragma mark - Ad load

- (void)loadADWithArgument:(ATAdMediationArgument *)argument {
    NSString *adUnitID = [self adUnitIDWithArgument:argument];
    if (adUnitID.length == 0) {
        NSError *error = [NSError errorWithDomain:kTPNAdSurgeAdapterErrorDomain
                                             code:ATAdErrorCodeInvalidInputEncountered
                                         userInfo:@{NSLocalizedDescriptionKey:@"AdSurge native unitId is empty, please configure `unitId` on the TopOn dashboard."}];
        [self.adStatusBridge atOnAdLoadFailed:error adExtra:nil];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        self.nativeAd = [[AdSurgeNativeAd alloc] initWithAdUnitIdentifier:adUnitID];
        // `viewController` must be set before loading, otherwise clicks cannot be handled.
        self.nativeAd.viewController = argument.viewController ?: [UIApplication sharedApplication].keyWindow.rootViewController;
        self.nativeAd.delegate = self.nativeDelegate;

        self.nativeDelegate.adMediationArgument = argument;
        self.nativeDelegate.nativeAd = self.nativeAd;

        AdSurgeAdConfig *config = [self adConfigWithArgument:argument adFormat:AdSurgeAdFormat.native];
        config.autoPlay = YES;
        config.nativeAdLogoPos = [self nativeLogoPositionWithArgument:argument];
        [self.nativeAd loadAd:config];
    });
}

- (id)getAdObject {
    return self.nativeAd;
}

#pragma mark - C2S win / loss

- (void)didReceiveBidResult:(ATBidWinLossResult *)result {
    [TPNAdSurgeBaseAdapter sendBidResult:result
                               forAd:self.nativeDelegate.loadedAd
                       placementType:AdSurgePlacementTypeNative];
}

@end
