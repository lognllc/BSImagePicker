//
//  BSImagePickerController.m
//  MultipleImagePicker
//
//  Created by Joakim Gyllström on 2014-04-05.
//  Copyright (c) 2014 Joakim Gyllström. All rights reserved.
//

#import "BSImagePickerController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "BSSpeechBubbleView.h"
#import "BSAlbumCell.h"

@interface BSImagePickerController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIToolbarDelegate, UITableViewDataSource, UITableViewDelegate>

+ (ALAssetsLibrary *)defaultAssetsLibrary;

@property (nonatomic, strong) NSMutableArray *photoAlbums; //Contains ALAssetsGroup
@property (nonatomic, strong) ALAssetsGroup *selectedAlbum;
@property (nonatomic, strong) NSMutableArray *photos;

@property (nonatomic, strong) UIToolbar *toolbar;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UITableView *albumTableView;
@property (nonatomic, strong) BSSpeechBubbleView *speechBubbleView;

@property (nonatomic, strong) UIBarButtonItem *cancelButton;
@property (nonatomic, strong) UIBarButtonItem *albumButton;
@property (nonatomic, strong) UIBarButtonItem *doneButton;

- (void)cancelButtonPressed:(id)sender;
- (void)doneButtonPressed:(id)sender;
- (void)albumButtonPressed:(id)sender;

@end

@implementation BSImagePickerController

+ (ALAssetsLibrary *)defaultAssetsLibrary
{
    static dispatch_once_t pred = 0;
    static ALAssetsLibrary *library = nil;
    dispatch_once(&pred, ^{
        library = [[ALAssetsLibrary alloc] init];
    });
    return library;
}

#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        //Default to shitloads of images
        _maximumNumberOfImages = NSUIntegerMax;
        
        //Add subviews
        [self.view addSubview:self.toolbar];
        [self.view addSubview:self.collectionView];
        
        //Setup constraints
        NSDictionary *views = @{@"_collectionView": self.collectionView, @"_toolbar": self.toolbar};
        NSDictionary *metrics = @{@"statusbarHeight": [NSNumber numberWithFloat:[UIApplication sharedApplication].statusBarFrame.size.height]};
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_toolbar]|"
                                                                         options:0
                                                                         metrics:nil
                                                                           views:views]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_collectionView]|"
                                                                          options:0
                                                                          metrics:nil
                                                                            views:views]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-statusbarHeight-[_toolbar][_collectionView]|"
                                                                          options:0
                                                                          metrics:metrics
                                                                            views:views]];
        
        //Setup album/photo arrays
        _photoAlbums = [[NSMutableArray alloc] init];
        _photos = [[NSMutableArray alloc] init];
        
        [[BSImagePickerController defaultAssetsLibrary] enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            if(group) {
                [self.photoAlbums addObject:group];
                
                //Default to select saved photos album
                if([[group valueForProperty:ALAssetsGroupPropertyType] isEqual:[NSNumber numberWithInteger:ALAssetsGroupSavedPhotos]]) {
                    [self setSelectedAlbum:group];
                }
            }
        } failureBlock:^(NSError *error) {
        }];
    }
    return self;
}

#pragma mark - UIViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 0;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

#pragma mark - UICollectionViewDelegate

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeZero;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsZero;
}

#pragma mark - UIToolbarDelegate

