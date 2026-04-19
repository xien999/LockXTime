#import "LXTRootListController.h"
#import <notify.h>

@implementation LXTRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}

- (void)respring {
    // Settings only posts a Darwin notification.
    // The tweak inside SpringBoard receives it and performs the actual respring.
    notify_post("com.xien999.lockxtime/doRespring");
}

@end
