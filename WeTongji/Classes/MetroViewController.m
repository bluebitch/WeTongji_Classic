//
//  MetroViewController.m
//  WeTongji
//
//  Created by 紫川 王 on 12-3-6.
//  Copyright (c) 2012年 Tongji Apple Club. All rights reserved.
//

#import "MetroViewController.h"
#import "RootView.h"
#import "WTDockButton.h"
#import "ChannelViewController.h"
#import "FavoriteViewController.h"
#import "NewsViewController.h"
#import "ScheduleViewController.h"
#import "MetroInfoReader.h"
#import "UIApplication+Addition.h"
#import "CoreDataViewController.h"
#import "NSUserDefaults+Addition.h"
#import "NSNotificationCenter+Addition.h"

#define BUTTON_WIDTH        70
#define BUTTON_HEIGHT       70

#define BUTTON_HORIZONTAL_INTERVAL  8
#define BUTTON_VERTICAL_INTERVAL    6
#define BUTTON_HORIZONTAL_OFFSET    8
#define BUTTON_VERTICAL_OFFSET      5

#define BUTTON_COUNT    24

#define SCROLL_VIEW_SHRINK_POS_Y    100
#define SCROLL_VIEW_SPREAD_POS_Y    100
#define SCROLL_HEADER_VIEW_HEIGHT   (460 - BUTTON_HEIGHT - BUTTON_VERTICAL_OFFSET - BUTTON_VERTICAL_INTERVAL)

#define SCROLL_HEADER_VIEW_MAX_ALPHA 0.5f

@interface MetroViewController ()

@property (nonatomic, strong) NSMutableArray *buttonHeap;
@property (readonly, nonatomic) CGFloat scrollViewHeight;
@property (nonatomic, getter = isShrink) BOOL shrink;
@property (nonatomic, getter = isShrinking) BOOL shrinking;
@property (nonatomic, strong) NSMutableArray *buttonInfoArray;
@property (nonatomic, strong) NSArray *metroInfoArray;

@end

@implementation MetroViewController

@synthesize scrollView = _scrollView;
@synthesize buttonHeap = _buttonHeap;
@synthesize scrollBackgroundView = _scrollBackgroundView;
@synthesize shrink = _shrink;
@synthesize shrinking = _shrinking;
@synthesize buttonInfoArray = _buttonInfoArray;
@synthesize metroInfoArray = _metroInfoArray;
@synthesize bgImageView = _bgImageView;
@synthesize shadowImageView = _shadowImageView;
@synthesize blackBgView = _blackBgView;
@synthesize appNameVersionLabel = _appNameVersionLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        MetroInfoReader *reader = [[MetroInfoReader alloc] init];
        NSArray *metroInfoArray = [reader getMetroInfoArray];
        self.metroInfoArray = metroInfoArray;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self configureMetroButton];
    [self configureScrollView];
    [self refreshScrollViewContentHeight];
    [self configureBgImageView];
    
    NSString *currentBundleVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    self.appNameVersionLabel.text = [NSString stringWithFormat:@"微同济 %@", currentBundleVersion];
    
    [NSNotificationCenter registerChangeCurrentUIStyleNotificationWithSelector:@selector(handleChangeCurrentUIStyleNotification:) target:self];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    self.scrollView = nil;
    self.scrollBackgroundView = nil;
    self.shadowImageView = nil;
}

#pragma mark -
#pragma mark UI methods

- (void)configureMetroButtonUIStyle {
    int index = 0;
    for(WTDockButton *button in self.buttonHeap) {
        [button configureUIStyle];
        if(index < self.metroInfoArray.count) {
            MetroInfo *info = [self.metroInfoArray objectAtIndex:index];
            UIStyle style = [NSUserDefaults getCurrentUIStyle];
            if(style == UIStyleBlackChocolate){
                [button setImage:[UIImage imageNamed:info.buttonImageFileName] forState:UIControlStateNormal];
            } else if(style == UIStyleWhiteChocolate) {
                NSString *whiteButtonImageFileName = info.buttonImageFileName;
                whiteButtonImageFileName = [NSString stringWithFormat:@"%@_white", whiteButtonImageFileName];
                [button setImage:[UIImage imageNamed:whiteButtonImageFileName] forState:UIControlStateNormal];
            }
        }
        index++;
    }
}

