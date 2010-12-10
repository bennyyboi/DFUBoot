//
//  DFUBootAppDelegate.m
//  DFUBoot
//
//  Created by Ben on 23/10/2010.
//  Copyright 2010 Techizmo. All rights reserved.
//

#import "DFUBootAppDelegate.h"

@implementation DFUBootAppDelegate

@synthesize window, ipswSel, progressInfo, browseIPSW, cancelProcess, progressDial, creditsPane, acCredits, closeCredits, hazFinished;

// Start the button actions...

- (IBAction)hideCredits:(id)sender
{
	[creditsPane orderOut:sender];
}

- (IBAction)showCredits:(id)sender
{
	[creditsPane orderFront:sender];
	[creditsPane retain];
}

- (IBAction)findIPSW:(id)sender
{
	NSOpenPanel *oPanel = [[NSOpenPanel openPanel] retain];

	
	[oPanel beginForDirectory:nil file:nil types:[NSArray arrayWithObject:@"ipsw"] modelessDelegate:self didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSOKButton)
	{
		// Recreate folder
		NSString * cPathName = @"/tmp/ipsw";// cPathName is your specified path
		
		
		
		NSFileManager *fm = [NSFileManager defaultManager];
		[fm createDirectoryAtPath:cPathName withIntermediateDirectories:TRUE
					   attributes:nil error:nil]; 
		
		NSLog(@"Created temp folder: %@", cPathName);
		
		//Start the spinning wheel...Start the show in style is the way forward!
		[progressDial startAnimation:YES];
		[progressDial setHidden:NO];
		[progressDial setNeedsDisplay:YES];
		
		//Disable 'Browse for IPSW' button.
		[browseIPSW setEnabled:NO];
		[browseIPSW setNeedsDisplay:YES];
		[cancelProcess setEnabled:YES];
		[cancelProcess setNeedsDisplay:YES];
		
		//Update ProgressInfo
		[progressInfo setStringValue:@"Preparing IPSW..."];
		
		//Show the actual filename under the 'Browse for IPSW' button...
		NSString *fileNameToBeShown=[[NSFileManager defaultManager] displayNameAtPath:[panel filename]];
		[ipswSel setStringValue:fileNameToBeShown];
		
		// Prepare to copy the IPSW to a temporary location...
		NSFileManager *fileManager = [NSFileManager defaultManager];
		
		NSString *source, *dest;
		
		source = [[panel filename] stringByExpandingTildeInPath];
		NSLog(source);
		dest = [NSString stringWithFormat:@"/tmp/ipsw/%@", fileNameToBeShown];
		NSLog(dest);
		
		if ([fileManager fileExistsAtPath:source])
		{
			[fileManager copyPath:source toPath:dest handler:nil];
			NSLog(@"ipsw moved to: %@", dest);
		}
		
		// Prepare to rename file...
		
		// When the IPSW is sitting nicely in the temp folder we need to change it's extension so we can
		// extract it's contents to be used later on during the process.
		
		NSString *oldName = dest;
		NSString *destx = [[fileNameToBeShown lastPathComponent] stringByDeletingPathExtension];
		NSString *newName = [NSString stringWithFormat:@"/tmp/ipsw/%@.zip", destx];
		
		NSString *newPath = [[oldName stringByDeletingPathExtension] stringByAppendingPathComponent:newName];
		[[NSFileManager defaultManager] movePath:oldName toPath:newName handler:nil];
		
		NSLog( @"IPSW Extension changed to %@", newName );
		
		// Okay, so we now changed the file extension - we need to extract the IPSW contents into the
		// root directory '/tmp/ipsw' so we can do whatever we want with the content, such-as delete stuff? mauahah!
		
		NSString *dest1 = @"/tmp/ipsw";
		NSTask *cmnd = [[NSTask alloc] init];
		[cmnd setLaunchPath:@"/usr/bin/ditto"];
		[cmnd setArguments:[NSArray arrayWithObjects:
							@"-v",@"-x",@"-k",@"--rsrc",newName,dest1,nil]];
		NSString *destx1 = [[fileNameToBeShown lastPathComponent] stringByDeletingPathExtension];
		[progressInfo setStringValue:[NSString stringWithFormat:@"Extracting '%@'...", destx1]];
		[cmnd launch];
		[cmnd waitUntilExit];
		
		// Handle the tasks termination status
		if ([cmnd terminationStatus] != 0)
		{
			NSLog(@"Sorry, didn't work!");
			[progressInfo setStringValue:@"I Haz Failed...Unable to unzip archive!"];
			[progressDial stopAnimation:YES];
			[browseIPSW setEnabled:YES];
			[browseIPSW setNeedsDisplay:YES];
			return NULL;
		}
		
		// You *did* remember to wash behind your ears...right?
		[cmnd release];
		
		// Since we going to be making a custom IPSW we need to delete the compressed zip file,
		// otherwise it will make the newly IPSW invalid when used on iTunes :/
		
		NSString *fileToDelete = newName;
		
		NSError *error;
		BOOL success = [[NSFileManager defaultManager] removeItemAtPath:fileToDelete error:&error];
		if ( !success )
		{
			[progressInfo setStringValue:@"I Haz Failed...Unable to delete zip file..."];
		}
		
		NSLog(@"Deleted file: %@", fileToDelete);
		
		
		[progressInfo setStringValue:@"Patching IPSW..."];
		
		// Start the patching process
		
		// We need to find the img3 directory, usually found in the
		// 'all_flash.nXXap.production' or older device 'all_flash.mXXap.production'.
		// Then we need to delete the LLB from that directory and make sure we delete both LLB's
		// if two production folders are found.
		
		NSString *flashFolder = @"/tmp/ipsw/Firmware/all_flash";
		NSFileManager *defaultManager = [NSFileManager defaultManager];
		NSArray *filePath = [defaultManager directoryContentsAtPath:flashFolder];
		int i , count = [filePath count];
		
		for ( i = 0 ; i < count ; i++ ) {
			NSLog(@"Looking for img3 directory...");
			NSLog(@"Done...Found img3 directory...Moving on!");
			
			NSString *deviceNand = [NSString stringWithFormat:@"/tmp/ipsw/Firmware/all_flash/%@",[filePath objectAtIndex:i]];
			
            NSLog(@"Detecting Device Type...");
			NSLog(@"Done...Detected Device Type...Moving on!");
			
			NSRange range = NSMakeRange(39, 5);
			NSString *deviceType = [NSString stringWithFormat:@"%@", [deviceNand substringWithRange:range]];
			
			NSLog(@"Detected Device Type As: %@",deviceType);
			
			NSLog(@"Detecting Application Processor...");
			
			NSString * path = [[NSBundle mainBundle] pathForResource:@"ap" ofType:@"plist"];
			
			NSDictionary *plistDictionary = [NSDictionary dictionaryWithContentsOfFile:path];
			NSRange ipswName = NSMakeRange(0, 9);
			NSString* deviceVer = [NSString stringWithFormat:@"%@", [fileNameToBeShown substringWithRange:ipswName]];
			
			NSString *nameString = [plistDictionary objectForKey:deviceVer];
			
			NSLog(@"Application Processor Detected: %@x", nameString);
			NSString* iproc = [NSString stringWithFormat:@"%@x",nameString];
			
			NSString *old_Name = [NSString stringWithFormat:@"/tmp/ipsw/Firmware/all_flash/all_flash.%@.production/applelogo.%@.img3", deviceType,iproc];
			NSString *new_Name = [NSString stringWithFormat:@"/tmp/ipsw/Firmware/all_flash/all_flash.%@.production/LLB.%@.RELEASE.img3", deviceType,deviceType];
			
			NSString *new_Path = [[old_Name stringByDeletingPathExtension] stringByAppendingPathComponent:new_Name];
			[[NSFileManager defaultManager] movePath:old_Name toPath:new_Name handler:nil];
			
			NSLog(@"%@",defaultManager);
			
			// Do the final step :-)
	
			
			NSString *Mainfest = [NSString stringWithFormat:@"/tmp/ipsw/Firmware/all_flash/all_flash.%@.production/.DS_Store",deviceType,deviceType];
			NSError *error2;
			BOOL success2 = [[NSFileManager defaultManager] removeItemAtPath:Mainfest error:&error2];
			if ( !success2 )
			{
				NSLog(@"Failed to Delete Manifest: %@",Mainfest);
			}
			
			NSString *Mainfest2 = [NSString stringWithFormat:@"/tmp/ipsw/.DS_Store",deviceType,deviceType];
			NSError *error3;
			BOOL success3 = [[NSFileManager defaultManager] removeItemAtPath:Mainfest2 error:&error3];
			if ( !success3 )
			{
				NSLog(@"Failed to Delete Manifest: %@",Mainfest2);
			}
			
			NSLog(@"Deleted manifest: %@", Mainfest);
			
		
			
			NSTimer *timer;
			
			timer = [NSTimer scheduledTimerWithTimeInterval: 20.5
													 target: self
												   selector: @selector(handleTimer:)
												   userInfo: nil
													repeats: NO];
			
			
			
			
		}
		

	}
	
	[panel release];
}

