//
//  EmojiKeyBoardView.h
//  EmojiKeyBoard
//
//  Created by Ayush on 09/05/13.
//  Copyright (c) 2013 Ayush. All rights reserved.
//
// Set as inputView to textfields, this view class gives an
// interface to the user to enter emoji characters.

#import <UIKit/UIKit.h>

@protocol EmojiKeyboardViewDelegate;

@interface EmojiKeyBoardView : UIView

@property (nonatomic, weak) id<EmojiKeyboardViewDelegate> delegate;

@end

@protocol EmojiKeyboardViewDelegate <NSObject>

@optional
/**
 Delegate method called when user taps an emoji button
 @param emojiKeyBoardView EmojiKeyBoardView object on which user has tapped.
 @param emoji Emoji used by user
 */
- (void)emojiKeyBoardView:(EmojiKeyBoardView *)emojiKeyBoardView didUseEmoji:(NSString *)emoji;

/**
 Delegate method called when user taps on the backspace button
 @param emojiKeyBoardView EmojiKeyBoardView object on which user has tapped.
 */
- (void)emojiKeyBoardViewDidPressBackspaceButton;

@end
