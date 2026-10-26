//
//  TPNAdSurgeNativeObject.m
//  iOSDemo
//

#import "TPNAdSurgeNativeObject.h"
@interface TPNAdSurgeNativeObject ()

/// The container inserted between the TopOn container and the developer's subviews.
@property (nonatomic, weak) AdSurgeNativeAdView *adSurgeContainerView;
/// Constraints created by the adapter for the AdChoices icon, kept so they can be replaced.
@property (nonatomic, copy, nullable) NSArray<NSLayoutConstraint *> *adChoicesConstraints;


@end

@implementation TPNAdSurgeNativeObject

#pragma mark - Register

/// Registers the container and the clickable views with the AdSurge SDK.
/// AdSurge requires the ad assets to live inside an `AdSurgeNativeAdView` container, so an
/// `AdSurgeNativeAdView` is inserted between the TopOn container and its subviews.
- (void)registerClickableViews:(NSArray<UIView *> *)clickableViews
                 withContainer:(UIView *)container
              registerArgument:(ATNativeRegisterArgument *)registerArgument {
    if (container == nil) { return; }
    
    // AdSurge 1.9.0 only offers self rendered native ads, there is no template view.
    AdSurgeNativeAdView *nativeAdView = [[AdSurgeNativeAdView alloc] initWithFrame:container.bounds];
    nativeAdView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    // Move the views built by the developer into the AdSurge container, keeping the layout.
    NSArray<UIView *> *originSubviews = [container.subviews copy];
    [container addSubview:nativeAdView];
    for (UIView *subview in originSubviews) {
        [nativeAdView addSubview:subview];
    }
    
    // Register the assets so that AdSurge can track the impression correctly.
    if (registerArgument.titleLabel != nil) {
        [nativeAdView setHeadlineView:registerArgument.titleLabel];
    }
    if (registerArgument.textLabel != nil) {
        [nativeAdView setBodyView:registerArgument.textLabel];
    }
    if (registerArgument.iconImageView != nil) {
        [nativeAdView setIconView:registerArgument.iconImageView];
    }
    if (registerArgument.ctaLabel != nil) {
        [nativeAdView setCallToActionView:registerArgument.ctaLabel];
    }
    if (self.mediaView != nil) {
        [nativeAdView setMediaView:self.mediaView];
    }
    
    if (registerArgument.viewController != nil) {
        self.nativeAd.viewController = registerArgument.viewController;
    }
    
    self.adSurgeContainerView = nativeAdView;
    
    // AdChoices (negative feedback / privacy icon). AdSurge only hands over a ready made view and
    // offers no registration API for it, so the adapter mounts and positions it by itself, honouring
    // the developer's `adChoicesViewOrigin` / `logoViewFrame` preference.
    [self layoutAdChoicesViewIfNeeded];
    
    NSMutableArray<UIView *> *clickViews = [NSMutableArray arrayWithArray:clickableViews ?: @[]];
    if (clickViews.count == 0) {
        // Fall back to the registered assets instead of the whole container, otherwise a tap on the
        // AdChoices icon would also be counted as an ad click.
        [clickViews addObjectsFromArray:[self fallbackClickViewsWithRegisterArgument:registerArgument
                                                                           container:nativeAdView]];
    }
    [self.nativeAd registerViewForInteraction:nativeAdView clickViews:clickViews];
}

#pragma mark - AdChoices

static const CGFloat kTPNAdSurgeAdChoicesDefaultSide = 20.0f;
static const CGFloat kTPNAdSurgeAdChoicesDefaultMargin = 4.0f;