- (void) handleTimer: (NSTimer *) timer
{
    [progressInfo setStringValue:@"Rebuilding IPSW..."];
	
	// Woohoo now we need to zip everything back up and do the renaming ;-)
	
	// Delete a previous CUSTOM-IPSW that DFUBoot created... - FIX
	NSString* pcuser = [NSString stringWithFormat:@"%@", CSCopyUserName(1)];
	NSString *oldDI = [NSString stringWithFormat:@"/Users/%@/Desktop/DFUBoot_Custom_Restore.ipsw",pcuser];
	NSError *error;
	BOOL success = [[NSFileManager defaultManager] removeItemAtPath:oldDI error:&error];
	if ( !success )
	{
		NSLog(@"Failed to delete previous cooked IPSW :-( --> %@",oldDI);
	}
	
	NSLog(@"Deleted previous cooked IPSW: %@",oldDI);
	
	/* Assumes sourcePath and targetPath are both
	 valid, standardized paths. */
	
	NSString* sourcePath = @"/tmp/ipsw";
	
	// Computer User
	NSString* cuser = [NSString stringWithFormat:@"%@", CSCopyUserName(1)];
	
	NSString* targetPath = [NSString stringWithFormat:@"/Users/%@/Desktop/DFUBoot_Custom_Restore.zip", cuser];
	
	// Create the zip task
	NSTask * backupTask = [[NSTask alloc] init];
	[backupTask setLaunchPath:@"/usr/bin/ditto"];
	[backupTask setArguments:
	 [NSArray arrayWithObjects:@"-c", @"-k", @"-X", @"--rsrc", 
	  sourcePath, targetPath, nil]];
	
	// Launch it and wait for execution
	[backupTask launch];
	[backupTask waitUntilExit];
	
	// Handle the task's termination status
	if ([backupTask terminationStatus] != 0)
		NSLog(@"Sorry, didn't work.");
	
	// You *did* remember to wash behind your ears ...
	// ... right?
	[backupTask release];
	
	NSLog(@"Successfully created a zip file with the IPSW contents...");
	
	timer = [NSTimer scheduledTimerWithTimeInterval: 30.5
											 target: self
										   selector: @selector(spitFile:)
										   userInfo: nil
											repeats: NO];
} 

