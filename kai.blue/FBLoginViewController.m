
#import "FBLoginViewController.h"

@interface FBLoginViewController () <CommsDelegate>
@property (nonatomic, strong) IBOutlet UIButton *btnLogin;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityLogin;
@end

@implementation FBLoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];
    // Ensure the User is Logged out when loading this View Controller
    // Going forward, we would check the state of the current user and bypass the Login Screen
    // but here, the Login screen is an important part of the tutorial
    [PFUser logOut];
}

- (void) commsDidLogin:(BOOL)loggedIn {
	// Re-enable the Login button
	[_btnLogin setEnabled:YES];
    
	// Stop the activity indicator
	[_activityLogin stopAnimating];
    
	// Did we login successfully ?
	if (loggedIn) {
		// Seque to the Image Wall
		[self performSegueWithIdentifier:@"LoginSuccessful" sender:self];
	} else {
		// Show error alert
		[[[UIAlertView alloc] initWithTitle:@"Login Failed"
                                    message:@"Facebook Login failed. Please try again"
                                   delegate:nil
                          cancelButtonTitle:@"Ok"
                          otherButtonTitles:nil] show];
	}
}



// Outlet for FBLogin button
- (IBAction) loginPressed:(id)sender
{
    // Disable the Login button to prevent multiple touches
    [_btnLogin setEnabled:NO];
    
    // Show an activity indicator
    [_activityLogin startAnimating];

    // Reset the DataStore so that we are starting from a fresh Login
    // as we could have come to this screen from the Logout navigation
    [[DataStore instance] reset];
    
    // Do the login
    [Comms login:self];
}

@end
