//
//  EmojiPageView.m
//  EmojiKeyBoard
//
//  Created by Ayush on 09/05/13.
//  Copyright (c) 2013 Ayush. All rights reserved.
//

#import "EmojiPageView.h"

@interface EmojiPageView ()

@property (nonatomic, assign) CGSize emojiSize;
@property (nonatomic, assign) NSUInteger columns;
@property (nonatomic, assign) NSUInteger rows;
@property (nonatomic, strong) NSMutableArray *emojis;

@property (nonatomic, strong) UILabel *previousEmoji;

@end

@implementation EmojiPageView
@synthesize emojiSize = emojiSize_;
@synthesize emojis = emojis_;
@synthesize columns = columns_;
@synthesize rows = rows_;
@synthesize delegate = delegate_;

- (void)setEmojiTexts:(NSMutableArray *)emojiTexts {
    if ([self.emojis count] == [emojiTexts count]) {
        for (NSUInteger i = 0; i < [emojiTexts count]; ++i) {
            UILabel *emoji = self.emojis[i];
            emoji.text = emojiTexts[i];
        }
    } else {
        [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        self.emojis = nil;
        self.emojis = [NSMutableArray arrayWithCapacity:self.rows * self.columns];
        for (NSUInteger i = 0; i < [emojiTexts count]; ++i) {
            UILabel *emoji = [self createEmojiAtIndex:i];
            emoji.text = emojiTexts[i];
            [self addToEmojiPageView:emoji];
        }
    }
}


- (void)addToEmojiPageView:(UIView *)emoji {
    [self.emojis addObject:emoji];
    [self addSubview:emoji];
}

// Padding is the expected space between two buttons.
// Thus, space of top button = padding / 2
// extra padding according to particular button's pos = pos * padding
// Margin includes, size of buttons in between = pos * buttonSize
// Thus, margin = padding / 2
//                + pos * padding
//                + pos * buttonSize

- (CGFloat)XMarginForEmojiInColumn:(NSInteger)column
{
    CGFloat padding = ((CGRectGetWidth(self.bounds) - self.columns * self.emojiSize.width) / self.columns);
    return (padding / 2 + column * (padding + self.emojiSize.width));
}

- (CGFloat)YMarginForEmojiInRow:(NSInteger)rowNumber
{
    CGFloat padding = ((CGRectGetHeight(self.bounds) - self.rows * self.emojiSize.height) / self.rows);
    return (padding / 2 + rowNumber * (padding + self.emojiSize.height));
}

- (UILabel *)createEmojiAtIndex:(NSUInteger)index
{
    UILabel *emoji = [[UILabel alloc] initWithFrame:CGRectZero];
    emoji.userInteractionEnabled = NO;
    emoji.font = [UIFont fontWithName:@"Apple color emoji" size:BUTTON_FONT_SIZE];
    emoji.backgroundColor = [UIColor clearColor];
    emoji.textAlignment = NSTextAlignmentCenter;
    NSInteger row = (NSInteger)(index / self.columns);
    NSInteger column = (NSInteger)(index % self.columns);
    emoji.frame = CGRectIntegral(CGRectMake([self XMarginForEmojiInColumn:column],
                                             [self YMarginForEmojiInRow:row],
                                             self.emojiSize.width,
                                             self.emojiSize.height));
    return emoji;
}

- (UILabel *)emojiForPointInEmojiPageView:(CGPoint)point
{
    UILabel *emojiToFind = nil;
    for (UILabel *emoji in self.emojis) {
        CGPoint nativePoint = [emoji convertPoint:point fromView:self];
        if ([emoji pointInside:nativePoint withEvent:nil]) {
            emojiToFind = emoji;
            break;
        }
    }
    return emojiToFind;
}

- (id)initWithFrame:(CGRect)frame emojiSize:(CGSize)emojiSize rows:(NSUInteger)rows columns:(NSUInteger)columns
{
    self = [super initWithFrame:frame];
    if (self) {
        self.emojiSize = emojiSize;
        self.columns = columns;
        self.rows = rows;
        self.emojis = [[NSMutableArray alloc] initWithCapacity:rows * columns];
        UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(emojiViewLongPress:)];
        longPressGestureRecognizer.minimumPressDuration = 0.04f;
        [self addGestureRecognizer:longPressGestureRecognizer];
        self.previousEmoji = nil;
    }
    return self;
}


- (void)emojiViewLongPress:(UILongPressGestureRecognizer *)longGestureRecognizer
{
    UIGestureRecognizerState state = longGestureRecognizer.state;
    if (state == UIGestureRecognizerStateChanged ||
        state == UIGestureRecognizerStateBegan) {
        CGPoint touchedLocation = [longGestureRecognizer locationInView:self];
        UILabel *emoji = [self emojiForPointInEmojiPageView:touchedLocation];
        if (!emoji) {
            if (self.previousEmoji) {
                [self.delegate emojiDisablePopup:self.previousEmoji];
            }
            return;
        }
        if (self.previousEmoji && self.previousEmoji != emoji) {
            [self.delegate emojiDisablePopup:self.previousEmoji];
        }
        self.previousEmoji = emoji;
        if ([self.delegate respondsToSelector:@selector(emojiEnablePopup:)]) {
            [self.delegate emojiEnablePopup:emoji];
        }
    } else if (state == UIGestureRecognizerStateEnded) {
        if (self.previousEmoji) {
            [self.delegate emojiDisablePopup:self.previousEmoji];
            [self.delegate emojiPageView:self didUseEmoji:self.previousEmoji.text];
        }
    }
}

@end
