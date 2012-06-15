//
//  ViewController.m
//  ShakeToPlay
//
//  Created by Marian PAUL on 11/03/12.
//  Copyright (c) 2012 IPuP SARL. All rights reserved.
//

#import "ViewController.h"

#define kAccelerometerFrequency         40  // fréquence (Hz) de mise à jour des données de l'accéléromètre
#define kFilteringFactor                0.1 // constante utilisée pour un filtre passe haut
#define kMinEraseInterval               0.5 // intervalle minimal en secondes entre deux échantillonnages pour déclencher la fonction "secouer"
#define kEraseAccelerationThreshold     2.0 // seuil d'accélération pour lequel on détecte la fonction "secouer"

@interface ViewController ()

@end

@implementation ViewController

- (void) registerForMediaPlayerNotifications // [2]
{
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(gerer_LelementJoueEnCoursAChange:) 
                                                 name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification 
                                               object:_musicPlayer]; // [3]
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(gerer_LetatPlayPauseAChange:) 
                                                 name:MPMusicPlayerControllerPlaybackStateDidChangeNotification 
                                               object:_musicPlayer];
    
    [_musicPlayer beginGeneratingPlaybackNotifications];
}

- (void)viewDidLoad {

    [super viewDidLoad];
    
    _playPauseButton.enabled = NO; // [4]
    
    // on initialise le music player
    _musicPlayer = [MPMusicPlayerController applicationMusicPlayer]; // [5]
    
    // on lance l'abonnement aux notifications 
    [self registerForMediaPlayerNotifications]; // [6]
    
    // on lance l'échantillonnage de l'accéléromètre
    [[UIAccelerometer sharedAccelerometer] setUpdateInterval:(1.0 / kAccelerometerFrequency)]; // [1]
    [[UIAccelerometer sharedAccelerometer] setDelegate:self];

    
}

#pragma mark - Button Methods

- (IBAction)pickItems:(id)sender 
{
    // initialisation et affichage du picker pour choisir la musique
    MPMediaPickerController *picker = [[MPMediaPickerController alloc] initWithMediaTypes: MPMediaTypeMusic]; // [7]
    
    picker.delegate = self;
    picker.allowsPickingMultipleItems = YES; // [8]
    picker.prompt = @"Choisir votre liste de lecture";
    
    [self presentModalViewController:picker animated:YES]; // [9]
}

- (IBAction)playPause:(id)sender
{    
    MPMusicPlaybackState playbackState = [_musicPlayer playbackState];
    
    if (playbackState == MPMusicPlaybackStateStopped || playbackState == MPMusicPlaybackStatePaused)
        [_musicPlayer play];
    else if (playbackState == MPMusicPlaybackStatePlaying)
        [_musicPlayer pause];
}

- (IBAction)changeToNext:(id)sender
{
    [_musicPlayer skipToNextItem];
}

- (IBAction)changeToPrevious:(id)sender 
{
    [_musicPlayer skipToPreviousItem];
}

#pragma mark - MPMediaPickerControllerDelegate methods

