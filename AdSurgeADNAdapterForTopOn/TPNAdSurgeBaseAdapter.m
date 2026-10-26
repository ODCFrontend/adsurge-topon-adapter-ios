//
//  TPNAdSurgeBaseAdapter.m
//  iOSDemo
//

#import "TPNAdSurgeBaseAdapter.h"
#import "TPNAdSurgeInitAdapter.h"

NSString *const kTPNAdSurgeAdapterVersion = @"1.9.0.0";

NSString *const kTPNAdSurgeServerAppIDKey          = @"appid";
NSString *const kTPNAdSurgeServerUnitIDKey         = @"unitId";

NSString *const kTPNAdSurgeAdapterErrorDomain = @"com.adsurge.topon.adapter";

NSString *const kTPNAdSurgeBidFloorKey       = @"bid_floor";

NSString *const kTPNAdSurgeNativeLogoPositionKey = @"ad_logo_position";

NSString *const kTPNAdSurgeVideoMuteKey      = @"video_muted";

@implementation TPNAdSurgeBaseAdapter

#pragma mark - adapter init class name define

- (Class)initializeClassName {
    return [TPNAdSurgeInitAdapter class];
}

#pragma mark - Public

- (NSString *)adUnitIDWithArgument:(ATAdMediationArgument *)argument {
    // `slot_id` must NOT be used here, it carries a different meaning on the TopOn side.
    id unitID = argument.serverContentDic[kTPNAdSurgeServerUnitIDKey];
    if ([unitID isKindOfClass:[NSNumber class]]) {
        unitID = [unitID stringValue];
    }
    if ([unitID isKindOfClass:[NSString class]] && [(NSString *)unitID length] > 0) {
        return unitID;
    }
    return @"";
}

- (AdSurgeAdConfig *)adConfigWithArgument:(ATAdMediationArgument *)argument
                                 adFormat:(AdSurgeAdFormat *)adFormat {
    AdSurgeAdConfig *config = [AdSurgeAdConfig configWithAdFormat:adFormat];
    
    config.mute = [self videoMutedWithArgument:argument];
    
    // Extra info passed to the ad server, useful for troubleshooting.
    NSMutableDictionary *extra = [NSMutableDictionary dictionary];
    if (argument.placementID.length > 0) {
        extra[@"topon_placement_id"] = argument.placementID;
    }
    if (argument.requestID.length > 0) {
        extra[@"topon_request_id"] = argument.requestID;
    }
    config.extra = extra.count > 0 ? extra.copy : nil;
    
    // Mediation info, reported by AdSurge for cross checking the revenue data.
    config.mediationSource = @"TopOn";
    config.mediationAdUnitId = argument.placementID;
    config.mediationTraceId = argument.requestID;
    
    // S2S bidding payload, only used when the ad source is configured as Header Bidding.
    if (argument.bidId.length > 0) {
        config.payload = argument.bidId;
    }
    ATAdapterLoadAdType loadType = argument.adapterLoadAdType;
    if (loadType == ATAdapterLoadTypeC2SRequesting ||
        loadType == ATAdapterLoadTypeC2SBiding) {
        config.bidFloor = [self bidFloorWithArgument:argument];
    }
    

    return config;
}

+ (NSDictionary *)c2sInfoWithRevenue:(double)revenue {
    // AdSurge reports the revenue of a single impression in USD, TopOn expects the eCPM.
    double ecpm = revenue * 1000.0f;
    if (ecpm < 0 || isnan(ecpm) || isinf(ecpm)) {
        ecpm = 0;
    }
    NSMutableDictionary *infoDic = [NSMutableDictionary dictionary];
    [infoDic AT_setDictValue:[NSString stringWithFormat:@"%f", ecpm] key:ATAdSendC2SBidPriceKey];
    [infoDic AT_setDictValue:@(ATBiddingCurrencyTypeUS) key:ATAdSendC2SCurrencyTypeKey];
    return infoDic.copy;
}

