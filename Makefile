ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = CounterFlame

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CFMenu
CFMenu_FILES = ImGuiDrawView.mm
CFMenu_CFLAGS = -fobjc-arc
CFMenu_FRAMEWORKS = UIKit Foundation Metal
CFMenu_LDFLAGS = -Wl,-undefined,dynamic_lookup

include $(THEOS)/makefiles/tweak.mk
