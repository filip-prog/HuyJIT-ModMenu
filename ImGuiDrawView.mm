#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "IMGUI/imgui.h"
#import "IMGUI/backends/imgui_impl_metal.h"
#import "IMGUI/backends/imgui_impl_ios.h"
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>
#import <objc/runtime.h>

#define OFF_PLAYERCONTROLLER_MOVEMENT 0x40
#define OFF_PLAYERCONTROLLER_CAMERA   0x30
#define OFF_PLAYERCONTROLLER_PLAYER   0x90
#define OFF_PLAYERCONTROLLER_DEATH    0xA8
#define OFF_MOVEMENT_SELFROOT         0x188
#define OFF_PLAYER_ISLOCAL            0x1C
#define OFF_PLAYER_NICKNAME           0x20
#define OFF_GAMECONTROLLER_ALIVE      0x120

template <typename T> T ReadMem(void* base, uint64_t offset) {
    if (!base) return T();
    return *(T*)((uint64_t)base + offset);
}

struct Vector3 { float x, y, z; };
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

// Functia de desenare ImGui
void DrawMenu() {
    ImGui::Begin("CF Menu", nullptr, ImGuiWindowFlags_AlwaysAutoResize);
    ImGui::Text("Counter Flame Cheat");
    ImGui::Separator();
    ImGui::Checkbox("ESP Box", &b_ESP);
    ImGui::Checkbox("ESP Skeleton", &b_Skeleton);
    ImGui::Checkbox("Aimbot", &b_Aimbot);
    ImGui::End();
}

// Functia de hook pentru ImGui
void (*orig_ImGuiDrawView_draw)(id, SEL);
void my_ImGuiDrawView_draw(id self, SEL _cmd) {
    if (orig_ImGuiDrawView_draw) orig_ImGuiDrawView_draw(self, _cmd);
    
    // Desenam meniul nostru
    ImGuiIO& io = ImGui::GetIO();
    ImGui_ImplMetal_NewFrame((__bridge MTLRenderPassDescriptor*)nil);
    ImGui_ImplIOS_NewFrame();
    ImGui::NewFrame();
    
    DrawMenu();
    
    ImGui::Render();
    // Aici se face randarea efectiva (ImGui_ImplMetal_RenderDrawData)
}

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