- (UIBarPosition)positionForBar:(id <UIBarPositioning>)bar
{
    return UIBarPositionTopAttached;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.photoAlbums count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BSAlbumCell *cell = [[BSAlbumCell alloc] init];
    
    ALAssetsGroup *group = [self.photoAlbums objectAtIndex:indexPath.row];

    if([group isEqual:self.selectedAlbum]) {
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    
    [cell.imageView setImage:[UIImage imageWithCGImage:group.posterImage scale:1.0 orientation:UIImageOrientationUp]];
    [cell.textLabel setText:[group valueForProperty:ALAssetsGroupPropertyName]];
    [cell setBackgroundColor:[UIColor clearColor]];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ALAssetsGroup *group = [self.photoAlbums objectAtIndex:indexPath.row];
    [self setSelectedAlbum:group];
    
    [UIView animateWithDuration:0.2
                     animations:^{
                         CGRect frame = self.speechBubbleView.frame;
                         frame.size.height = 7.0;
                         frame.size.width = 14.0;
                         frame.origin.y = [[UIApplication sharedApplication] statusBarFrame].size.height + self.toolbar.frame.size.height/2.0 + 10;
                         frame.origin.x = (self.view.frame.size.width - frame.size.width)/2.0;
                         [self.speechBubbleView setFrame:frame];
                     } completion:^(BOOL finished) {
                         [self.speechBubbleView removeFromSuperview];
                     }];
}

#pragma mark - Lazy load views

- (UICollectionView *)collectionView
{
    if(!_collectionView) {
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:[[UICollectionViewFlowLayout alloc] init]];
        [_collectionView setBackgroundColor:[UIColor whiteColor]];
        [_collectionView setAllowsMultipleSelection:YES];
        [_collectionView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [_collectionView setDelegate:self];
        [_collectionView setDataSource:self];
    }
    
    return _collectionView;
}

- (UIToolbar *)toolbar
{
    if(!_toolbar) {
        _toolbar = [[UIToolbar alloc] initWithFrame:CGRectZero];
        [_toolbar setTranslatesAutoresizingMaskIntoConstraints:NO];
        [_toolbar setDelegate:self];
        
        UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                               target:nil
                                                                               action:nil];
        
        [_toolbar setItems:@[self.cancelButton, space, self.albumButton, space, self.doneButton]];
    }
    
    return _toolbar;
}

- (UIBarButtonItem *)cancelButton
{
    if(!_cancelButton) {
        _cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                      target:self
                                                                      action:@selector(cancelButtonPressed:)];
    }
    
    return _cancelButton;
}

- (UIBarButtonItem *)doneButton
{
    if(!_doneButton) {
        _doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                    target:self
                                                                    action:@selector(doneButtonPressed:)];
    }
    
    return _doneButton;
}

- (UIBarButtonItem *)albumButton
{
    if(!_albumButton) {
        _albumButton = [[UIBarButtonItem alloc] initWithTitle:@"hejsan"
                                                        style:UIBarButtonItemStylePlain
                                                       target:self
                                                       action:@selector(albumButtonPressed:)];
    }
    
    return _albumButton;
}

- (BSSpeechBubbleView *)speechBubbleView
{
    if(!_speechBubbleView) {
        _speechBubbleView = [[BSSpeechBubbleView alloc] initWithFrame:CGRectMake(0, 0, 240, 320)];
        [_speechBubbleView.contentView addSubview:self.albumTableView];
    }
    
    return _speechBubbleView;
}

- (UITableView *)albumTableView
{
    if(!_albumTableView) {
        _albumTableView = [[UITableView alloc] init];
        [_albumTableView setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
        [_albumTableView setBackgroundColor:[UIColor clearColor]];
        [_albumTableView setDelegate:self];
        [_albumTableView setDataSource:self];
    }
    
    return _albumTableView;
}

#pragma mark - Button actions

- (void)cancelButtonPressed:(id)sender
{
    if(self.cancelBlock) {
        self.cancelBlock();
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)doneButtonPressed:(id)sender
{
    if(self.doneBlock) {
        self.doneBlock();
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)albumButtonPressed:(id)sender
{
    [self.view addSubview:self.speechBubbleView];
    [self.albumTableView reloadData];
    
    CGFloat tableViewHeight = MIN(self.albumTableView.contentSize.height, 160);
    CGRect frame = CGRectMake(0, 0, 240, tableViewHeight+7);
    
    //Remember old values
    CGFloat height = frame.size.height;
    CGFloat width = frame.size.width;
    
    //Set new frame
    frame.size.height = 0.0;
    frame.size.width = 0.0;
    frame.origin.y = [[UIApplication sharedApplication] statusBarFrame].size.height + self.toolbar.frame.size.height/2.0 + 10;
    frame.origin.x = (self.view.frame.size.width - frame.size.width)/2.0;
    [self.speechBubbleView setFrame:frame];
    
    [UIView animateWithDuration:0.7
                          delay:0.0
         usingSpringWithDamping:0.7
          initialSpringVelocity:0
                        options:0
                     animations:^{
                         CGRect frame = self.speechBubbleView.frame;
                         frame.size.height = height;
                         frame.size.width = width;
                         frame.origin.x = (self.view.frame.size.width - frame.size.width)/2.0;
                         [self.speechBubbleView setFrame:frame];
                     } completion:^(BOOL finished) {
//                         [self.speechBubbleView removeFromSuperview];
                     }];
}

#pragma mark - Something

- (void)setSelectedAlbum:(ALAssetsGroup *)selectedAlbum
{
    _selectedAlbum = selectedAlbum;
    [self.collectionView reloadData];
}

@end