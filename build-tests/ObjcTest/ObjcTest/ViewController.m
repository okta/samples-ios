//
//  ViewController.m
//  ObjcTest
//
//  Created by Ildar Abdullin on 7/22/20.
//  Copyright © 2020 Okta. All rights reserved.
//

#import "ViewController.h"
@import OktaOidc;

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    OktaOidc *oidc = [[OktaOidc alloc] initWithConfiguration:nil error:nil];
    NSLog(@"%@", @(oidc.hasActiveBrowserSession));
}


@end
