/*
 Copyright (c) 2012 Tim Sawtell
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"),
 to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
 and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 IN THE SOFTWARE.
 */

#import "TSViewController.h"

static NSString * const kHideActivitySuperview  = @"hideActivitySuperview";
static NSString * const kFontToUse              = @"Helvetica-Bold";

static CGFloat const kCornerRadius              = 10.0f;
static CGFloat const kFontSize                  = 16.0f;

@interface TSViewController ()
@property (nonatomic, assign) BOOL overrideShowingActivityScreen;
@property (nonatomic, strong) UIView *activitySuperview;

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context;
- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view;
- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view;
- (void)fetchData;
@end

@implementation TSViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.scrollViewToResizeOnKeyboardShow.contentInset = UIEdgeInsetsZero;
    if (self.wantsPullToRefresh) {
        self.headerView = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.scrollViewToResizeOnKeyboardShow.bounds.size.height, self.scrollViewToResizeOnKeyboardShow.bounds.size.width, self.scrollViewToResizeOnKeyboardShow.bounds.size.height) forBottomOfView:NO];
        self.headerView.delegate = self;
        [self.scrollViewToResizeOnKeyboardShow addSubview:self.headerView];
        
        if (self.wantsPullToRefreshFooter) {
            self.footerView = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, self.scrollViewToResizeOnKeyboardShow.frame.size.height, self.view.frame.size.width, self.scrollViewToResizeOnKeyboardShow.bounds.size.height) forBottomOfView:YES];
            self.footerView.delegate = self;
            self.footerView.hidden = YES;
            [self.scrollViewToResizeOnKeyboardShow addSubview:self.footerView];
        }
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:UIKeyboardDidShowNotification];
    [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:UIKeyboardWillHideNotification];
    [super viewDidUnload];
}


// when the keyboard shows we have to update the scroll position and the content inset for the tableview, such that it's resized to be above the keyboard
- (void)keyboardDidShow:(NSNotification *)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    UIEdgeInsets contentInsets;
    CGFloat distanceOfTableViewFromBottomOfWindow = self.view.frame.size.height - self.scrollViewToResizeOnKeyboardShow.frame.origin.y - (self.scrollViewToResizeOnKeyboardShow.frame.origin.y + self.scrollViewToResizeOnKeyboardShow.frame.size.height);
    contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height - self.scrollViewToResizeOnKeyboardShow.frame.origin.y - distanceOfTableViewFromBottomOfWindow, 0.0f);
    
    self.scrollViewToResizeOnKeyboardShow.contentInset = contentInsets;
    self.scrollViewToResizeOnKeyboardShow.scrollIndicatorInsets = contentInsets;
}

- (void)keyboardWillHide:(NSNotification *)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.scrollViewToResizeOnKeyboardShow.contentInset = contentInsets;
    self.scrollViewToResizeOnKeyboardShow.scrollIndicatorInsets = contentInsets;
}

- (void) showActivityScreen
{
    [self showActivityScreenWithMessage:@"Loading..." animated:YES];
}

- (void) showActivityScreenWithMessage:(NSString*)message animated:(BOOL)animated
{
    if (self.overrideShowingActivityScreen == YES) {
        return;
    }
	if (self.activitySuperview) {
		[self.activitySuperview removeFromSuperview];
		self.activitySuperview = nil;
	}
	self.activitySuperview = [[UIView alloc] initWithFrame: self.view.bounds];
	[self.activitySuperview setAutoresizingMask: UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
	[self.view addSubview: self.activitySuperview];
	
	UIView *dimmerView = [[UIView alloc] initWithFrame: self.activitySuperview.bounds];
	[dimmerView setAutoresizingMask: UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
	dimmerView.backgroundColor = [UIColor colorWithWhite: 0.0 alpha: 1.0];
	dimmerView.alpha = 0.6;
	[self.activitySuperview addSubview: dimmerView];
	
	CGRect containerBG = CGRectRoundToInt(CGRectMake((self.activitySuperview.bounds.size.width / 2) - (250.0 / 2),
                                                     (self.activitySuperview.bounds.size.height / 2) - (250.0 / 2), 250.0, 250.0));
	
	UIView *containerView = [[UIView alloc] initWithFrame:containerBG];
	containerView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
	[containerView setBackgroundColor:[UIColor clearColor]];
	[self.activitySuperview addSubview:containerView];
    
	CGRect spinnerBG = CGRectRoundToInt(CGRectMake((containerBG.size.width / 2) - (111.0 / 2),
                                                   (containerBG.size.height / 2) - (111.0 / 2), 111.0, 111.0));
	UIView *activitySpinnerBackground = [[UIView alloc] initWithFrame: spinnerBG];
	activitySpinnerBackground.backgroundColor = [UIColor colorWithWhite: 0.0 alpha: 0.6];
	activitySpinnerBackground.opaque = NO;
	activitySpinnerBackground.alpha = 1.0;
	activitySpinnerBackground.layer.cornerRadius = kCornerRadius;
	activitySpinnerBackground.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
	
	[containerView addSubview: activitySpinnerBackground];
	
	if(NSStringIsSane(message) == YES)
	{
		UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, spinnerBG.origin.y-50-20, (containerView.bounds.size.width-40), 70)];
        [messageLabel setNumberOfLines:2];
		messageLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
		[messageLabel setFont:[UIFont fontWithName:kFontToUse size:kFontSize]];
		[messageLabel setShadowColor:[UIColor blackColor]];
		[messageLabel setShadowOffset:CGSizeMake(0, 1)];
		[messageLabel setTextColor:[UIColor whiteColor]];
		[messageLabel setBackgroundColor:[UIColor clearColor]];
		[messageLabel setTextAlignment:NSTextAlignmentCenter];
		messageLabel.text = message;
		[containerView addSubview:messageLabel];
	}
	
	UIActivityIndicatorView *activitySpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhiteLarge];
	[activitySpinnerBackground addSubview: activitySpinner];
	[activitySpinner setFrame: CGRectMake(37, 37, 37, 37)];
	[activitySpinner startAnimating];
	
	if (animated) {
		self.activitySuperview.alpha = 0.0;
		[UIView beginAnimations: nil context: nil];
		[UIView setAnimationDuration: 0.3];
		self.activitySuperview.alpha = 1.0;
		[UIView commitAnimations];
	}
}

