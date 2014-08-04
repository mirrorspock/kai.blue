
@implementation Comms

+ (void) login:(id<CommsDelegate>)delegate
{
	// Basic User information and your friends are part of the standard permissions
	// so there is no reason to ask for additional permissions
	[PFFacebookUtils logInWithPermissions:nil block:^(PFUser *user, NSError *error) {
		// Was login successful ?
		if (!user) {
			if (!error) {
                NSLog(@"The user cancelled the Facebook login.");
            } else {
                NSLog(@"An error occurred: %@", error.localizedDescription);
            }
            
			// Callback - login failed
			if ([delegate respondsToSelector:@selector(commsDidLogin:)]) {
				[delegate commsDidLogin:NO];
			}
		} else {
			if (user.isNew) {
				NSLog(@"User signed up and logged in through Facebook!");
			} else {
				NSLog(@"User logged in through Facebook!");
			}
            
			[FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                if (!error) {
                    NSDictionary<FBGraphUser> *me = (NSDictionary<FBGraphUser> *)result;
                    // Store the Facebook Id
                    [[PFUser currentUser] setObject:me.objectID forKey:@"fbId"];
                    [[PFUser currentUser] saveInBackground];
                    [[DataStore instance].fbFriends setObject:me forKey:me.objectID];
                    // 1
                    NSLog(@"Finding friends");

                    
                    FBRequest *friendsRequest = [FBRequest requestForMyFriends];
                    [friendsRequest startWithCompletionHandler: ^(FBRequestConnection *connection,
                                                                  NSDictionary* result,
                                                                  NSError *error) {
                        // 2
                        NSArray *friends = result[@"data"];
                        for (NSDictionary<FBGraphUser>* friend in friends) {
                            NSLog(@"Found a friend: %@", friend.name);
                            // 3
                            // Add the friend to the list of friends in the DataStore
                            [[DataStore instance].fbFriends setObject:friend forKey:friend.objectID];
                        }
                        
                        // 4
                        // Callback - login successful
                        if ([delegate respondsToSelector:@selector(commsDidLogin:)]) {
                            [delegate commsDidLogin:YES];
                        }
                    }];
                    
                }
                
            }];
		}
	}];
}


+ (void) uploadImage:(UIImage *)image withComment:(NSString *)comment forDelegate:(id<CommsDelegate>)delegate
{
    // 1
    NSData *imageData = UIImagePNGRepresentation(image);
    
    // 2
    PFFile *imageFile = [PFFile fileWithName:@"img" data:imageData];
    [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            // 3
            PFObject *wallImageObject = [PFObject objectWithClassName:@"WallImage"];
            wallImageObject[@"image"] = imageFile;
            wallImageObject[@"userFBId"] = [[PFUser currentUser] objectForKey:@"fbId"];
            wallImageObject[@"user"] = [PFUser currentUser].username;
            
            [wallImageObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    // 4
                    PFObject *wallImageCommentObject = [PFObject objectWithClassName:@"WallImageComment"];
                    wallImageCommentObject[@"comment"] = comment;
                    wallImageCommentObject[@"userFBId"] = [[PFUser currentUser] objectForKey:@"fbId"];
                    wallImageCommentObject[@"user"] = [PFUser currentUser].username;
                    wallImageCommentObject[@"imageObjectId"] = wallImageObject.objectId;
                    
                    [wallImageCommentObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        // 5
                        if ([delegate respondsToSelector:@selector(commsUploadImageComplete:)]) {
                            [delegate commsUploadImageComplete:YES];
                        }
                    }];
                } else {
                    // 6
                    if ([delegate respondsToSelector:@selector(commsUploadImageComplete:)]) {
                        [delegate commsUploadImageComplete:NO];
                    }
                }
            }];
        } else {
            // 7
            if ([delegate respondsToSelector:@selector(commsUploadImageComplete:)]) {
                [delegate commsUploadImageComplete:NO];
            }
        }
    } progressBlock:^(int percentDone) {
        // 8
        if ([delegate respondsToSelector:@selector(commsUploadImageProgress:)]) {
            [delegate commsUploadImageProgress:percentDone];
        }
    }];
}


@end
