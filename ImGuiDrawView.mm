#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "IMGUI/imgui.h"
#import <objc/runtime.h>

#define OFF_PLAYERCONTROLLER_PLAYER   0x90
#define OFF_PLAYER_ISLOCAL            0x1C

template <typename T> T ReadMem(void* base, uint64_t offset) {
    if (!base) return T();
    return *(T*)((uint64_t)base + offset);
}

static void* g_GameController = nullptr;
static void* g_LocalPlayer = nullptr;

bool b_ESP = false;
bool b_Skeleton = false;
bool b_Aimbot = false;

// Hook GameController
void (*orig_GameController_Awake)(id, SEL);
void my_GameController_Awake(id self, SEL _cmd) {
    g_GameController = (__bridge void*)self;
    if (orig_GameController_Awake) orig_GameController_Awake(self, _cmd);
}

// Hook PlayerController
void (*orig_PlayerController_Awake)(id, SEL);
void my_PlayerController_Awake(id self, SEL _cmd) {
    void* selfPtr = (__bridge void*)self;
    void* player = ReadMem<void*>(selfPtr, OFF_PLAYERCONTROLLER_PLAYER);
    if (player && ReadMem<bool>(player, OFF_PLAYER_ISLOCAL)) {
        g_LocalPlayer = selfPtr;
    }
    if (orig_PlayerController_Awake) orig_PlayerController_Awake(self, _cmd);
}

// Se executa cand tweak-ul se incarca
__attribute__((constructor)) static void init() {
    Class gc = objc_getClass("GameController");
    if (gc) {
        Method m = class_getInstanceMethod(gc, @selector(Awake));
        if (m) { orig_GameController_Awake = (void(*)(id,SEL))method_getImplementation(m); method_setImplementation(m, (IMP)my_GameController_Awake); }
    }
    
    Class pc = objc_getClass("PlayerController");
    if (pc) {
        Method m = class_getInstanceMethod(pc, @selector(Awake));
        if (m) { orig_PlayerController_Awake = (void(*)(id,SEL))method_getImplementation(m); method_setImplementation(m, (IMP)my_PlayerController_Awake); }
    }
}
