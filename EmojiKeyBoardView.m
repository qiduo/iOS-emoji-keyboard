//
//  EmojiKeyBoardView.m
//  EmojiKeyBoard
//
//  Created by Ayush on 09/05/13.
//  Copyright (c) 2013 Ayush. All rights reserved.
//

#import "EmojiKeyBoardView.h"
#import "EmojiPageView.h"
#import "DDPageControl.h"

#define BUTTON_WIDTH 45
#define BUTTON_HEIGHT 37
#define HighlightedEmojiViewHeight 108.f
#define HighlightedEmojiViewWidth  76.f
#define BackspaceButtonWidth       45.f

#define DEFAULT_SELECTED_SEGMENT 0
#define PAGE_CONTROL_INDICATOR_DIAMETER 6.0
#define RECENT_EMOJIS_MAINTAINED_COUNT 40

#define BACKGROUND_COLOR 0xECECEC

static NSString *const segmentRecentName = @"Recent";
NSString *const RecentUsedEmojiCharactersKey = @"RecentUsedEmojiCharactersKey";


@interface QDPopupEmojiView : UIView

@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UILabel *popupEmoji;

@end

@implementation QDPopupEmojiView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.backgroundImageView.image = [UIImage imageNamed:@"bg-emoji-popup"];
        self.popupEmoji = [[UILabel alloc] initWithFrame:CGRectZero];
        self.popupEmoji.backgroundColor = [UIColor clearColor];
        self.popupEmoji.textAlignment = NSTextAlignmentCenter;
        self.popupEmoji.font = [UIFont fontWithName:@"Apple color emoji" size:BUTTON_FONT_SIZE];
        [self addSubview:self.backgroundImageView];
        [self addSubview:self.popupEmoji];
    }
    return self;
}

- (void)layoutSubviews
{
    self.backgroundImageView.frame = self.bounds;
    CGFloat xOffset = (self.bounds.size.width - BUTTON_WIDTH) * 0.5f;
    self.popupEmoji.frame = CGRectMake(xOffset, 18.f, BUTTON_WIDTH, BUTTON_HEIGHT);
}

@end

@implementation UIColor (TDTAdditions)

+ (UIColor *)colorWithIntegerValue:(NSUInteger)value alpha:(CGFloat)alpha {
    NSUInteger mask = 255;
    NSUInteger blueValue = value & mask;
    value >>= 8;
    NSUInteger greenValue = value & mask;
    value >>= 8;
    NSUInteger redValue = value & mask;
    return [UIColor colorWithRed:(CGFloat)(redValue / 255.0) green:(CGFloat)(greenValue / 255.0) blue:(CGFloat)(blueValue / 255.0) alpha:alpha];
}

@end


@interface EmojiKeyBoardView () <UIScrollViewDelegate, EmojiPageViewDelegate>

@property (nonatomic, strong) UISegmentedControl *segmentsBar;
@property (nonatomic, strong) UIButton *backspaceButton;
@property (nonatomic, strong) DDPageControl *pageControl;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSDictionary *emojis;
@property (nonatomic, strong) NSMutableArray *pageViews;
@property (nonatomic, strong) NSString *category;

@property (nonatomic, strong) QDPopupEmojiView *popupEmojiView;

@property (nonatomic, strong) UILabel *testLabel;

@end

@implementation EmojiKeyBoardView
@synthesize delegate = delegate_;
@synthesize segmentsBar = segmentsBar_;
@synthesize pageControl = pageControl_;
@synthesize scrollView = scrollView_;
@synthesize emojis = emojis_;
@synthesize pageViews = pageViews_;
@synthesize category = category_;

- (NSDictionary *)emojis {
    if (!emojis_) {
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"EmojisList"
                                                          ofType:@"plist"];
        emojis_ = [[NSDictionary dictionaryWithContentsOfFile:plistPath] copy];
    }
    return emojis_;
}

- (NSMutableArray *)recentEmojis {
    NSArray *emojis = [[NSUserDefaults standardUserDefaults] arrayForKey:RecentUsedEmojiCharactersKey];
    NSMutableArray *recentEmojis = [emojis mutableCopy];
    if (recentEmojis == nil) {
        recentEmojis = [NSMutableArray array];
    }
    return recentEmojis;
}

