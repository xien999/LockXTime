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
    notify_post("com.xien999.lockxtime/doRespring");
}

@end
