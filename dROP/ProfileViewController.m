//
//  ProfileViewController.m
//  dROP
//
//  Created by Moses Esan on 08/03/2015.
//  Copyright (c) 2015 Moses Esan. All rights reserved.
//

#import "ProfileViewController.h"
#import "Config.h"
#import "PostTextTableViewCell.h"
#import "ColouredTableViewCell.h"
#import "CommentsTableViewController.h"
#import "UIFont+Montserrat.h"
#import "InfoViewController.h"
#import "CCMBorderView.h"
#import "CCMPopupTransitioning.h"

#import "MHFacebookImageViewer.h"
#import "RESideMenu.h"
#import "DIDataManager.h"


@interface ProfileViewController ()
{
    UILabel *rankLabel;
    NSDate *lastUpdated;
    
    BOOL showAlert;
    DIDataManager *shared;
}

@property (nonatomic, strong) MCSwipeTableViewCell *cellToDelete;

@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    shared = [DIDataManager sharedManager];
    
    self.title = @"Profile";

    
    showAlert = NO;
    
    [self getData];
    
    //Info
    UIButton *info = [UIButton buttonWithType:UIButtonTypeCustom];
    info.frame = CGRectMake(0, 0, 22, 22);
    [info setImage:[UIImage imageNamed:@"Info"] forState:UIControlStateNormal];
    [info setClipsToBounds:YES];
    info.imageView.contentMode = UIViewContentModeScaleAspectFill;
    info.imageEdgeInsets = UIEdgeInsetsMake(1, 1, 1, 1);
    [info addTarget:self action:@selector(showPointsInfo:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:info];
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, WIDTH, 85)];
    headerView.backgroundColor = [UIColor clearColor];
    
    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.frame = CGRectMake(0, 85 - 1.0f,
                                    WIDTH, 1.0f);
    bottomBorder.backgroundColor = [UIColor colorWithRed:216/255.0f green:216/255.0f blue:216/255.0f alpha:1].CGColor;
    [headerView.layer addSublayer:bottomBorder];
    
    
    UILabel *rankTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 8, CGRectGetWidth(headerView.frame), 30)];
    rankTitleLabel.backgroundColor = [UIColor clearColor];
    rankTitleLabel.text = @"RANK:";
    rankTitleLabel.textAlignment = NSTextAlignmentCenter;
    rankTitleLabel.font = [UIFont montserratFontOfSize:22.0f];
    rankTitleLabel.textColor = DATE_COLOR;
    [headerView addSubview:rankTitleLabel];
    
    rankLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 38, CGRectGetWidth(headerView.frame), 40)];
    rankLabel.backgroundColor = [UIColor clearColor];
    rankLabel.textAlignment = NSTextAlignmentCenter;
    rankLabel.font = [UIFont montserratFontOfSize:23.5f];
    rankLabel.textColor = DATE_COLOR;
    [headerView addSubview:rankLabel];
    
    self.tableView.tableHeaderView = headerView;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newPostAdded:)
                                                 name:NEW_POST_NOTIFICATION
                                               object:nil];
    
    //Add Refresh Control
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self
                       action:@selector(refresh:)
             forControlEvents:UIControlEventValueChanged];
    
    [self.tableView addSubview:refreshControl];
}

- (void)viewWillAppear:(BOOL)animated
{
    showAlert = YES;

    self.navigationController.navigationBar.barStyle = BAR_STYLE;
    self.navigationController.navigationBar.barTintColor = BAR_TINT_COLOR2;
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:235/255.0f green:237/255.0f blue:236/255.0f alpha:1.0f];
    self.navigationController.navigationBar.translucent = NO;
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    NSDictionary *usersInfo  = [Config userPoints];
    
    rankLabel.text = [NSString stringWithFormat:@"%@ (%@)",usersInfo[@"Rank"],usersInfo[@"Points"]];
    
    if ([Config checkLastUpdated:lastUpdated withMaxDifference:20])
        [self getData];
    
    [self.tableView reloadData];
}