- (void)configureScrollView {
    CGRect frame = self.scrollBackgroundView.frame;
    frame.origin.y = SCROLL_HEADER_VIEW_HEIGHT;
    self.scrollBackgroundView.frame = frame;
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320.0f, SCROLL_HEADER_VIEW_HEIGHT)];
    headerView.tag = ROOT_METRO_SCROLL_HEADER_VIEW_TAG;
    headerView.backgroundColor = [UIColor clearColor];
    [self.scrollView addSubview:headerView];
    
    self.scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
}

- (void)configureBgImageView {
    UIStyle style = [NSUserDefaults getCurrentUIStyle];
    if(style == UIStyleBlackChocolate){
        self.bgImageView.image = [UIImage imageNamed:@"dock_bg.png"];
        self.shadowImageView.alpha = 0.7f;
    } else if(style == UIStyleWhiteChocolate) {
        self.bgImageView.image = [UIImage imageNamed:@"dock_bg_white.png"];
        self.shadowImageView.alpha = 0.4f;
    }
}

- (void)configureMetroButton {
    
    self.buttonHeap =  [[NSMutableArray alloc] init];
    for(int i = 0; i < BUTTON_COUNT; i++) {
        WTButton *button = nil;
        if(i < self.metroInfoArray.count) {
            MetroInfo *info = [self.metroInfoArray objectAtIndex:i];
            button = [[WTDockButton alloc] initWithImage:[UIImage imageNamed:info.buttonImageFileName] highlightedImage:[UIImage imageNamed:info.buttonHighlightImageFileName] title:info.buttonTitle];
            if(info.nibFileName)
                [button addTarget:self action:@selector(didClickMetroButton:) forControlEvents:UIControlEventTouchUpInside];
            else if(info.alertMessage)
                [button addTarget:self action:@selector(didTriggerAlertMessage:) forControlEvents:UIControlEventTouchUpInside];
        }
        else {
            button = [[WTDockButton alloc] initWithImage:nil highlightedImage:nil title:@""];
        }
        
        CGPoint center = button.center;
        int j = i % 4;
        int k = i / 4;
        
        center.x = BUTTON_HORIZONTAL_OFFSET + (BUTTON_HORIZONTAL_INTERVAL + BUTTON_WIDTH) * j + BUTTON_WIDTH / 2;
        center.y = BUTTON_VERTICAL_OFFSET + (BUTTON_VERTICAL_INTERVAL + BUTTON_HEIGHT) * k + SCROLL_HEADER_VIEW_HEIGHT + BUTTON_HEIGHT / 2;
        button.center = center;
        
        [self.scrollView addSubview:button];
        [self.buttonHeap addObject:button];
    }
    [self configureMetroButtonUIStyle];
}

- (void)refreshScrollViewContentHeight {
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, self.scrollViewHeight);
    CGRect frame = self.scrollBackgroundView.frame;
    frame.size.height = self.scrollViewHeight + 460.0f;
    self.scrollBackgroundView.frame = frame;
}

#pragma mark -
#pragma mark Animations

- (void)shrinkAnimation {
    [UIView animateWithDuration:0.2f animations:^{
        self.scrollView.contentOffset = CGPointMake(0, 0);
    } completion:^(BOOL finished) {
        self.shrinking = NO;
    }];
}

- (void)spreadAnimation {
    float duration = _willScrollViewDecelerate ? 0.1f : 0.2f;
    [UIView animateWithDuration:duration animations:^{
        self.scrollView.contentOffset = CGPointMake(0, SCROLL_HEADER_VIEW_HEIGHT);
    } completion:^(BOOL finished) {
        if(!self.scrollView.isDecelerating)
            self.shrinking = NO;
        self.scrollView.userInteractionEnabled = YES;
    }];
}

- (void)adjustScrollViewAnimation {
    if(!self.isShrink) {
        [self spreadAnimation];
    }
}

