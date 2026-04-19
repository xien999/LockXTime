TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LockXTime

LockXTime_FILES = Tweak.xm
LockXTime_CFLAGS = -fobjc-arc
LockXTime_PRIVATE_FRAMEWORKS = FrontBoardServices SpringBoardServices

SUBPROJECTS += prefs

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk
