//
//  EmojiPageView.h
//  EmojiKeyBoard
//
//  Created by Ayush on 09/05/13.
//  Copyright (c) 2013 Ayush. All rights reserved.
//

#import <UIKit/UIKit.h>

#define BUTTON_FONT_SIZE 32

@protocol EmojiPageViewDelegate;

@interface EmojiPageView : UIView

@property (nonatomic, weak) id<EmojiPageViewDelegate> delegate;

/**
 Creates and returns an EmojiPageView

 @param buttonsSize Size for the button representing a single emoji
 @param rows Number of rows in a single EmojiPageView
 @param columns Number of columns in a single EmojiPageView. Also represents the number of emojis shown in a row.

 @return An instance of EmojiPageView
 */
- (id)initWithFrame:(CGRect)frame emojiSize:(CGSize)emojiSize rows:(NSUInteger)rows columns:(NSUInteger)columns;

/**
 Sets texts on buttons in the EmojiPageView.

 @param buttonTexts An array of texts to be set on buttons in EmojiPageView
 */
- (void)setEmojiTexts:(NSMutableArray *)emojiTexts;

@end

@protocol EmojiPageViewDelegate <NSObject>

@optional
/**
 Delegate method called when user taps an emoji button
 @param emojiPageView EmojiPageView object on which user has tapped.
 @param emoji Emoji pressed by user
 */
- (void)emojiPageView:(EmojiPageView *)emojiPageView didUseEmoji:(NSString *)emoji;

/**
 Delegate method called when user taps on the backspace button
 @param emojiPageView EmojiPageView object on which user has tapped.
 */
- (void)emojiPageViewDidPressBackSpace:(EmojiPageView *)emojiPageView;

- (void)emojiEnablePopup:(UILabel *)emoji;
- (void)emojiDisablePopup:(UILabel *)emoji;

@end