#pragma mark -
#pragma mark Properties 

- (CGFloat)scrollViewHeight {
    NSInteger k = self.buttonHeap.count / 4 + (self.buttonHeap.count % 4 == 0 ? 0 : 1);
    CGFloat result = BUTTON_VERTICAL_OFFSET + (BUTTON_HEIGHT + BUTTON_VERTICAL_INTERVAL) * k + SCROLL_HEADER_VIEW_HEIGHT;
    if(result < 460.0f + SCROLL_HEADER_VIEW_HEIGHT)
        result = 460.0f + SCROLL_HEADER_VIEW_HEIGHT;
//    CGFloat result = 460.0f + SCROLL_HEADER_VIEW_HEIGHT;
    return result;
}

- (void)setShrink:(BOOL)shrink {
    _shrink = shrink;
    self.shrinking = YES;
    
    if(shrink) {
        [self shrinkAnimation];
    }
    else {
        [self spreadAnimation];
    }
}

- (void)setShrinking:(BOOL)shrinking {
    _shrinking = shrinking;
    if(shrinking)
        self.scrollView.userInteractionEnabled = NO;
    else 
        self.scrollView.userInteractionEnabled = YES;
}

#pragma mark -
#pragma mark UIScrollView delegate 

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    _scrollViewStartTouch = YES;
    self.shrinking = NO;
    [self refreshScrollViewContentHeight];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat posY = scrollView.contentOffset.y;
    _isScrollingDownward = posY < _lastScrollContentOffsetY;
    _lastScrollContentOffsetY = posY;
    
    CGFloat alpha = posY / SCROLL_HEADER_VIEW_HEIGHT;
    alpha = alpha < 1 ? alpha : 1;
    alpha = alpha > 0 ? alpha : 0;
    alpha *= M_PI / 2;
    alpha = sinf(alpha) * SCROLL_HEADER_VIEW_MAX_ALPHA;
    self.blackBgView.alpha = alpha;
    
    if(posY > SCROLL_HEADER_VIEW_HEIGHT && !self.shrink && self.isShrinking && !_scrollViewStartTouch) {
        self.scrollView.contentOffset = CGPointMake(0, SCROLL_HEADER_VIEW_HEIGHT);
    }
    else if(posY < SCROLL_HEADER_VIEW_HEIGHT && !self.shrink && self.scrollView.isDecelerating && !_scrollViewStartTouch) {
        self.scrollView.contentOffset = CGPointMake(0, SCROLL_HEADER_VIEW_HEIGHT);
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    _willScrollViewDecelerate = decelerate;
    if(_lastScrollContentOffsetY < SCROLL_HEADER_VIEW_HEIGHT)
        self.shrink = _isScrollingDownward;
    _scrollViewStartTouch = NO;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    //[self adjustScrollViewAnimation];
    self.shrinking = NO;
}

- (void)didClickMetroButton:(UIButton *)sender {
    NSUInteger index = [self.buttonHeap indexOfObject:sender];
    MetroInfo *info = [self.metroInfoArray objectAtIndex:index];
    if(info.needLogin) {
        if([CoreDataViewController getCurrentUser] == nil) {
            [UIApplication showAlertMessage:@"该功能需要配合个人帐号才能使用，请登录微同济。" withTitle:@"出错啦"];
            return;
        }
    }
    UIViewController *vc = [[NSClassFromString(info.nibFileName) alloc] initWithNibName:info.nibFileName bundle:nil];
    if(vc) {
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [self presentModalViewController:nav animated:YES];
    }
}

- (void)didTriggerAlertMessage:(UIButton *)sender {
    NSUInteger index = [self.buttonHeap indexOfObject:sender];
    MetroInfo *info = [self.metroInfoArray objectAtIndex:index];
    [UIApplication showAlertMessage:info.alertMessage withTitle:@"即将推出"];

}

#pragma mark -
#pragma mark Handle notifications

- (void)handleChangeCurrentUIStyleNotification:(NSNotification *)notification {
    [self configureBgImageView];
    [self configureMetroButtonUIStyle];
}

@end
