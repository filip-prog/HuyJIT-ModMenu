#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// Variabilele globale pentru meniu
bool b_ESP = false;
bool b_Skeleton = false;
bool b_Aimbot = false;

// Creăm fereastra meniului
@interface CFMenuWindow : UIWindow
@property (nonatomic, strong) UIView *menuView;
@end

@implementation CFMenuWindow

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.windowLevel = UIWindowLevelAlert + 1;
        self.backgroundColor = [UIColor clearColor];
        self.rootViewController = [[UIViewController alloc] init];
        
        // Panoul negru semi-transparent
        self.menuView = [[UIView alloc] initWithFrame:CGRectMake(20, 100, 250, 220)];
        self.menuView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.9];
        self.menuView.layer.cornerRadius = 10;
        self.menuView.layer.borderWidth = 1;
        self.menuView.layer.borderColor = [UIColor whiteColor].CGColor;
        [self.rootViewController.view addSubview:self.menuView];
        
        // Titlu
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, 250, 30)];
        title.text = @"CF Menu";
        title.textColor = [UIColor whiteColor];
        title.textAlignment = NSTextAlignmentCenter;
        title.font = [UIFont boldSystemFontOfSize:18];
        [self.menuView addSubview:title];
        
        // Buton ESP
        UISwitch *espSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(20, 60, 50, 30)];
        [espSwitch addTarget:self action:@selector(toggleESP:) forControlEvents:UIControlEventValueChanged];
        [self.menuView addSubview:espSwitch];
        UILabel *espLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, 60, 150, 30)];
        espLabel.text = @"ESP Box";
        espLabel.textColor = [UIColor whiteColor];
        [self.menuView addSubview:espLabel];
        
        // Buton Skeleton
        UISwitch *skelSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(20, 110, 50, 30)];
        [skelSwitch addTarget:self action:@selector(toggleSkeleton:) forControlEvents:UIControlEventValueChanged];
        [self.menuView addSubview:skelSwitch];
        UILabel *skelLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, 110, 150, 30)];
        skelLabel.text = @"ESP Skeleton";
        skelLabel.textColor = [UIColor whiteColor];
        [self.menuView addSubview:skelLabel];
        
        // Buton Aimbot
        UISwitch *aimSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(20, 160, 50, 30)];
        [aimSwitch addTarget:self action:@selector(toggleAimbot:) forControlEvents:UIControlEventValueChanged];
        [self.menuView addSubview:aimSwitch];
        UILabel *aimLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, 160, 150, 30)];
        aimLabel.text = @"Aimbot";
        aimLabel.textColor = [UIColor whiteColor];
        [self.menuView addSubview:aimLabel];
    }
    return self;
}

- (void)toggleESP:(UISwitch *)sender { b_ESP = sender.isOn; }
- (void)toggleSkeleton:(UISwitch *)sender { b_Skeleton = sender.isOn; }
- (void)toggleAimbot:(UISwitch *)sender { b_Aimbot = sender.isOn; }

@end

static CFMenuWindow *g_MenuWindow = nil;

// Hook pentru UIWindow fara Logos
void (*orig_UIWindow_makeKeyAndVisible)(id, SEL);
void my_UIWindow_makeKeyAndVisible(id self, SEL _cmd) {
    if (orig_UIWindow_makeKeyAndVisible) orig_UIWindow_makeKeyAndVisible(self, _cmd);
    
    if (!g_MenuWindow) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            g_MenuWindow = [[CFMenuWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
            g_MenuWindow.hidden = NO;
        });
    }
}

__attribute__((constructor)) static void init() {
    Class winClass = objc_getClass("UIWindow");
    if (winClass) {
        Method m = class_getInstanceMethod(winClass, @selector(makeKeyAndVisible));
        if (m) {
            orig_UIWindow_makeKeyAndVisible = (void(*)(id,SEL))method_getImplementation(m);
            method_setImplementation(m, (IMP)my_UIWindow_makeKeyAndVisible);
        }
    }
}
