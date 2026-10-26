//
//  TPNAdSurgeNativeDelegate.m
//  iOSDemo
//

#import "TPNAdSurgeNativeDelegate.h"
#import "TPNAdSurgeNativeObject.h"
#import "TPNAdSurgeBaseAdapter.h"

@implementation TPNAdSurgeNativeDelegate

#pragma mark - AdSurgeNativeAdDelegate

/// Ad loaded, assemble the TopOn native ad material object.
- (void)didLoadAd:(AdSurgeAd *)ad {
    self.loadedAd = ad;

    AdSurgeNativeAd *nativeAd = self.nativeAd;
    if (nativeAd == nil) {
        NSError *error = [NSError errorWithDomain:kTPNAdSurgeAdapterErrorDomain
                                             code:ATAdErrorCodeADOfferNotFound
                                         userInfo:@{NSLocalizedDescriptionKey:@"AdSurge native ad object has been released."}];
        [self.adStatusBridge atOnAdLoadFailed:error adExtra:nil];
        return;
    }

    AdSurgeMediaContent *mediaContent = nativeAd.mediaContent;
    mediaContent.delegate = self;

    TPNAdSurgeNativeObject *nativeObject = [[TPNAdSurgeNativeObject alloc] init];
    nativeObject.nativeAd = nativeAd;
    // AdSurge 1.9.0 only supports self rendered native ads.
    nativeObject.nativeAdRenderType = ATNativeAdRenderSelfRender;
    nativeObject.nativeAdType = ATNativeAdTypeFeed;
    nativeObject.title = nativeAd.headLine;
    nativeObject.mainText = nativeAd.body;
    nativeObject.ctaText = nativeAd.callToAction;
    nativeObject.interactionType = ATNativeAdInteractionTypeOthers;

    // Icon. AdSurge only exposes a url, so the adapter downloads it before reporting the ad as
    // loaded, exactly like the official AppLovin adapter does in `ATApplovinCustomEvent.m`.
    // `ATImageLoader` is a public TopOn core component (Core/Managers) with its own cache, and is
    // shared with the SDK's own template native rendering, so no extra dependency is needed.
    // The url is still kept on the material object so that the upper layer can use it if needed.
    NSString *iconUrl = nativeAd.iconInfo.iconUrl;
    nativeObject.iconUrl = iconUrl;

    // Media content, the SDK renders the video / image inside this view.
    if (mediaContent != nil) {
        nativeObject.mediaView = mediaContent;
        CGFloat aspectRatio = [mediaContent aspectRatio];
        if (aspectRatio > 0) {
            nativeObject.videoAspectRatio = aspectRatio;
            nativeObject.mainImageWidth = aspectRatio * 100.0f;
            nativeObject.mainImageHeight = 100.0f;
        }
        BOOL hasVideo = [mediaContent hasVideoContent];
        nativeObject.isVideoContents = hasVideo;
        nativeObject.nativeMaterialFormat = hasVideo ? ATAdMaterialFormatVideo : ATAdMaterialFormatImage;
        if (hasVideo) {
            nativeObject.videoDuration = [mediaContent duration];
        }
    }

//    // AdChoices view, must be added into the same AdSurgeNativeAdView container.
//    if (nativeAd.adChoicesView != nil) {
//        nativeObject.logoView = nativeAd.adChoicesView;
//    }

    [self loadIconThenNotifyLoaded:nativeObject iconUrl:iconUrl revenue:ad.revenue];
}

/// Downloads the icon with the TopOn SDK image loader, then reports "ad loaded".
/// A `dispatch_group` is used so that adding more assets later stays trivial, and the load
/// success event is only sent once every asset is ready. A download failure is not fatal: the
/// ad is still reported as loaded, just without the icon.
- (void)loadIconThenNotifyLoaded:(TPNAdSurgeNativeObject *)nativeObject
                         iconUrl:(nullable NSString *)iconUrl
                         revenue:(double)revenue {
    dispatch_group_t imageLoadGroup = dispatch_group_create();

    if (iconUrl.length > 0) {
        dispatch_group_enter(imageLoadGroup);
        [[ATImageLoader shareLoader] newLoadImageWithURL:iconUrl completion:^(UIImage *image, NSError *error) {
            if (image != nil) {
                nativeObject.icon = image;
            } else {
                [ATAdLogger showExternalLogWarning:[NSString stringWithFormat:@"AdSurge native icon download failed, url:%@, error:%@", iconUrl, error]
                                         prefixStr:@"AdSurgeAdapter"];
            }
            dispatch_group_leave(imageLoadGroup);
        }];
    }

    __weak typeof(self) weakSelf = self;
    dispatch_group_notify(imageLoadGroup, dispatch_get_main_queue(), ^{
        [weakSelf.adStatusBridge atOnNativeAdLoadedArray:@[nativeObject]
                                                 adExtra:[TPNAdSurgeBaseAdapter c2sInfoWithRevenue:revenue]];
    });
}

/// Ad load failed.
- (void)didFailToLoadAdForAdUnitIdentifier:(NSString *)adUnitIdentifier withError:(AdSurgeError *)error {
    [self.adStatusBridge atOnAdLoadFailed:[TPNAdSurgeBaseAdapter errorWithAdSurgeError:error] adExtra:nil];
}

/// Ad displayed, `error` is non-nil when the display failed.
- (void)didDisplayAd:(AdSurgeAd *)ad withError:(AdSurgeError *)error {
    if (error != nil) {
        [self.adStatusBridge atOnAdShowFailed:[TPNAdSurgeBaseAdapter errorWithAdSurgeError:error] extra:nil];
        return;
    }
    [self.adStatusBridge atOnAdShow:nil];
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

#pragma mark - AdSurgeNativeMediaContentDelegate

- (void)mediaContentDidStartVideo {
    [self.adStatusBridge atOnAdVideoStart:nil];
}

- (void)mediaContentDidPauseVideo {
    // TopOn has no dedicated "video paused" event, nothing to report here.
}

- (void)mediaContentDidStopVideo {
    [self.adStatusBridge atOnAdVideoEnd:nil];
}

@end