- (void)setRecentEmojis:(NSMutableArray *)recentEmojis {
    if ([recentEmojis count] > RECENT_EMOJIS_MAINTAINED_COUNT) {
        NSIndexSet *indexesToBeRemoved = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(RECENT_EMOJIS_MAINTAINED_COUNT, [recentEmojis count] - RECENT_EMOJIS_MAINTAINED_COUNT)];
        [recentEmojis removeObjectsAtIndexes:indexesToBeRemoved];
    }
    [[NSUserDefaults standardUserDefaults] setObject:recentEmojis forKey:RecentUsedEmojiCharactersKey];
}

- (BOOL)enableInputClicksWhenVisible
{
    return YES;
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.category = segmentRecentName;
        self.backgroundColor = [UIColor colorWithIntegerValue:BACKGROUND_COLOR alpha:1.0];
        self.segmentsBar = [[UISegmentedControl alloc] initWithItems:@[
                                                                       [UIImage imageNamed:@"btn-recent-normal"],
                                                                       [UIImage imageNamed:@"btn-face-normal"],
                                                                       [UIImage imageNamed:@"btn-bell-normal"],
                                                                       [UIImage imageNamed:@"btn-flower-normal"],
                                                                       [UIImage imageNamed:@"btn-car-normal"],
                                                                       [UIImage imageNamed:@"btn-characters-normal"],
                                                                       ]];
        
        CGRect segmentsBarFrame = CGRectMake(0, 0, CGRectGetWidth(self.bounds) - BackspaceButtonWidth, CGRectGetHeight(self.segmentsBar.bounds));
        self.segmentsBar.frame = segmentsBarFrame;
        self.segmentsBar.segmentedControlStyle = UISegmentedControlStyleBar;
        self.segmentsBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;

        [self.segmentsBar setDividerImage:[UIImage imageNamed:@"bg-icons-separator"] forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        [self.segmentsBar setDividerImage:[UIImage imageNamed:@"bg-corner-left"] forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
        [self.segmentsBar setDividerImage:[UIImage imageNamed:@"bg-corner-right"] forLeftSegmentState:UIControlStateSelected rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        [self.segmentsBar setBackgroundImage:[UIImage imageNamed:@"bg-unselected-center"] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        [self.segmentsBar setBackgroundImage:[UIImage imageNamed:@"bg-tab"] forState:UIControlStateSelected barMetrics:UIBarMetricsDefault];

        
        [self.segmentsBar addTarget:self action:@selector(categoryChangedViaSegmentsBar:) forControlEvents:UIControlEventValueChanged];
        [self setSelectedCategoryImageInSegmentControl:self.segmentsBar AtIndex:DEFAULT_SELECTED_SEGMENT];
        self.segmentsBar.selectedSegmentIndex = DEFAULT_SELECTED_SEGMENT;
        [self addSubview:self.segmentsBar];
        
        self.backspaceButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.backspaceButton.frame = CGRectMake(segmentsBarFrame.origin.x + segmentsBarFrame.size.width, 0.f, BackspaceButtonWidth, segmentsBarFrame.size.height);
        [self.backspaceButton addTarget:self action:@selector(backspaceButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self.backspaceButton setBackgroundImage:[UIImage imageNamed:@"btn-backspace-normal"] forState:UIControlStateNormal];
        [self.backspaceButton setBackgroundImage:[UIImage imageNamed:@"btn-backspace-highlighted"] forState:UIControlStateHighlighted];
        
        [self addSubview:self.backspaceButton];

        self.pageControl = [[DDPageControl alloc] initWithType:DDPageControlTypeOnFullOffFull];
        self.pageControl.onColor = [UIColor darkGrayColor];
        self.pageControl.offColor = [UIColor lightGrayColor];
        self.pageControl.indicatorDiameter = PAGE_CONTROL_INDICATOR_DIAMETER;
        self.pageControl.hidesForSinglePage = NO;
        self.pageControl.currentPage = 0;
        self.pageControl.backgroundColor = [UIColor clearColor];
        CGSize pageControlSize = [self.pageControl sizeForNumberOfPages:3];
        NSUInteger numberOfPages = [self numberOfPagesForCategory:self.category
                                                      inFrameSize:CGSizeMake(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds) - CGRectGetHeight(self.segmentsBar.bounds) - pageControlSize.height)];
        self.pageControl.numberOfPages = numberOfPages;
        pageControlSize = [self.pageControl sizeForNumberOfPages:numberOfPages];
        self.pageControl.frame = CGRectIntegral(CGRectMake((CGRectGetWidth(self.bounds) - pageControlSize.width) / 2,
                                                       CGRectGetHeight(self.bounds) - pageControlSize.height,
                                                       pageControlSize.width,
                                                       pageControlSize.height));
        [self.pageControl addTarget:self action:@selector(pageControlTouched:) forControlEvents:UIControlEventValueChanged];
        [self addSubview:self.pageControl];

        self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.segmentsBar.bounds), CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds) - CGRectGetHeight(self.segmentsBar.bounds) - pageControlSize.height)];
        
        self.scrollView.pagingEnabled = YES;
        self.scrollView.showsHorizontalScrollIndicator = NO;
        self.scrollView.showsVerticalScrollIndicator = NO;
        self.scrollView.delegate = self;
        
        [self addSubview:self.scrollView];
        
        self.popupEmojiView = [[QDPopupEmojiView alloc] initWithFrame:CGRectMake(0.f, 90.f, HighlightedEmojiViewWidth, HighlightedEmojiViewHeight)];
        self.popupEmojiView.hidden = YES;
        [self addSubview:self.popupEmojiView];
    }
    return self;
}

