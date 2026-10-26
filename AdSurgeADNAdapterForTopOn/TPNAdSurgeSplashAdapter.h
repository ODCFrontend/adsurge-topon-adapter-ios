//
//  TPNAdSurgeSplashAdapter.h
//  iOSDemo
//
//  Maps the TopOn splash ad format onto the AdSurge "App Open" ad.
//
//  ⚠️ Fill this class name in the "Splash Adapter Class Name" field of the
//  custom ad network on the TopOn dashboard: TPNAdSurgeSplashAdapter
//

#import <Foundation/Foundation.h>
#import "TPNAdSurgeBaseAdapter.h"

NS_ASSUME_NONNULL_BEGIN

@interface TPNAdSurgeSplashAdapter : TPNAdSurgeBaseAdapter <ATBaseSplashAdapterProtocol>

@end

NS_ASSUME_NONNULL_END
