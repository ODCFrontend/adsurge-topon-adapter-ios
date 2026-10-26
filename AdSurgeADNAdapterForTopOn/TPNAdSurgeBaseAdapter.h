//
//  TPNAdSurgeBaseAdapter.h
//  iOSDemo
//
//  TopOn custom ad network adapter for AdSurge ADN (SDK 1.9.0).
//
//  Base class of all AdSurge format adapters. It only tells the TopOn SDK which
//  init adapter to use, plus a few shared helpers (unit id / ad config / C2S price).
//  Class name of the base adapter does NOT need to be filled on the TopOn dashboard.
//
//  Docs:
//  - TopOn custom ad network (SDK >= 6.4.94): https://help.toponad.net/cn/docs/zi-ding-yi-guang-gao-ping-tai-SDK-ban-ben-6-4-94
//  - AdSurge iOS SDK integration: https://www.adsurge.com/supportcenter/article?platform=publisher&pid=2481235
//

#import <Foundation/Foundation.h>
// Umbrella headers shipped by the two SDKs, no self-made common header is needed.
#import <AnyThinkSDK/AnyThinkSDK.h>
#import <AdSurgeSDK/AdSurgeSDK.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Adapter version

/// Adapter version reported to the TopOn dashboard.
extern NSString *const kTPNAdSurgeAdapterVersion;

#pragma mark - Server config keys
/**
 * TopOn dashboard custom ad network config keys.
 *
 * The keys below are the ones actually delivered by the TopOn server, verified from the
 * `network_unit_info` section of the SDK log:
 *
 *   "network_unit_info" = {
 *       appid  = 10037;    // AdSurge App ID
 *       unitId = 15277;    // AdSurge Ad Unit ID of this ad format
 *   };
 */
extern NSString *const kTPNAdSurgeServerAppIDKey;
extern NSString *const kTPNAdSurgeServerUnitIDKey;

/// Optional bid floor configured in the dashboard custom parameters,
/// e.g. `"bid_floor": "1.5"`. Only meaningful for C2S bidding.
/// `extra` dictionary of the load call, i.e. `ATAdMediationArgument.localInfoDic`.
extern NSString *const kTPNAdSurgeBidFloorKey;

/// Optional preferred corner of the native ad logo, configured in the dashboard custom parameters
/// as `"ad_logo_position": "top_right"`. See `kTPNAdSurgeNativeLogoPositionKey` for the accepted
/// values. Native ad sources only.
extern NSString *const kTPNAdSurgeNativeLogoPositionKey;
/// Optional mute state of video creatives, configured in the dashboard custom parameters as
/// `"video_muted": "1"` — `1` muted, `0` with sound
extern NSString *const kTPNAdSurgeVideoMuteKey;

#pragma mark - Error

/// TopOn error domain used by this adapter.
extern NSString *const kTPNAdSurgeAdapterErrorDomain;

@interface TPNAdSurgeBaseAdapter : ATBaseMediationAdapter

/// Reads the AdSurge ad unit id from the dashboard config (`unitId`, `unit_id` as fallback).
/// Returns an empty string when it is not configured, the caller then reports a load failure
/// instead of requesting an ad with an invalid unit id.
- (NSString *)adUnitIDWithArgument:(ATAdMediationArgument *)argument;

/// Builds the AdSurge ad request config for the given format from the TopOn argument.
- (AdSurgeAdConfig *)adConfigWithArgument:(ATAdMediationArgument *)argument
                                 adFormat:(AdSurgeAdFormat *)adFormat;
/// Resolves the native ad logo corner from the TopOn configuration.
/// Defaults to `AdSurgeNativeLogoPosition_TopRight` when not configured.
- (AdSurgeNativeAdLogoPosition)nativeLogoPositionWithArgument:(ATAdMediationArgument *)argument;

/// Builds the C2S price dict which is passed back together with the "ad loaded" event.
/// - Parameter revenue: revenue of a single impression in USD, i.e. eCPM / 1000.
+ (NSDictionary *)c2sInfoWithRevenue:(double)revenue;

/// Wraps an `AdSurgeError` into an `NSError` so it can be reported to the TopOn SDK.
+ (NSError *)errorWithAdSurgeError:(nullable AdSurgeError *)error;

/// Forwards a TopOn C2S win / loss result to the AdSurge SDK.
/// - Parameters:
///   - result: win / loss result sent by the TopOn SDK.
///   - ad: the loaded AdSurge ad object, the notification urls are bound to it.
///   - placementType: AdSurge placement type of the current ad format.
+ (void)sendBidResult:(ATBidWinLossResult *)result
                forAd:(nullable AdSurgeAd *)ad
        placementType:(AdSurgePlacementType)placementType;

@end

NS_ASSUME_NONNULL_END