- (void)dealloc
{
    self.pageControl = nil;
    self.scrollView = nil;
    self.segmentsBar = nil;
    self.category = nil;
    self.emojis = nil;
    [self purgePageViews];
}

- (void)backspaceButtonPressed:(UIButton *)sender
{
    [[UIDevice currentDevice] playInputClick];
    if ([self.delegate respondsToSelector:@selector(emojiKeyBoardViewDidPressBackspaceButton)]) {
        [self.delegate emojiKeyBoardViewDidPressBackspaceButton];
    }
}

- (void)layoutSubviews
{
    CGRect segmentsBarFrame = self.segmentsBar.frame;
    self.backspaceButton.frame = CGRectMake(segmentsBarFrame.origin.x + segmentsBarFrame.size.width, 0.f, BackspaceButtonWidth, segmentsBarFrame.size.height);
    
    CGSize pageControlSize = [self.pageControl sizeForNumberOfPages:3];
    NSUInteger numberOfPages = [self numberOfPagesForCategory:self.category
                                                inFrameSize:CGSizeMake(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds) - CGRectGetHeight(self.segmentsBar.bounds) - pageControlSize.height)];

    NSInteger currentPage = (self.pageControl.currentPage > numberOfPages) ? numberOfPages : self.pageControl.currentPage;

    self.pageControl.numberOfPages = numberOfPages;
    pageControlSize = [self.pageControl sizeForNumberOfPages:numberOfPages];
    self.pageControl.frame = CGRectIntegral(CGRectMake((CGRectGetWidth(self.bounds) - pageControlSize.width) / 2,
                                                     CGRectGetHeight(self.bounds) - pageControlSize.height,
                                                     pageControlSize.width,
                                                     pageControlSize.height));
    
    self.scrollView.frame = CGRectMake(0,
                                     CGRectGetHeight(self.segmentsBar.bounds),
                                     CGRectGetWidth(self.bounds),
                                     CGRectGetHeight(self.bounds) - CGRectGetHeight(self.segmentsBar.bounds) - pageControlSize.height);
    [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.scrollView.contentOffset = CGPointMake(CGRectGetWidth(self.scrollView.bounds) * currentPage, 0);
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.scrollView.bounds) * numberOfPages, CGRectGetHeight(self.scrollView.bounds));
    [self purgePageViews];
    self.pageViews = [NSMutableArray array];
    [self setPage:currentPage];
}

#pragma mark event handlers

- (void)setSelectedCategoryImageInSegmentControl:(UISegmentedControl *)segmentsBar AtIndex:(NSInteger)index {
    NSArray *imagesForSelectedSegments = @[[UIImage imageNamed:@"btn-recent-highlighted"],
                                           [UIImage imageNamed:@"btn-face-highlighted"],
                                           [UIImage imageNamed:@"btn-bell-highlighted"],
                                           [UIImage imageNamed:@"btn-flower-highlighted"],
                                           [UIImage imageNamed:@"btn-car-highlighted"],
                                           [UIImage imageNamed:@"btn-characters-highlighted"],
                                           ];
    NSArray *imagesForNonSelectedSegments = @[[UIImage imageNamed:@"btn-recent-normal"],
                                              [UIImage imageNamed:@"btn-face-normal"],
                                              [UIImage imageNamed:@"btn-bell-normal"],
                                              [UIImage imageNamed:@"btn-flower-normal"],
                                              [UIImage imageNamed:@"btn-car-normal"],
                                              [UIImage imageNamed:@"btn-characters-normal"],
                                              ];
    for (int i = 0; i < self.segmentsBar.numberOfSegments; ++i) {
        [segmentsBar setImage:imagesForNonSelectedSegments[i] forSegmentAtIndex:i];
    }
    [segmentsBar setImage:imagesForSelectedSegments[index] forSegmentAtIndex:index];
}

