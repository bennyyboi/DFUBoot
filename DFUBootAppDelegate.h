//
//  DFUBootAppDelegate.h
//  DFUBoot
//
//  Created by Ben on 23/10/2010.
//  Copyright 2010 Techizmo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DFUBootAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
	IBOutlet NSTextField *ipswSel;
	IBOutlet NSTextField *progressInfo;
	IBOutlet NSButton *browseIPSW;
	IBOutlet NSButton *cancelProcess;
	IBOutlet NSProgressIndicator *progressDial;
	IBOutlet NSPanel *creditsPane;
	IBOutlet NSButton *acCredits;
	IBOutlet NSButton *closeCredits;
	IBOutlet NSPanel *hazFinished;
}

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, retain) IBOutlet NSTextField *ipswSel;
@property (nonatomic, retain) IBOutlet NSTextField *progressInfo;
@property (nonatomic, retain) IBOutlet NSButton *browseIPSW;
@property (nonatomic, retain) IBOutlet NSButton *cancelProcess;
@property (nonatomic, retain) IBOutlet NSProgressIndicator *progressDial;
@property (nonatomic, retain) IBOutlet NSPanel *creditsPane;
@property (nonatomic, retain) IBOutlet NSPanel *hazFinished;
@property (nonatomic, retain) IBOutlet NSButton *acCredits;
@property (nonatomic, retain) IBOutlet NSButton *closeCredits;

// Actions

- (IBAction)findIPSW:(id)sender;
- (IBAction)cancelProc:(id)sender;
- (IBAction)showCredits:(id)sender;
- (IBAction)hideCredits:(id)sender;

@end