- (void) spitFile: (NSTimer *) timer
{
    [progressInfo setStringValue:@"Finializing..."];
	
	// Change .zip to .ipsw
	
	// Computer User again...
	NSString* cuser = [NSString stringWithFormat:@"%@", CSCopyUserName(1)];
	
	NSString* oldFileName = [NSString stringWithFormat:@"/Users/%@/Desktop/DFUBoot_Custom_Restore.zip", cuser];
	NSString* newFileName = [NSString stringWithFormat:@"/Users/%@/Desktop/DFUBoot_Custom_Restore.ipsw", cuser];
	
	NSString *newPath = [[oldFileName stringByDeletingPathExtension] stringByAppendingPathComponent:newFileName];
	[[NSFileManager defaultManager] movePath:oldFileName toPath:newFileName handler:nil];
	
	NSLog(@"Successfully created custom IPSW: %@", newFileName);
	
	NSTimer *timer2;
	
	timer2 = [NSTimer scheduledTimerWithTimeInterval: 20.5
											 target: self
										   selector: @selector(done:)
										   userInfo: nil
											repeats: NO];
	
} 

- (void) done: (NSTimer *) timer3
{
	[progressDial stopAnimation:YES];
	[progressDial setNeedsDisplay:YES];
    [progressInfo setStringValue:@"Finished!..."];
	
	// Show the lovely NSPanel ;)
	[hazFinished makeKeyAndOrderFront:timer3];
	
	// Reset everything...
	
	[ipswSel setStringValue:@"No IPSW Selected..."];
	[browseIPSW setEnabled:YES];
	[browseIPSW setNeedsDisplay:YES];
	[cancelProcess setEnabled:NO];
	[cancelProcess setNeedsDisplay:YES];
	
	// Delete temp folder...
	
	NSString *tmpFld = @"/tmp/ipsw";
	NSError *error;
	BOOL success = [[NSFileManager defaultManager] removeItemAtPath:tmpFld error:&error];
	if ( !success )
	{
		NSLog(@"Failed to Delete temp folder: %@",tmpFld);
	}
	
	NSLog(@"Reset everything...DONE...Delete tmp folder...DONE...Goodbye!");
	

} 

