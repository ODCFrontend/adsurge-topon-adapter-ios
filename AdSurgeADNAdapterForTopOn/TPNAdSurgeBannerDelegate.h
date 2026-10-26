//
//  TPNAdSurgeBannerDelegate.h
//  iOSDemo
//
//  Bridges AdSurge banner callbacks to the TopOn SDK.
//

#import <Foundation/Foundation.h>
#import <AnyThinkSDK/AnyThinkSDK.h>
#import <AdSurgeSDK/AdSurgeSDK.h>
// Not exported by AdSurgeSDK.h, imported explicitly.
#import <AdSurgeSDK/AdSurgeBannerAdDelegate.h>

NS_ASSUME_NONNULL_BEGIN

@interface TPNAdSurgeBannerDelegate : NSObject <AdSurgeBannerAdDelegate>

@property (nonatomic, strong) ATBannerAdStatusBridge *adStatusBridge;

/// The AdSurge banner view handed back to the TopOn SDK on load success.
@property (nonatomic, weak) AdSurgeBannerAdView *bannerView;

/// The loaded ad object, used to send the C2S win / loss notification.
@property (nonatomic, strong, nullable) AdSurgeAd *loadedAd;

@end

NS_ASSUME_NONNULL_END
