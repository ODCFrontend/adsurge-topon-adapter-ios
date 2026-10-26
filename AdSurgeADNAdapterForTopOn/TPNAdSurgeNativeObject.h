//
//  TPNAdSurgeNativeObject.h
//  iOSDemo
//
//  TopOn native ad material object wrapping one `AdSurgeNativeAd`.
//

#import <Foundation/Foundation.h>
#import <AnyThinkSDK/AnyThinkSDK.h>
#import <AdSurgeSDK/AdSurgeSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface TPNAdSurgeNativeObject : ATCustomNetworkNativeAd

/// The AdSurge native ad object this material belongs to.
@property (nonatomic, strong) AdSurgeNativeAd *nativeAd;

/// Render config passed down by the developer through the TopOn SDK.
@property (nonatomic, strong, nullable) ATNativeAdRenderConfig *renderConfig;

@end

NS_ASSUME_NONNULL_END