- (IBAction)cancelProc:(id)sender
{
	// Stop the spinning wheel...
	[progressDial stopAnimation:sender];
	
	// Update ProgressInfo
	[progressInfo setStringValue:@"Process Cancelled By User..."];
	[ipswSel setStringValue:@"No IPSW Selected..."];
	[cancelProcess setEnabled:NO];
	[cancelProcess setNeedsDisplay:YES];
	
	// Re-enable the browse button
	[browseIPSW setEnabled:YES];
	[browseIPSW setNeedsDisplay:YES];
	
	// Delete folder ./tmp/ipsw for new control
	NSError *error;
	BOOL success = [[NSFileManager defaultManager] removeItemAtPath:@"/tmp/ipsw" error:&error];
	if ( !success )
	{
		
	}
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application
	
	[cancelProcess setEnabled:NO];
	[cancelProcess setNeedsDisplay:YES];
	
	// Show a notification to users when the app launches...
	NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:@"Warning"];
    [alert setInformativeText:@"DFUBoot is only for people who require access to DFU mode, that can't access it the normal way e.g. Broken Home + Sleep/Wake buttons. This will patch any IPSW to be used in iTunes to restore your device, however it will not restore it will put your device into a DFU loop so you can use DFU mode for whatever reason you need it for."];
    [alert setAlertStyle:NSCriticalAlertStyle];
	[alert beginSheetModalForWindow:window
                      modalDelegate:self
	 
					 didEndSelector:@selector(closeWarning:returnCode:
											  contextInfo:)
                        contextInfo:nil];
	
	// Delete folder ./tmp/ipsw for new control
	NSError *error;
	BOOL success = [[NSFileManager defaultManager] removeItemAtPath:@"/tmp/ipsw" error:&error];
	if ( !success )
	{
		
	}
	
	NSLog(@"Deleted temp folder: /tmp/ipsw");
	
	// Recreate folder
	NSString * cPathName = @"/tmp/ipsw";// cPathName is your specified path
	
	
	
	NSFileManager *fm = [NSFileManager defaultManager];
	[fm createDirectoryAtPath:cPathName withIntermediateDirectories:TRUE
				   attributes:nil error:nil]; 
	
	NSLog(@"Created temp folder: %@", cPathName);
	
	
}

- (void)closeWarning:(NSAlert *)alert
	  returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    NSLog(@"User has read the warning, and clicked OK...");
	
    [alert release];
}

@end
