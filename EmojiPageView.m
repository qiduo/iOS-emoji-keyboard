//
//  EmojiPageView.m
//  EmojiKeyBoard
//
//  Created by Ayush on 09/05/13.
//  Copyright (c) 2013 Ayush. All rights reserved.
//

#import "EmojiPageView.h"

@interface EmojiPageView ()

@property (nonatomic, assign) CGSize buttonSize;
@property (nonatomic, assign) NSUInteger columns;
@property (nonatomic, assign) NSUInteger rows;
@property (nonatomic, strong) NSMutableArray *buttons;

@property (nonatomic, assign) NSInteger previousPopupEmojiIndex;

@end

@implementation EmojiPageView
@synthesize buttonSize = buttonSize_;
@synthesize buttons = buttons_;
@synthesize columns = columns_;
@synthesize rows = rows_;
@synthesize delegate = delegate_;

- (void)setButtonTexts:(NSMutableArray *)buttonTexts {
    if (([self.buttons count] - 1) == [buttonTexts count]) {
        for (NSUInteger i = 0; i < [buttonTexts count]; ++i) {
            [self.buttons[i] setTitle:buttonTexts[i] forState:UIControlStateNormal];
        }
    } else {
        [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        self.buttons = nil;
        self.buttons = [NSMutableArray arrayWithCapacity:self.rows * self.columns];
        for (NSUInteger i = 0; i < [buttonTexts count]; ++i) {
            UIButton *button = [self createButtonAtIndex:i];
            [button setTitle:buttonTexts[i] forState:UIControlStateNormal];
            [self addToViewButton:button];
        }
    }
}


- (void)addToViewButton:(UIButton *)button {

  NSAssert(button != nil, @"Button to be added is nil");

  [self.buttons addObject:button];
  [self addSubview:button];
}

// Padding is the expected space between two buttons.
// Thus, space of top button = padding / 2
// extra padding according to particular button's pos = pos * padding
// Margin includes, size of buttons in between = pos * buttonSize
// Thus, margin = padding / 2
//                + pos * padding
//                + pos * buttonSize

- (CGFloat)XMarginForButtonInColumn:(NSInteger)column
{
    CGFloat padding = ((CGRectGetWidth(self.bounds) - self.columns * self.buttonSize.width) / self.columns);
    return (padding / 2 + column * (padding + self.buttonSize.width));
}

- (CGFloat)YMarginForButtonInRow:(NSInteger)rowNumber
{
    CGFloat padding = ((CGRectGetHeight(self.bounds) - self.rows * self.buttonSize.height) / self.rows);
    return (padding / 2 + rowNumber * (padding + self.buttonSize.height));
}

- (UIButton *)createButtonAtIndex:(NSUInteger)index
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.titleLabel.font = [UIFont fontWithName:@"Apple color emoji" size:BUTTON_FONT_SIZE];
    NSInteger row = (NSInteger)(index / self.columns);
    NSInteger column = (NSInteger)(index % self.columns);
    button.frame = CGRectIntegral(CGRectMake([self XMarginForButtonInColumn:column],
                                             [self YMarginForButtonInRow:row],
                                             self.buttonSize.width,
                                             self.buttonSize.height));
    return button;
}

- (UIButton *)emojiForPointInEmojiView:(CGPoint)point
{
    UIButton *emoji = nil;
    for (UIButton *button in self.buttons) {
        CGPoint nativePoint = [button convertPoint:point fromView:self];
        if ([button pointInside:nativePoint withEvent:nil]) {
            emoji = button;
            break;
        }
    }
    return emoji;
}

- (id)initWithFrame:(CGRect)frame buttonSize:(CGSize)buttonSize rows:(NSUInteger)rows columns:(NSUInteger)columns
{
    self = [super initWithFrame:frame];
    if (self) {
        self.buttonSize = buttonSize;
        self.columns = columns;
        self.rows = rows;
        self.buttons = [[NSMutableArray alloc] initWithCapacity:rows * columns];
        UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(emojiViewLongPress:)];
        longPressGestureRecognizer.minimumPressDuration = 0.08f;
        [self addGestureRecognizer:longPressGestureRecognizer];
        self.previousPopupEmojiIndex = -1;
    }
    return self;
}


- (void)emojiViewLongPress:(UILongPressGestureRecognizer *)longGestureRecognizer
{
    if (longGestureRecognizer.state == UIGestureRecognizerStateChanged ||
        longGestureRecognizer.state == UIGestureRecognizerStateBegan) {
        NSLog(@"state...change... or begin...");
        CGPoint touchedLocation = [longGestureRecognizer locationInView:self];
        UIButton *emoji = [self emojiForPointInEmojiView:touchedLocation];
        if (!emoji) {
            if (self.previousPopupEmojiIndex >= 0) {
                [self.delegate emojiDisablePopup:[self.buttons objectAtIndex:self.previousPopupEmojiIndex]];
            }
            return;
        }
        NSInteger currentEmojiIndex = [self.buttons indexOfObject:emoji];
        NSLog(@"in here, current index: %i", currentEmojiIndex);
        if (self.previousPopupEmojiIndex >= 0 && currentEmojiIndex != self.previousPopupEmojiIndex &&
            [self.delegate respondsToSelector:@selector(emojiDisablePopup:)]) {
            [self.delegate emojiDisablePopup:[self.buttons objectAtIndex:self.previousPopupEmojiIndex]];
        }
        self.previousPopupEmojiIndex = currentEmojiIndex;
        if ([self.delegate respondsToSelector:@selector(emojiEnablePopup:)]) {
            [self.delegate emojiEnablePopup:emoji];
        }
        NSLog(@"enable...");
    }
    if (longGestureRecognizer.state == UIGestureRecognizerStateEnded ||
        longGestureRecognizer.state == UIGestureRecognizerStateCancelled) {
        NSLog(@"....state end..");
        if (self.previousPopupEmojiIndex >= 0) {
            UIButton *previousEmoji = [self.buttons objectAtIndex:self.previousPopupEmojiIndex];
            [self.delegate emojiDisablePopup:previousEmoji];
            [self.delegate emojiPageView:self didUseEmoji:previousEmoji.titleLabel.text];
        }
    }
    
}

@end