+ (NSError *)errorWithAdSurgeError:(AdSurgeError *)error {
    if (error == nil) {
        return [NSError errorWithDomain:kTPNAdSurgeAdapterErrorDomain
                                   code:ATAdErrorCodeADOfferLoadingFailed
                               userInfo:@{NSLocalizedDescriptionKey:@"AdSurge unknown error."}];
    }
    return [NSError errorWithDomain:kTPNAdSurgeAdapterErrorDomain
                               code:error.code
                           userInfo:@{NSLocalizedDescriptionKey:error.message ?: @"AdSurge unknown error."}];
}

+ (void)sendBidResult:(ATBidWinLossResult *)result
                forAd:(AdSurgeAd *)ad
        placementType:(AdSurgePlacementType)placementType {
    // Only meaningful when the ad source is configured as C2S bidding on the dashboard.
    if (ad == nil) { return; }

    // TopOn passes eCPM, AdSurge expects the price of a single impression, i.e. eCPM / 1000.
    double winPrice = [result.winPrice doubleValue] / 1000.0f;
    NSNumber *secondPrice = result.secondPrice.length > 0 ? @([result.secondPrice doubleValue] / 1000.0f) : nil;

    if (result.bidResultType == ATBidWinLossResultTypeWin) {
        [ad sendWinNotificationWithPrice:winPrice
                          minToWinPrice:secondPrice
                           minToWinSeat:nil
                      minToWinPlacement:@(placementType)
                       minToWinStrategy:@(AdSurgePriceStrategyTypeBidding)];
    } else {
        [ad sendLossNotificationWithPrice:winPrice
                            currencyType:@"USD"
                              lossReason:@([self adSurgeLossReasonWithATLossType:result.lossReasonType])
                             auctionSeat:nil
                           placementType:@(placementType)
                           priceStrategy:@(AdSurgePriceStrategyTypeBidding)];
    }
}

+ (AdSurgeLossReason)adSurgeLossReasonWithATLossType:(ATBiddingLossType)lossType {
    switch (lossType) {
        case ATBiddingLossWithBiddingTimeOut:
        case ATBiddingLossWithExpire:
            return AdSurgeLossReasonOverTime;
        case ATBiddingLossWithLowPriceInHB:
        case ATBiddingLossWithLowPriceInNormal:
            return AdSurgeLossReasonLossToOtherBidder;
        case ATBiddingLossWithFloorFilter:
        default:
            return AdSurgeLossReasonUnknown;
    }
}

- (AdSurgeNativeAdLogoPosition)nativeLogoPositionWithArgument:(ATAdMediationArgument *)argument {
    for (id value in [self configValuesForKey:kTPNAdSurgeNativeLogoPositionKey argument:argument]) {
        if (![value respondsToSelector:@selector(integerValue)]) { continue; }
        NSInteger raw = [value integerValue];
        // Out of range means "not configured": the value must be an `AdSurgeNativeAdLogoPosition`,
        // whose raw values start at 1, so 0 / garbage must not be forwarded to the SDK.
        if (raw >= AdSurgeNativeLogoPosition_TopLeft && raw <= AdSurgeNativeLogoPosition_BottomRight) {
            return (AdSurgeNativeAdLogoPosition)raw;
        }
    }
    return AdSurgeNativeLogoPosition_TopRight;
}

#pragma mark - Private

- (NSArray *)configValuesForKey:(NSString *)key argument:(ATAdMediationArgument *)argument {
    NSMutableArray *values = [NSMutableArray arrayWithCapacity:2];
    for (NSDictionary *source in @[argument.serverContentDic ?: @{},
                                   argument.localInfoDic ?: @{}]) {
        id value = source[key];
        if (value != nil && ![value isKindOfClass:[NSNull class]]) {
            [values addObject:value];
        }
    }
    return values;
}


