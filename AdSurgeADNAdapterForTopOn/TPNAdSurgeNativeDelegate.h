//
//  TPNAdSurgeNativeDelegate.h
//  iOSDemo
//
//  Bridges AdSurge native ad callbacks to the TopOn SDK.
//

#import <Foundation/Foundation.h>
#import <AnyThinkSDK/AnyThinkSDK.h>
#import <AdSurgeSDK/AdSurgeSDK.h>
// Not exported by AdSurgeSDK.h, imported explicitly.
#import <AdSurgeSDK/AdSurgeNativeAdDelegate.h>
#import <AdSurgeSDK/AdSurgeNativeMediaContentDelegate.h>
#import <AdSurgeSDK/AdSurgeMediaContent.h>

NS_ASSUME_NONNULL_BEGIN

@interface TPNAdSurgeNativeDelegate : NSObject <AdSurgeNativeAdDelegate, AdSurgeNativeMediaContentDelegate>

@property (nonatomic, strong) ATNativeAdStatusBridge *adStatusBridge;

@property (nonatomic, strong, nullable) ATAdMediationArgument *adMediationArgument;

/// The AdSurge native ad object being loaded.
@property (nonatomic, weak) AdSurgeNativeAd *nativeAd;

/// The loaded ad object, used to send the C2S win / loss notification.
@property (nonatomic, strong, nullable) AdSurgeAd *loadedAd;

@end

NS_ASSUME_NONNULL_END
