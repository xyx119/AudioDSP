//
//  ViewController.m
//  AudioDSP
//
//  Created by Eric on 1/10/16.
//  Copyright © 2016 Eric. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"

#define IP_DEFAULT   @"IP_DEFAULT"

static  AppDelegate *app = nil;

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    NSString * defaultIP = [[NSUserDefaults standardUserDefaults] stringForKey:IP_DEFAULT];
    self.tfIPAddress.text = defaultIP;
    
    self.lbLocalIPAddress.text = [NSString stringWithFormat:@"Local IP Address: %@", [app getLocalIPAddress]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)clickedStartButton:(id)sender {
    
    if ([self.tfIPAddress.text length] == 0){
        return;
    }
    
    [self.tfIPAddress resignFirstResponder];
    
    [[NSUserDefaults standardUserDefaults] setObject:self.tfIPAddress.text forKey: IP_DEFAULT];
    
    if ( [self.btnRun.currentTitle isEqualToString: @"Start" ]){
        
        [app start:self.tfIPAddress.text];
        [self.btnRun setTitle:@"End" forState:UIControlStateNormal];
    }
    else{
        [app stop];
        [self.btnRun setTitle:@"Start" forState:UIControlStateNormal];
    }

    
}
@end