- (void)mediaPicker: (MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
{
    // on vient de choisir une chanson, on autorise le bouton play/pause
    _playPauseButton.enabled = YES;
    
    BOOL wasPlaying = ([_musicPlayer playbackState] == MPMusicPlaybackStatePlaying);
    
    [_musicPlayer setQueueWithItemCollection:mediaItemCollection];
    // on joue le morceau si on n'était pas en pause
    if (wasPlaying)
        [_musicPlayer play]; // [10]
    
    [self dismissModalViewControllerAnimated:YES]; // [11]
}

- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker
{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Gestionnaires notifications Musique

- (void) gerer_LelementJoueEnCoursAChange: (id) notification 
{
    // [12]
    
    MPMediaItem *currentItem = [_musicPlayer nowPlayingItem];    
    UIImage *artworkImage = nil;
    
    // On récupère l'image si elle existe
    MPMediaItemArtwork *artwork = [currentItem valueForProperty: MPMediaItemPropertyArtwork];
    
    // On la transforme en image si elle existe
    if (artwork)
        artworkImage = [artwork imageWithSize:_albumMediaArtwork.bounds.size];
    _albumMediaArtwork.image = artworkImage;
    
    // On affiche les informations du morceau en cours
    
    _titleSong.text = [currentItem valueForProperty: MPMediaItemPropertyTitle]; // [1]
    _artistName.text = [currentItem valueForProperty: MPMediaItemPropertyArtist]; // [2]
    _albumName.text = [currentItem valueForProperty: MPMediaItemPropertyAlbumTitle]; //[3]
    _rateSong.text = [NSString stringWithFormat:@"%d", [[currentItem valueForProperty: MPMediaItemPropertyRating] integerValue]]; // [4]
}

// Lorsque l'état du player change, on met à jour le bouton play/pause
- (void) gerer_LetatPlayPauseAChange: (id) notification 
{
    
    MPMusicPlaybackState playbackState = [_musicPlayer playbackState];
    
    _playPauseButton.enabled = (playbackState != MPMusicPlaybackStateStopped); // [13]
    [_playPauseButton setSelected:(playbackState == MPMusicPlaybackStatePlaying)]; // [14]
    
    if (playbackState == MPMusicPlaybackStateStopped) {
        // On désactive le bouton
        [_playPauseButton setEnabled:NO];    
        // on enlève l'image
        [_albumMediaArtwork setImage:nil];

        // Même si le lecteur était arrêté, on stoppe quand même pour être sûr de vider le buffer
        [_musicPlayer stop];
    }
}

#pragma mark - Accelerometer delegate method
- (void) accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration
{   
    UIAccelerationValue length,x,y,z; // ce sont les paramètres de notre accelerometre
    
    // On utilise un filtre passe-bas pour compenser l'influence de la gravité : on retrouve nos constantes déclarées plus haut dans les #define
    _myAccelerometer[0] = acceleration.x * kFilteringFactor + _myAccelerometer[0] * (1.0 - kFilteringFactor);
    _myAccelerometer[1] = acceleration.y * kFilteringFactor + _myAccelerometer[1] * (1.0 - kFilteringFactor);
    _myAccelerometer[2] = acceleration.z * kFilteringFactor + _myAccelerometer[2] * (1.0 - kFilteringFactor); // [1]
    
    // On calcule les valeurs pour nos 3 axes de l'accéléromètre (transformation en filtre passe haut simplifié)
    x = acceleration.x - _myAccelerometer[0];
    y = acceleration.y - _myAccelerometer[1];
    z = acceleration.z - _myAccelerometer[2]; // [2]
    
    // On calcule l'intensité de l'accéleration courante
    length = sqrt(x * x + y * y + z * z);
    
    // Si l'iphone est secoué, on fait quelque chose 
    // Pour utiliser l'accéléromètre, on scrute la différence de déplacement ou/et d'accélération entre deux instants donnés
    // La méthode CFAbsoluteTimeGetCurrent() permet d'obtenir la date de l'instant t2, qu'on compare a l'instant t1 stocké dans lastTime
    if((length >= kEraseAccelerationThreshold) && (CFAbsoluteTimeGetCurrent() > _lastTime + kMinEraseInterval)) // [3]
    {
        [self performSelector:@selector(playPause:) withObject:nil];
        // on met à jour le dernier moment où l'on a secoué
        _lastTime = CFAbsoluteTimeGetCurrent();
    }
}

- (void)dealloc 
{
    [_musicPlayer stop];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMusicPlayerControllerPlaybackStateDidChangeNotification object:nil];

}

- (void)viewDidUnload
{
    [super viewDidUnload];
    _playPauseButton = nil;
    _albumMediaArtwork = nil;
    _titleSong = nil;
    _albumName = nil; 
    _artistName = nil;
    _rateSong = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