- (void)categoryChangedViaSegmentsBar:(UISegmentedControl *)sender {
    
    [[UIDevice currentDevice] playInputClick];
    
    NSArray *categoryList = @[segmentRecentName, @"People", @"Objects", @"Nature", @"Places", @"Symbols"];
    
    self.category = categoryList[sender.selectedSegmentIndex];
    [self setSelectedCategoryImageInSegmentControl:sender AtIndex:sender.selectedSegmentIndex];
    
    self.pageControl.currentPage = 0;
    // This triggers layoutSubviews
    // Choose a number that can never be equal to numberOfPages of pagecontrol else
    // layoutSubviews would not be called
    self.pageControl.numberOfPages = 100;
}

- (void)pageControlTouched:(DDPageControl *)sender {
    CGRect bounds = self.scrollView.bounds;
    bounds.origin.x = CGRectGetWidth(bounds) * sender.currentPage;
    bounds.origin.y = 0;
    // scrollViewDidScroll is called here. Page set at that time.
    [self.scrollView scrollRectToVisible:bounds animated:YES];
}

// Track the contentOffset of the scroll view, and when it passes the mid
// point of the current view’s width, the views are reconfigured.
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat pageWidth = CGRectGetWidth(scrollView.frame);
    NSInteger newPageNumber = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    if (self.pageControl.currentPage == newPageNumber) {
        return;
    }
    self.pageControl.currentPage = newPageNumber;
    [self setPage:self.pageControl.currentPage];
}

#pragma mark change a page on scrollView

// Check if setting pageView for an index is required
- (BOOL)requireToSetPageViewForIndex:(NSUInteger)index {
    if (index >= self.pageControl.numberOfPages) {
        return NO;
    }
    for (EmojiPageView *page in self.pageViews) {
        if ((page.frame.origin.x / CGRectGetWidth(self.scrollView.bounds)) == index) {
            return NO;
        }
    }
    return YES;
}

// Create a pageView and add it to the scroll view.
- (EmojiPageView *)synthesizeEmojiPageView {
    NSUInteger rows = [self numberOfRowsForFrameSize:self.scrollView.bounds.size];
    NSUInteger columns = [self numberOfColumnsForFrameSize:self.scrollView.bounds.size];
    EmojiPageView *pageView = [[EmojiPageView alloc] initWithFrame:
                               CGRectMake(0, 0, CGRectGetWidth(self.scrollView.bounds), CGRectGetHeight(self.scrollView.bounds)) emojiSize:CGSizeMake(BUTTON_WIDTH, BUTTON_HEIGHT) rows:rows columns:columns];
    pageView.delegate = self;
    [self.pageViews addObject:pageView];
    [self.scrollView addSubview:pageView];
    return pageView;
}

// return a pageView that can be used in the current scrollView.
// look for an available pageView in current pageView-s on scrollView.
// If all are in use i.e. are of current page or neighbours
// of current page, we create a new one

- (EmojiPageView *)usableEmojiPageView {
    EmojiPageView *pageView = nil;
    for (EmojiPageView *page in self.pageViews) {
        NSUInteger pageNumber = page.frame.origin.x / CGRectGetWidth(self.scrollView.bounds);
        if (abs(pageNumber - self.pageControl.currentPage) > 1) {
            pageView = page;
            break;
        }
    }
    if (!pageView) {
        pageView = [self synthesizeEmojiPageView];
    }
    return pageView;
}