- (void) hideActivityScreen
{
    [self hideActivityScreenAnimated:YES];
}

- (void) hideActivityScreenAnimated:(BOOL)animated
{
	if (!animated) {
		[self.activitySuperview removeFromSuperview];
		self.activitySuperview = nil;
		return;
	}
	self.activitySuperview.alpha = 1.0;
	[UIView beginAnimations:kHideActivitySuperview context: nil];
	[UIView setAnimationDuration: 0.5];
	[UIView setAnimationDelegate: self];
	[UIView setAnimationDidStopSelector: @selector(animationDidStop:finished:context:)];
	self.activitySuperview.alpha = 0.0;
	[UIView commitAnimations];
}

- (void) animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
	if ([animationID isEqualToString:kHideActivitySuperview]) {
		[self.activitySuperview removeFromSuperview];
		self.activitySuperview = nil;
	}
}

#pragma mark - EgoHeaderview

- (void)setupFooterView
{
    CGRect frameRect;
    if (self.scrollViewToResizeOnKeyboardShow.contentSize.height < self.scrollViewToResizeOnKeyboardShow.bounds.size.height) {
        frameRect = CGRectMake(self.footerView.frame.origin.x, self.scrollViewToResizeOnKeyboardShow.bounds.size.height, self.footerView.frame.size.width, self.footerView.frame.size.height);
        self.footerView.frame = frameRect;
    } else {
        frameRect = CGRectMake(self.footerView.frame.origin.x, self.scrollViewToResizeOnKeyboardShow.contentSize.height, self.footerView.frame.size.width, self.footerView.frame.size.height);
        self.footerView.frame = frameRect;
    }
}

- (BOOL)wantsPullToRefresh
{
    return NO; // by default, the VCs you subclass should return YES if needed
}

- (BOOL)wantsPullToRefreshFooter
{
    return NO; // by default, the VCs you subclass should return YES if needed
}

- (void)fetchData
{
    self.fetchingData = YES;
}

- (void)doneLoadingData
{
	//  model should call this when its done loading
	self.fetchingData = NO;
    [self.headerView egoRefreshScrollViewDataSourceDidFinishedLoading:self.scrollViewToResizeOnKeyboardShow];
    [self.footerView egoRefreshScrollViewDataSourceDidFinishedLoading:self.scrollViewToResizeOnKeyboardShow];
}

- (void)reloadData
{
    // any other things that need to be reloaded
    if (self.wantsPullToRefreshFooter) {
        self.footerView.hidden = NO;
        [self setupFooterView];
    }
    if ([self wantsPullToRefresh]) {
        [self performSelector:@selector(doneLoadingData) withObject:nil afterDelay:0.1];
    }
}

#pragma mark - EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view
{
    [self fetchData];
}

- (void)egoRefreshTableHeaderDidTriggerLoadMore:(EGORefreshTableHeaderView *)view
{
    [self fetchData];
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view
{
    return self.fetchingData;
}

#pragma mark - UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	if (self.wantsPullToRefresh) {
        // find out if the user is pulling on the top part (to refresh) or the bottom part (to load more)
        NSInteger currentOffset = scrollView.contentOffset.y;
        NSInteger maximumOffset = MAX(scrollView.contentSize.height - scrollView.frame.size.height, 0);
        if (currentOffset < 0) {
            [self.headerView egoRefreshScrollViewDidScroll:scrollView];
        } else if (currentOffset > maximumOffset) {
            [self.footerView egoRefreshScrollViewDidScroll:scrollView];
        }
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	if (self.wantsPullToRefresh) {
        // find out if the user is pulling on the top part (to refresh) or the bottom part (to load more)
        NSInteger currentOffset = scrollView.contentOffset.y;
        NSInteger maximumOffset = MAX(scrollView.contentSize.height - scrollView.frame.size.height, 0);
        if (currentOffset < 0) {
            [self.headerView egoRefreshScrollViewDidEndDragging:scrollView];
        } else if (currentOffset > maximumOffset) {
            [self.footerView egoRefreshScrollViewDidEndDragging:scrollView];
        }
    }
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view
{	
	return [NSDate date]; // should return date data source was last changed
}

@end
