#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>

// --- OFFSET-URI DIN DUMP.CS ---
#define OFF_PLAYERCONTROLLER_MOVEMENT 0x40
#define OFF_PLAYERCONTROLLER_CAMERA   0x30
#define OFF_PLAYERCONTROLLER_PLAYER   0x90
#define OFF_PLAYERCONTROLLER_DEATH    0xA8
#define OFF_MOVEMENT_SELFROOT         0x188
#define OFF_PLAYER_ISLOCAL            0x1C
#define OFF_PLAYER_NICKNAME           0x20
#define OFF_GAMECONTROLLER_ALIVE      0x120

// --- STRUCTURI ---
struct Vector3 { float x, y, z; };
struct Vector2 { float x, y; };
struct Matrix4x4 { float m[4][4]; };

// --- VARIABILE GLOBALE ---
static void* g_GameController = nullptr;
static void* g_LocalPlayer = nullptr;
static void* g_MainCamera = nullptr;

bool b_ESP = false;
bool b_Skeleton = false;
bool b_Aimbot = false;

// --- FUNCTII DE CITIRE MEMORIE ---
template <typename T> T ReadMem(void* base, uint64_t offset) {
    if (!base) return T();
    return *(T*)((uint64_t)base + offset);
}

// --- FUNCTIE WORLD TO SCREEN (Transforma 3D in 2D) ---
bool WorldToScreen(Vector3 pos, Vector2* screen, Matrix4x4 matrix, int screenWidth, int screenHeight) {
    Vector3 transform = {
        matrix.m[0][0] * pos.x + matrix.m[0][1] * pos.y + matrix.m[0][2] * pos.z + matrix.m[0][3],
        matrix.m[1][0] * pos.x + matrix.m[1][1] * pos.y + matrix.m[1][2] * pos.z + matrix.m[1][3],
        matrix.m[3][0] * pos.x + matrix.m[3][1] * pos.y + matrix.m[3][2] * pos.z + matrix.m[3][3]
    };

    if (transform.z < 0.1f) return false;

    float x = transform.x / transform.z;
    float y = transform.y / transform.z;

    float screenX = (screenWidth / 2.0f) + (screenWidth / 2.0f) * x;
    float screenY = (screenHeight / 2.0f) - (screenHeight / 2.0f) * y;

    screen->x = screenX;
    screen->y = screenY;

    return true;
}

// --- INTERFATA GRAFICA ---
@interface CFMenuWindow : UIWindow <UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIView *menuView;
@property (nonatomic, strong) UIButton *floatingBtn;
@property (nonatomic, strong) UIView *espOverlay;
@property (nonatomic, strong) NSTimer *espTimer;
@end

@implementation CFMenuWindow

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.windowLevel = UIWindowLevelAlert + 1;
        self.backgroundColor = [UIColor clearColor];
        self.rootViewController = [[UIViewController alloc] init];
        
        // Overlay transparent pentru desenat ESP
        self.espOverlay = [[UIView alloc] initWithFrame:self.bounds];
        self.espOverlay.backgroundColor = [UIColor clearColor];
        self.espOverlay.userInteractionEnabled = NO;
        [self.rootViewController.view addSubview:self.espOverlay];
        
        // Butonul mic plutitor (CF)
        self.floatingBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        self.floatingBtn.frame = CGRectMake(20, 100, 40, 40);
        self.floatingBtn.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.8];
        self.floatingBtn.layer.cornerRadius = 20;
        [self.floatingBtn setTitle:@"CF" forState:UIControlStateNormal];
        [self.floatingBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.floatingBtn addTarget:self action:@selector(showMenu) forControlEvents:UIControlEventTouchUpInside];
        [self.rootViewController.view addSubview:self.floatingBtn];
        
        // Meniul principal
        self.menuView = [[UIView alloc] initWithFrame:CGRectMake(20, 150, 250, 240)];
        self.menuView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.9];
        self.menuView.layer.cornerRadius = 10;
        self.menuView.hidden = YES;
        [self.rootViewController.view addSubview:self.menuView];
        
        // Titlu
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, 200, 30)];
        title.text = @"CF Menu"; title.textColor = [UIColor whiteColor];
        [self.menuView addSubview:title];
        
        // Buton Închidere
        UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        closeBtn.frame = CGRectMake(210, 10, 30, 30);
        [closeBtn setTitle:@"X" forState:UIControlStateNormal];
        [closeBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [closeBtn addTarget:self action:@selector(hideMenu) forControlEvents:UIControlEventTouchUpInside];
        [self.menuView addSubview:closeBtn];
        
        // Switch-uri
        UISwitch *espSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(20, 60, 50, 30)];
        [espSwitch addTarget:self action:@selector(toggleESP:) forControlEvents:UIControlEventValueChanged];
        [self.menuView addSubview:espSwitch];
        UILabel *espLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, 60, 150, 30)];
        espLabel.text = @"ESP Box"; espLabel.textColor = [UIColor whiteColor];
        [self.menuView addSubview:espLabel];
        
        UISwitch *skelSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(20, 110, 50, 30)];
        [skelSwitch addTarget:self action:@selector(toggleSkeleton:) forControlEvents:UIControlEventValueChanged];
        [self.menuView addSubview:skelSwitch];
        UILabel *skelLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, 110, 150, 30)];
        skelLabel.text = @"ESP Skeleton"; skelLabel.textColor = [UIColor whiteColor];
        [self.menuView addSubview:skelLabel];
        
        UISwitch *aimSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(20, 160, 50, 30)];
        [aimSwitch addTarget:self action:@selector(toggleAimbot:) forControlEvents:UIControlEventValueChanged];
        [self.menuView addSubview:aimSwitch];
        UILabel *aimLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, 160, 150, 30)];
        aimLabel.text = @"Aimbot"; aimLabel.textColor = [UIColor whiteColor];
        [self.menuView addSubview:aimLabel];
        
        // Pornim timer-ul care deseneaza
        self.espTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(drawESP) userInfo:nil repeats:YES];
    }
    return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    if (hitView == self.rootViewController.view || hitView == self.espOverlay) return nil;
    return hitView;
}

- (void)showMenu { self.menuView.hidden = NO; }
- (void)hideMenu { self.menuView.hidden = YES; }

- (void)toggleESP:(UISwitch *)sender { b_ESP = sender.isOn; }
- (void)toggleSkeleton:(UISwitch *)sender { b_Skeleton = sender.isOn; }
- (void)toggleAimbot:(UISwitch *)sender { b_Aimbot = sender.isOn; }

- (void)drawESP {
    // Stergem liniile vechi
    for (CALayer *layer in [self.espOverlay.layer.sublayers copy]) {
        [layer removeFromSuperlayer];
    }
    
    if (!b_ESP && !b_Skeleton) return;
    if (!g_GameController || !g_MainCamera) return;

    // Aici e logica de citire (Momentan o lasam goala pana stim matricea exacta)
    // Jocul foloseste o matrice de camera. Fara offset-ul exact al matricei, nu putem desena.
}
@end