- (void)getData
{
    dispatch_queue_t queriesQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queriesQueue, ^{
        
        [shared getUsersPostsWithBlock:^(BOOL reload, NSError *error) {
            
            if (!error && reload)
            {
                [self.tableView reloadData];
            }else if (error){
                
                if (error.code == 0 && showAlert) {
                    [[Config alertViewWithTitle:@"No Internet Connection" withMessage:nil] show];
                    showAlert = NO;
                }
            }
        }];
        
        [shared getLikedPostsWithBlock:^(BOOL reload, NSError *error) {
            
            if (!error && reload)
            {
                [self.tableView reloadData];
            }else if (error){
                
                if (error.code == 0 && showAlert) {
                    [[Config alertViewWithTitle:@"No Internet Connection" withMessage:nil] show];
                    showAlert = NO;
                }
            }
        }];
        
        [shared getLikedPostsWithBlock:^(BOOL update, NSError *error) {
            
            if (!error && update)
            {
                lastUpdated = [NSDate date];
                
                NSDictionary *usersInfo  = [Config userPoints];
                
                rankLabel.text = [NSString stringWithFormat:@"%@ (%@)",usersInfo[@"Rank"],usersInfo[@"Points"]];
                
            }else if (error){
                
                if (error.code == 0 && showAlert) {
                    [[Config alertViewWithTitle:@"No Internet Connection" withMessage:nil] show];
                    showAlert = NO;
                }
            }
        }];
    });
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    
    if (section == 0) return [shared.myPosts count];
    else return [shared.likedPosts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *postObject;
    CGFloat max;
    NSString *cellIdentifier;
    
    if (indexPath.section == 0) {
        postObject = shared.myPosts[indexPath.row];
        max = [shared.myPosts count] - 1;
    }else{
        postObject = shared.likedPosts[indexPath.row];
        max = [shared.likedPosts count] - 1;
    }

    NSInteger likesCount = [postObject[@"totalLikes"] integerValue];
    PFObject *parseObject = postObject[@"parseObject"];
    
    if (indexPath.section == 0) {
        cellIdentifier = [NSString stringWithFormat:@"MyPostCell%@",parseObject.objectId];
    }else{
        cellIdentifier = [NSString stringWithFormat:@"LikedPostCell%@",parseObject.objectId];
    }
    
    ColouredTableViewCell *cell = (ColouredTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell)
        cell = [[ColouredTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    
    [cell setFrameWithObject:postObject forIndex:indexPath.row];

    
    if (indexPath.row != max)
        cell.bottomBorder.frame = CGRectMake(0, CGRectGetHeight(cell.mainContainer.frame) - 0.5f, CGRectGetWidth(cell.mainContainer.frame), .5f);
    
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    if (parseObject[@"pic"])
    {
        cell.postImage.file = parseObject[@"pic"];
        cell.postImage.tag = 1;//indexPath.row;
        [cell.postImage loadInBackground];
        [cell.postImage setupImageViewerWithPFFile:cell.postImage.file onOpen:nil onClose:nil];
    }
    
    
    //if the user is the owner of the post
    //and the post has likes, show the smiley button
    //else hide it
    if ([Config isPostAuthor:postObject])
    {
        if (likesCount > 0) cell.smiley.hidden = NO;
        else cell.smiley.hidden = YES;
    }
    
    //If the value for the disliked index is not YES,
    //set the smiley selected state to the value of the liked index
    if (![postObject[@"disliked"] boolValue]){
        cell.smiley.selected = [postObject[@"liked"] boolValue];
    }else{
        //else  set the smiley selected state to NO
        //set the smiley highlighted state to the value of the disliked index to indicate the user has disliked the post
        cell.smiley.selected = NO;
        cell.smiley.highlighted = [postObject[@"disliked"] boolValue];
    }
    
    //If the user is not the post authour
    //They can like, dislike and report the post
    if (![Config isPostAuthor:postObject])
    {
        cell.smiley.tag = indexPath.row;
        [cell.smiley addTarget:self action:@selector(likePost:) forControlEvents:UIControlEventTouchUpInside];
        
        __weak typeof(cell) weakSelf = cell;
        
        [cell setSwipeGestureWithView:[Config viewWithImageName:@"cross"]
                                color:[UIColor colorWithRed:232.0 / 255.0 green:61.0 / 255.0 blue:14.0 / 255.0 alpha:1.0]
                                 mode:MCSwipeTableViewCellModeExit
                                state:MCSwipeTableViewCellState1 completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode) {
                                    
                                    _cellToDelete = weakSelf;
                                    
                                    
                                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Options?"
                                                                                        message:@"What would you like to do?"
                                                                                       delegate:self
                                                                              cancelButtonTitle:@"Cancel"
                                                                              otherButtonTitles:@"Dislike", @"Report",nil];
                                    [alertView show];
                                }];
    }else if ([Config isPostAuthor:postObject]){
        
        //If the user is th author of the post
        //allow the user to be able to delete the post
        __weak typeof(cell) weakSelf = cell;
        
        [cell setSwipeGestureWithView:[Config viewWithImageName:@"cross"]
                                color:[UIColor colorWithRed:232.0 / 255.0 green:61.0 / 255.0 blue:14.0 / 255.0 alpha:1.0]
                                 mode:MCSwipeTableViewCellModeExit
                                state:MCSwipeTableViewCellState1 completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode) {
                                    
                                    _cellToDelete = weakSelf;
                                    
                                    
                                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Delete Post"
                                                                                        message:@"Are yu sure you want to delete this post?"
                                                                                       delegate:self
                                                                              cancelButtonTitle:@"No"
                                                                              otherButtonTitles:@"Yes",nil];
                                    [alertView show];
                                }];
    }
    
    cell.tag = indexPath.row;
    cell.selectionStyle= UITableViewCellSelectionStyleNone;
    cell.bottomBorder.backgroundColor = [tableView separatorColor].CGColor;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 31.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *sectionHeaderView = [[UIView alloc] initWithFrame:
                                 CGRectMake(0, 0, tableView.frame.size.width, 31.0)];
    sectionHeaderView.backgroundColor = [UIColor whiteColor];
    
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:
                            CGRectMake(15, 8.0f, sectionHeaderView.frame.size.width, 14.0f)];
    
    headerLabel.backgroundColor = [UIColor clearColor];
    headerLabel.textAlignment = NSTextAlignmentLeft;
    headerLabel.textColor = BAR_TINT_COLOR2;
    [headerLabel setFont:[UIFont montserratFontOfSize:12.5f]];
    [sectionHeaderView addSubview:headerLabel];
    
    switch (section) {
        case 0:
            headerLabel.text = @"MY POSTS";
            return sectionHeaderView;
            break;
        case 1:
            headerLabel.text = @"LIKED POSTS";
            return sectionHeaderView;
            break;
        default:
            break;
    }
    
    return sectionHeaderView;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *postObject;
    
    if (indexPath.section == 0) postObject = shared.myPosts[indexPath.row];
    else postObject = shared.likedPosts[indexPath.row];
    
    NSString *postText = postObject[@"text"];
    
    CGFloat postTextHeight = [Config calculateHeightForText:postText withWidth:WIDTH - 55.0f withFont:TEXT_FONT];
    
    CGFloat height = TOP_PADDING + postTextHeight + 12 + ACTIONS_VIEW_HEIGHT + 3;
    
    if (postObject[@"parseObject"][@"pic"])
        height += 10 + IMAGEVIEW_HEIGHT;
    
    return height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *postObject;
    
    if (indexPath.section == 0) postObject = shared.myPosts[indexPath.row];
    else postObject = shared.likedPosts[indexPath.row];
    
    CommentsTableViewController *viewPost = [[CommentsTableViewController alloc] initWithNibName:nil bundle:nil];
    viewPost.postObject = postObject;
    viewPost.view.tag = indexPath.row;
    viewPost.viewType = PROFILE;
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    [self.navigationController pushViewController:viewPost animated:YES];
}

