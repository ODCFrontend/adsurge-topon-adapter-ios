//
//  TPNAdSurgeSplashDelegate.h
//  iOSDemo
//
//  Bridges AdSurge app open ad callbacks to the TopOn splash ad format.
//

#import <Foundation/Foundation.h>
#import <AnyThinkSDK/AnyThinkSDK.h>
#import <AdSurgeSDK/AdSurgeSDK.h>
// Not exported by AdSurgeSDK.h, imported explicitly.
#import <AdSurgeSDK/AdSurgeAppOpenAdDelegate.h>

NS_ASSUME_NONNULL_BEGIN

@interface TPNAdSurgeSplashDelegate : NSObject <AdSurgeAppOpenAdDelegate>

@property (nonatomic, strong) ATSplashAdStatusBridge *adStatusBridge;

/// The loaded ad object, used to send the C2S win / loss notification.
@property (nonatomic, strong, nullable) AdSurgeAd *loadedAd;

@end

NS_ASSUME_NONNULL_END
