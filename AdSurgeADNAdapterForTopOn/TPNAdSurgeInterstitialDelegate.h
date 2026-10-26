//
//  TPNAdSurgeInterstitialDelegate.h
//  iOSDemo
//
//  Bridges AdSurge interstitial callbacks to the TopOn SDK.
//

#import <Foundation/Foundation.h>
#import <AnyThinkSDK/AnyThinkSDK.h>
#import <AdSurgeSDK/AdSurgeSDK.h>
// Not exported by AdSurgeSDK.h, imported explicitly.
#import <AdSurgeSDK/AdSurgeInterstitialAdDelegate.h>

NS_ASSUME_NONNULL_BEGIN

@interface TPNAdSurgeInterstitialDelegate : NSObject <AdSurgeInterstitialAdDelegate>

@property (nonatomic, strong) ATInterstitialAdStatusBridge *adStatusBridge;

/// The loaded ad object, used to send the C2S win / loss notification.
@property (nonatomic, strong, nullable) AdSurgeAd *loadedAd;

@end

NS_ASSUME_NONNULL_END