- (void)setEmojiPageViewInScrollView:(UIScrollView *)scrollView atIndex:(NSUInteger)index
{
    if (![self requireToSetPageViewForIndex:index]) {
        return;
    }

    EmojiPageView *pageView = [self usableEmojiPageView];

    NSUInteger numberOfEmojisPerPage = [self numberOfEmojisPerPage:scrollView.bounds.size];
    NSUInteger startingIndex = index * numberOfEmojisPerPage;
    NSUInteger endingIndex = startingIndex + numberOfEmojisPerPage;
    NSMutableArray *emojiTexts = [self emojiTextsForCategory:self.category
                                                  fromIndex:startingIndex
                                                    toIndex:endingIndex];
    [pageView setEmojiTexts:emojiTexts];
    pageView.frame = CGRectMake(index * CGRectGetWidth(scrollView.bounds), 0, CGRectGetWidth(scrollView.bounds), CGRectGetHeight(scrollView.bounds));
}

- (NSUInteger)numberOfEmojisPerPage:(CGSize)frameSize
{
    NSUInteger numberOfRows = [self numberOfRowsForFrameSize:frameSize];
    NSUInteger numberOfColums = [self numberOfColumnsForFrameSize:frameSize];
    return numberOfColums * numberOfRows;
}

- (void)setPage:(NSInteger)page
{
    [self setEmojiPageViewInScrollView:self.scrollView atIndex:page - 1];
    [self setEmojiPageViewInScrollView:self.scrollView atIndex:page];
    [self setEmojiPageViewInScrollView:self.scrollView atIndex:page + 1];
}

- (void)purgePageViews
{
    for (EmojiPageView *page in self.pageViews) {
        page.delegate = nil;
    }
    self.pageViews = nil;
}

#pragma mark data methods

- (NSUInteger)numberOfColumnsForFrameSize:(CGSize)frameSize
{
    return (NSUInteger)floor(frameSize.width / BUTTON_WIDTH);
}

- (NSUInteger)numberOfRowsForFrameSize:(CGSize)frameSize
{
    return (NSUInteger)floor(frameSize.height / BUTTON_HEIGHT);
}

- (NSArray *)emojiListForCategory:(NSString *)category
{
    if ([category isEqualToString:segmentRecentName]) {
        return [self recentEmojis];
    }
    return [self.emojis objectForKey:category];
}


- (NSUInteger)numberOfPagesForCategory:(NSString *)category inFrameSize:(CGSize)frameSize
{
    NSUInteger emojiCount = [[self emojiListForCategory:category] count];
    NSUInteger numberOfEmojisOnAPage = [self numberOfEmojisPerPage:frameSize];

    NSUInteger numberOfPages = (NSUInteger)ceil((float)emojiCount / numberOfEmojisOnAPage);
    return numberOfPages;
}

// return the emojis for a category, given a staring and an ending index
- (NSMutableArray *)emojiTextsForCategory:(NSString *)category fromIndex:(NSUInteger)start toIndex:(NSUInteger)end {
    NSArray *emojis = [self emojiListForCategory:category];
    end = ([emojis count] > end)? end : [emojis count];
    NSIndexSet *index = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(start, end-start)];
    return [[emojis objectsAtIndexes:index] mutableCopy];
}

#pragma mark EmojiPageViewDelegate

- (void)setInRecentsEmoji:(NSString *)emoji {
    NSMutableArray *recentEmojis = [self recentEmojis];
    for (int i = 0; i < [recentEmojis count]; ++i) {
        if ([recentEmojis[i] isEqualToString:emoji]) {
            [recentEmojis removeObjectAtIndex:i];
        }
    }
    [recentEmojis insertObject:emoji atIndex:0];
    [self setRecentEmojis:recentEmojis];
}


- (void)emojiPageView:(EmojiPageView *)emojiPageView didUseEmoji:(NSString *)emoji
{
    [self setInRecentsEmoji:emoji];
    [[UIDevice currentDevice] playInputClick];
    [self.delegate emojiKeyBoardView:self didUseEmoji:emoji];
}

- (void)emojiEnablePopup:(UILabel *)emoji
{
    emoji.hidden = YES;
    CGPoint origin = emoji.frame.origin;
    CGRect emojiFrame = self.popupEmojiView.frame;
    emojiFrame.origin.x = origin.x - (HighlightedEmojiViewWidth - BUTTON_WIDTH) * 0.5f;
    emojiFrame.origin.y = origin.y + 2 * BUTTON_HEIGHT - HighlightedEmojiViewHeight;
    self.popupEmojiView.hidden = NO;
    self.popupEmojiView.frame = emojiFrame;
    self.popupEmojiView.popupEmoji.text = emoji.text;
}

- (void)emojiDisablePopup:(UILabel *)emoji
{
    emoji.hidden = NO;
    self.popupEmojiView.hidden = YES;
}

@end
