TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = LockXTimePrefs
LockXTimePrefs_FILES = LXTRootListController.m
LockXTimePrefs_INSTALL_PATH = /Library/PreferenceBundles
LockXTimePrefs_FRAMEWORKS = UIKit
LockXTimePrefs_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk
