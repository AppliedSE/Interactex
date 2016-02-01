//
//  THDivisionOperator.m
//  TangoHapps
//
//  Created by Juan Haladjian on 31/01/16.
//  Copyright © 2016 Technische Universität München. All rights reserved.
//

#import "THDivisionOperator.h"

@implementation THDivisionOperator

-(id) init{
    self = [super init];
    if(self){
        
    }
    return self;
}

#pragma mark - Archiving

-(id)copyWithZone:(NSZone *)zone {
    THDivisionOperator * copy = [super copyWithZone:zone];
    
    copy.operand1 = self.operand1;
    copy.operand2 = self.operand2;
    
    return copy;
}

#pragma mark - Methods

-(float) operate{
    
    self.result = (self.operand1 / self.operand2);
    return self.result;
}

-(NSString*) description{
    return @"division";
}

@end
