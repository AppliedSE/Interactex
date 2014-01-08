//
//  THCompassProperties.m
//  TangoHapps
//
//  Created by Juan Haladjian on 11/14/13.
//  Copyright (c) 2013 Technische Universität München. All rights reserved.
//

#import "THCompassProperties.h"
#import "THCompassEditableObject.h"

@implementation THCompassProperties

-(NSString*) title{
    return @"Compass";
}

-(void) updateTypeControl{
    
    THCompassEditableObject * compass = (THCompassEditableObject*) self.editableObject;
    self.typeControl.selectedSegmentIndex = compass.componentType;
}

-(void) reloadState{
    
    [self updateTypeControl];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)typeControlChanged:(id)sender {
    
    THCompassEditableObject * compass = (THCompassEditableObject*) self.editableObject;
    compass.componentType = self.typeControl.selectedSegmentIndex;
}

@end