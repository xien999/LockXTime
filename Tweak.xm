#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <notify.h>
#import <dlfcn.h>
#import <objc/runtime.h>

// Private headers — provided by your SDK
#import <FrontBoardServices/FBSSystemService.h>
#import <SpringBoardServices/SBSRelaunchAction.h>

// ─────────────────────────────────────────────────────────────────────────────

static NSString *const kPrefsDomain              = @"com.xien999.lockxtime";
static NSString *const kPrefsChangedNotification = @"com.xien999.lockxtime/prefsChanged";
static CFStringRef     kDoRespringNotification   = CFSTR("com.xien999.lockxtime/doRespring");

static BOOL    enabled           = YES;
static CGFloat stretchXVal       = 1.0;
static CGFloat stretchYVal       = 1.0;
static BOOL    isApplyingStretch = NO;

// ─── Preferences ─────────────────────────────────────────────────────────────

static void loadPrefs() {
    CFArrayRef keyList = CFPreferencesCopyKeyList(
        (CFStringRef)kPrefsDomain,
        kCFPreferencesCurrentUser,
        kCFPreferencesAnyHost
    );
    if (keyList) {
        NSDictionary *prefs = (NSDictionary *)CFBridgingRelease(
            CFPreferencesCopyMultiple(keyList, (CFStringRef)kPrefsDomain,
                                      kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
        );
        CFRelease(keyList);
        if (prefs) {
            enabled     = prefs[@"Enabled"]  ? [prefs[@"Enabled"] boolValue]   : YES;
            stretchXVal = prefs[@"StretchX"] ? [prefs[@"StretchX"] floatValue] : 1.0;
            stretchYVal = prefs[@"StretchY"] ? [prefs[@"StretchY"] floatValue] : 1.0;
        }
    } else {
        CFPreferencesSetAppValue((CFStringRef)@"Enabled",  (CFTypeRef)@YES,    (CFStringRef)kPrefsDomain);
        CFPreferencesSetAppValue((CFStringRef)@"StretchX", (CFTypeRef)@(1.0f), (CFStringRef)kPrefsDomain);
        CFPreferencesSetAppValue((CFStringRef)@"StretchY", (CFTypeRef)@(1.0f), (CFStringRef)kPrefsDomain);
        CFPreferencesAppSynchronize((CFStringRef)kPrefsDomain);
    }
    if (stretchXVal <= 0) stretchXVal = 1.0;
    if (stretchYVal <= 0) stretchYVal = 1.0;
}

// ─── Transform — stretches downward from top edge, no position shift ──────────
//
// CGAffineTransformMakeScale(sx, sy) scales from the CENTER of the view.
// This causes the top edge to move UP by (height * (sy-1) / 2) and the
// bottom edge to move DOWN by the same amount — not what we want.
//
// To pin the top edge and stretch only downward, we counter the upward
// shift with a downward translation added to the scale transform:
//
//   translateY = height * (sy - 1) / 2
//
// Combined into one transform:
//   T = Scale(sx, sy) · Translate(0, +translateY)
//
// This keeps the top edge exactly where it was and pushes only the bottom down.
// No anchorPoint or layer.position changes needed — pure CGAffineTransform.

static void ApplyStretchToView(UIView *view) {
    if (!view) return;
    if (isApplyingStretch) return;
    isApplyingStretch = YES;

    if (!enabled) {
        view.transform = CGAffineTransformIdentity;
    } else {
        CGFloat h = view.bounds.size.height;
        // How much center-scale would shift the top edge upward
        CGFloat translateY = h * (stretchYVal - 1.0) / 2.0;
        // Scale first, then push down to pin the top
        CGAffineTransform scale     = CGAffineTransformMakeScale(stretchXVal, stretchYVal);
        CGAffineTransform translate = CGAffineTransformMakeTranslation(0, translateY);
        view.transform = CGAffineTransformConcat(scale, translate);
    }

    isApplyingStretch = NO;
}

// ─── Hooks ───────────────────────────────────────────────────────────────────
// Only hook the TIME view — NOT SBFLockScreenDateView (the date label)

%hook CSProminentTimeView
- (void)layoutSubviews {
    %orig;
    ApplyStretchToView((UIView *)self);
}
%end

// ─── Respring — exact LiquidAss pattern ──────────────────────────────────────

static void performRespring(void) {
    dlopen("/System/Library/PrivateFrameworks/FrontBoardServices.framework/FrontBoardServices", RTLD_NOW);
    dlopen("/System/Library/PrivateFrameworks/SpringBoardServices.framework/SpringBoardServices", RTLD_NOW);

    Class actionClass  = objc_getClass("SBSRelaunchAction");
    Class serviceClass = objc_getClass("FBSSystemService");
    if (!actionClass || !serviceClass) return;

    SBSRelaunchAction *restartAction =
        [actionClass actionWithReason:@"LockXTimePrefs"
                              options:(SBSRelaunchActionOptionsRestartRenderServer |
                                       SBSRelaunchActionOptionsFadeToBlackTransition)
                            targetURL:nil];
    if (!restartAction) return;

    [[serviceClass sharedService] sendActions:[NSSet setWithObject:restartAction]
                                   withResult:nil];
}

static void doRespringCallback(CFNotificationCenterRef center,
                               void *observer,
                               CFStringRef name,
                               const void *object,
                               CFDictionaryRef userInfo) {
    dispatch_async(dispatch_get_main_queue(), ^{
        performRespring();
    });
}

static void prefsChangedCallback(CFNotificationCenterRef center,
                                 void *observer,
                                 CFStringRef name,
                                 const void *object,
                                 CFDictionaryRef userInfo) {
    loadPrefs();
}

// ─── Constructor ─────────────────────────────────────────────────────────────

%ctor {
    loadPrefs();
    CFNotificationCenterRef darwin = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterAddObserver(darwin, NULL, prefsChangedCallback,
    (CFStringRef)kPrefsChangedNotification, NULL,
    CFNotificationSuspensionBehaviorCoalesce);
    CFNotificationCenterAddObserver(darwin, NULL, doRespringCallback,
    kDoRespringNotification, NULL,
    CFNotificationSuspensionBehaviorDeliverImmediately);
    %init;
}
