//
//  ViewController.h
//  ShakeToPlay
//
//  Created by Marian PAUL on 11/03/12.
//  Copyright (c) 2012 iPuP SARL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@interface ViewController : UIViewController <MPMediaPickerControllerDelegate, UIAccelerometerDelegate> 
{
    MPMusicPlayerController *_musicPlayer;
    
    IBOutlet UIImageView *_albumMediaArtwork;
    IBOutlet UILabel *_titleSong, *_albumName, *_artistName, *_rateSong;
    IBOutlet UIButton *_playPauseButton;
    
    UIAccelerationValue _myAccelerometer[3];
    CFAbsoluteTime _lastTime;
}
- (void)registerForMediaPlayerNotifications;
- (IBAction)pickItems:(id)sender;
- (IBAction)playPause:(id)sender;
- (IBAction)changeToNext:(id)sender;
- (IBAction)changeToPrevious:(id)sender;

@end