- (void)newPostAdded:(NSNotification *)notification
{
    NSDictionary * info = notification.userInfo;
    PFObject *newObject = [info objectForKey:@"newObject"];
    
    //1 - Add New Post Array to the first position of the array
    [shared.myPosts insertObject:[Config createPostObject:newObject] atIndex:0];
    
    [self.tableView reloadData];
}

- (void)showPointsInfo:(UIBarButtonItem *)sender
{
    InfoViewController *pointsInfo = [[InfoViewController alloc] initWithNibName:nil bundle:nil];
    
    CCMPopupTransitioning *popup = [CCMPopupTransitioning sharedInstance];
    popup.destinationBounds = CGRectMake(0, 0, INFO_VIEW_WIDTH, INFO_VIEW_HEIGHT);
    popup.presentedController = pointsInfo;
    popup.presentingController = self;
    
    
    popup.backgroundViewColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    popup.backgroundViewAlpha = 3.0f;
    
    [self presentViewController:pointsInfo animated:YES completion:nil];
}

-(void)refresh:(UIRefreshControl *)refresh
{
    [refresh endRefreshing];
    
    [self getData];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    
    if([title isEqualToString:@"Dislike"])
    {
        [_cellToDelete swipeToOriginWithCompletion:^{
            
            //Call dislike method
            [shared dislikePostAtIndex:_cellToDelete.tag forView:PROFILE];
            
            //Remove the cell
            [self.tableView deleteRowsAtIndexPaths:@[[self.tableView indexPathForCell:_cellToDelete]] withRowAnimation:UITableViewRowAnimationFade];
            
            _cellToDelete = nil;
        }];
        
    }else if([title isEqualToString:@"Report"]) {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Report Post"
                                                            message:@"Please tell us what is wrong with ths post."
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"Offensive content", @"Spam", @"Other", nil];
        [alertView show];
    }else if([title isEqualToString:@"Offensive content"] ||
             [title isEqualToString:@"Spam"] ||
             [title isEqualToString:@"Other"])
    {
        //Call report method
        [shared reportPostAtIndex:_cellToDelete.tag forView:PROFILE];
        
        //Remove the cell
        [self.tableView deleteRowsAtIndexPaths:@[[self.tableView indexPathForCell:_cellToDelete]] withRowAnimation:UITableViewRowAnimationFade];
        
        _cellToDelete = nil;
        
        
    }else if([title isEqualToString:@"Yes"]) {
        
        //Call delete method
        [shared deletePostAtIndex:_cellToDelete.tag forView:HOME];
        
        //Remove the cell
        [self.tableView deleteRowsAtIndexPaths:@[[self.tableView indexPathForCell:_cellToDelete]] withRowAnimation:UITableViewRowAnimationFade];
        
        _cellToDelete = nil;
    }else{
        _cellToDelete = nil;
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