/// Mounts and positions the AdSurge AdChoices icon (negative feedback / privacy badge).
/// AdSurge offers no registration API for it, so the adapter owns the layout. Auto Layout is used
/// on purpose: `registerClickableViews:` may run before the container has a real frame.
- (void)layoutAdChoicesViewIfNeeded {
    UIView *adChoicesView = self.nativeAd.adChoicesView;
    UIView *container = self.adSurgeContainerView;
    if (adChoicesView == nil || container == nil) { return; }

    adChoicesView.userInteractionEnabled = YES;
    if (adChoicesView.superview != container) {
        [adChoicesView removeFromSuperview];
        [container addSubview:adChoicesView];
    }
    [container bringSubviewToFront:adChoicesView];

    // This method can run twice (register first, config later), drop the previous constraints.
    if (self.adChoicesConstraints.count > 0) {
        [NSLayoutConstraint deactivateConstraints:self.adChoicesConstraints];
        self.adChoicesConstraints = nil;
    }
    adChoicesView.translatesAutoresizingMaskIntoConstraints = NO;

    // Size: the developer's `logoViewFrame` first, then a compliant default.
    CGSize size = self.renderConfig.logoViewFrame.size;
    if (size.width <= 0 || size.height <= 0) {
        size = CGSizeMake(kTPNAdSurgeAdChoicesDefaultSide, kTPNAdSurgeAdChoicesDefaultSide);
    }

    NSMutableArray<NSLayoutConstraint *> *constraints =
        [NSMutableArray arrayWithArray:@[[adChoicesView.widthAnchor constraintEqualToConstant:size.width],
                                         [adChoicesView.heightAnchor constraintEqualToConstant:size.height]]];

    CGPoint origin = self.renderConfig.adChoicesViewOrigin;
    if (!CGPointEqualToPoint(origin, CGPointZero)) {
        // The developer pinned the icon explicitly, honour it verbatim.
        [constraints addObject:[adChoicesView.leadingAnchor constraintEqualToAnchor:container.leadingAnchor
                                                                          constant:origin.x]];
        [constraints addObject:[adChoicesView.topAnchor constraintEqualToAnchor:container.topAnchor
                                                                      constant:origin.y]];
    } else {
        // Otherwise follow the corner preference. TopOn defaults to the bottom right corner.
        const CGFloat margin = kTPNAdSurgeAdChoicesDefaultMargin;
        switch ([ATAPI sharedInstance].preferredAdLogoPosition) {
            case ATAdLogoPositionTopLeftCorner:
                [constraints addObject:[adChoicesView.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:margin]];
                [constraints addObject:[adChoicesView.topAnchor constraintEqualToAnchor:container.topAnchor constant:margin]];
                break;
            case ATAdLogoPositionTopRightCorner:
                [constraints addObject:[adChoicesView.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-margin]];
                [constraints addObject:[adChoicesView.topAnchor constraintEqualToAnchor:container.topAnchor constant:margin]];
                break;
            case ATAdLogoPositionBottomLeftCorner:
                [constraints addObject:[adChoicesView.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:margin]];
                [constraints addObject:[adChoicesView.bottomAnchor constraintEqualToAnchor:container.bottomAnchor constant:-margin]];
                break;
            case ATAdLogoPositionBottomRightCorner:
            default:
                [constraints addObject:[adChoicesView.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-margin]];
                [constraints addObject:[adChoicesView.bottomAnchor constraintEqualToAnchor:container.bottomAnchor constant:-margin]];
                break;
        }
    }

    [NSLayoutConstraint activateConstraints:constraints];
    self.adChoicesConstraints = constraints;
}

/// The asset views to register as clickable when the app layer did not pass any, deliberately
/// excluding the AdChoices icon and the TopOn dislike button.
- (NSArray<UIView *> *)fallbackClickViewsWithRegisterArgument:(ATNativeRegisterArgument *)registerArgument
                                                    container:(UIView *)container {
    NSMutableArray<UIView *> *views = [NSMutableArray array];
    for (UIView *view in @[registerArgument.titleLabel ?: [NSNull null],
                           registerArgument.textLabel ?: [NSNull null],
                           registerArgument.iconImageView ?: [NSNull null],
                           registerArgument.ctaLabel ?: [NSNull null],
                           self.mediaView ?: [NSNull null]]) {
        if ([view isKindOfClass:[UIView class]]) { [views addObject:view]; }
    }
    return views.count > 0 ? views : @[container];
}

#pragma mark - Configuration

- (void)setNativeADConfiguration:(ATNativeAdRenderConfig *)configuration {
    self.renderConfig = configuration;
    if (configuration.rootViewController != nil) {
        self.nativeAd.viewController = configuration.rootViewController;
    }
    // The config may arrive after `registerClickableViews:`, re-apply the AdChoices layout.
    [self layoutAdChoicesViewIfNeeded];
}


#pragma mark - ATAdLoadedNativeDataSource, video controls

- (CGFloat)videoDuration {
    return [self.nativeAd.mediaContent duration];
}

- (void)videoPlay {
    [self.nativeAd.mediaContent play];
}

- (void)videoPause {
    [self.nativeAd.mediaContent pause];
}

- (void)destroyNative {
    if (self.adChoicesConstraints.count > 0) {
        [NSLayoutConstraint deactivateConstraints:self.adChoicesConstraints];
        self.adChoicesConstraints = nil;
    }
    [self.nativeAd.adChoicesView removeFromSuperview];
    self.nativeAd = nil;
}

#pragma mark - life

- (void)dealloc {
    [_nativeAd.mediaContent pause];
}

@end