/// Resolves the bid floor sent to AdSurge for this request.
///
/// Sources, in priority order — the first valid one wins, the other is not looked at:
///   1. `serverContentDic[kTPNAdSurgeBidFloorKey]` — the `bid_floor` custom parameter of the ad
///      source on the TopOn dashboard. Source of truth: the operation team can change it without
///      an app release, and it is meant to mirror the floor TopOn itself filters the bids with.
///   2. `localInfoDic[kTPNAdSurgeBidFloorKey]` — value passed by the developer in the `extra` of
///      the load call. Fallback only, on purpose: a hardcoded app side value must never silently
///      shadow the dashboard configuration. Handy to pressure test the floor during integration.
///
/// ⚠️ UNIT CONVERSION: both sources are an **eCPM in USD** (USD per 1000 impressions), like every
/// price on the TopOn side, while `AdSurgeAdConfig.bidFloor` is the price of a **single
/// impression** in USD, exactly like `AdSurgeAd.revenue` and `-sendWinNotificationWithPrice:`.
/// Hence the `/ 1000`, which is the mirror image of `+c2sInfoWithRevenue:` multiplying by 1000.
/// Forgetting it makes the floor 1000x too high, and the only visible symptom is that the ad
/// source silently stops filling.
///
/// The floor is deliberately NOT sent in the other load scenarios:
///   - S2S (`argument.bidId` is not empty): the auction already settled on the TopOn server, this
///     request is only a fill with the winning payload, a floor could just cause a spurious no fill.
///   - plain waterfall / self fill: the price is fixed by the dashboard, a floor would only hurt
///     the fill rate without buying anything.
///
/// @return The single impression floor price in USD, or nil when no floor applies. nil means "no
///         filtering at all" on the AdSurge side, i.e. exactly the behaviour of the adapter before
///         this parameter was introduced, so ad sources without a floor are not affected.
- (NSNumber * _Nullable)bidFloorWithArgument:(ATAdMediationArgument * _Nonnull)argument {
    // S2S bidding: the winning bid is already chosen, only `payload` matters here.
    if (argument.bidId.length > 0) { return nil; }

    // Client side auction only.
    switch (argument.adapterLoadAdType) {
        case ATAdapterLoadTypeC2SRequesting:
        case ATAdapterLoadTypeC2SBiding:
            break;
        default:
            return nil;
    }

    for (id value in [self configValuesForKey:kTPNAdSurgeBidFloorKey argument:argument]) {
        double floor = 0;
        if ([value isKindOfClass:[NSNumber class]]) {
            floor = [(NSNumber *)value doubleValue];
        } else if ([value isKindOfClass:[NSString class]]) {
            // The dashboard may deliver the value as a string.
            floor = [(NSString *)value doubleValue];
        }
        // Zero / negative / garbage means "not configured", try the next source.
        // Forwarded as is: no unit conversion, see `kTPNAdSurgeBidFloorKey`.
        if (floor > 0 && !isnan(floor) && !isinf(floor)) { return @(floor); }
    }
    return nil;
}

- (BOOL)videoMutedWithArgument:(ATAdMediationArgument *)argument {
    for (id value in [self configValuesForKey:kTPNAdSurgeVideoMuteKey argument:argument]) {
        NSNumber *muted = [self boolNumberWithConfigValue:value];
        if (muted != nil) { return muted.boolValue; }
    }
    return [ATSDKGlobalSetting sharedManager].isMute;
}

/// Parses a dashboard / local config value into a tri-state boolean.
/// @return `@YES` / `@NO`, or nil when the value cannot be interpreted as a boolean.
- (NSNumber * _Nullable)boolNumberWithConfigValue:(id)value {
    if ([value isKindOfClass:[NSNumber class]]) {
        return @([(NSNumber *)value boolValue]);
    }
    if (![value isKindOfClass:[NSString class]]) {
        return nil; // NSNull, arrays, dictionaries — never send `boolValue` to those.
    }
    NSString *text = [[(NSString *)value stringByTrimmingCharactersInSet:
                       [NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
    if ([@[@"1"] containsObject:text])  { return @YES; }
    if ([@[@"0"] containsObject:text]) { return @NO; }
    return nil;
}


@end
