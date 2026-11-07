#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

bool b_ESP = false;
bool b_Skeleton = false;
bool b_Aimbot = false;

@interface CFMenuWindow : UIWindow <UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIView *menuView;
@property (nonatomic, strong) UIButton *floatingBtn;
@end

@implementation CFMenuWindow

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.windowLevel = UIWindowLevelAlert + 1;
        self.backgroundColor = [UIColor clearColor];
        self.rootViewController = [[UIViewController alloc] init];
        
        // Butonul mic plutitor (CF)
        self.floatingBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        self.floatingBtn.frame = CGRectMake(20, 100, 40, 40);
        self.floatingBtn.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.8];
        self.floatingBtn.layer.cornerRadius = 20;
        self.floatingBtn.layer.borderWidth = 1;
        self.floatingBtn.layer.borderColor = [UIColor whiteColor].CGColor;
        [self.floatingBtn setTitle:@"CF" forState:UIControlStateNormal];
        [self.floatingBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.floatingBtn addTarget:self action:@selector(showMenu) forControlEvents:UIControlEventTouchUpInside];
        [self.rootViewController.view addSubview:self.floatingBtn];
        
        // Panoul principal
        self.menuView = [[UIView alloc] initWithFrame:CGRectMake(20, 150, 250, 240)];
        self.menuView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.9];
        self.menuView.layer.cornerRadius = 10;
        self.menuView.layer.borderWidth = 1;
        self.menuView.layer.borderColor = [UIColor whiteColor].CGColor;
        self.menuView.hidden = YES;
        [self.rootViewController.view addSubview:self.menuView];
        
        // Titlu
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, 200, 30)];
        title.text = @"CF Menu";
        title.textColor = [UIColor whiteColor];
        title.font = [UIFont boldSystemFontOfSize:18];
        [self.menuView addSubview:title];
        
        // Buton Închidere
        UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        closeBtn.frame = CGRectMake(210, 10, 30, 30);
        [closeBtn setTitle:@"X" forState:UIControlStateNormal];
        [closeBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        closeBtn.titleLabel.font = [UIFont boldSystemFontOfSize:20];
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
        
        // Logica de mutare pentru Meniu
        UIPanGestureRecognizer *panMenu = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self.menuView addGestureRecognizer:panMenu];
        
        // Logica de mutare pentru Butonul CF
        UIPanGestureRecognizer *panBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self.floatingBtn addGestureRecognizer:panBtn];
    }
    return self;
}

// AICI E SMECHERIA: Lasam touch-urile sa treaca prin fereastra goala
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    if (hitView == self.rootViewController.view) {
        return nil; // Touch-ul merge in joc
    }
    return hitView;
}

- (void)showMenu { self.menuView.hidden = NO; }
- (void)hideMenu { self.menuView.hidden = YES; }

- (void)toggleESP:(UISwitch *)sender { b_ESP = sender.isOn; }
- (void)toggleSkeleton:(UISwitch *)sender { b_Skeleton = sender.isOn; }
- (void)toggleAimbot:(UISwitch *)sender { b_Aimbot = sender.isOn; }

- (void)handlePan:(UIPanGestureRecognizer *)sender {
    CGPoint translation = [sender translationInView:self];
    sender.view.center = CGPointMake(sender.view.center.x + translation.x, sender.view.center.y + translation.y);
    [sender setTranslation:CGPointZero inView:self];
}

@end

static CFMenuWindow *g_MenuWindow = nil;

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
