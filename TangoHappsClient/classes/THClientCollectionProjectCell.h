/*
THClientCollectionProjectCell.h
Interactex Client

Created by Juan Haladjian on 12/11/2013.

iGMP is an App to control an Arduino board over Bluetooth 4.0. iGMP uses the GMP protocol (based on Firmata): www.firmata.org

www.interactex.org

Copyright (C) 2013 TU Munich, Munich, Germany; DRLab, University of the Arts Berlin, Berlin, Germany; Telekom Innovation Laboratories, Berlin, Germany, 
	
Contacts:
juan.haladjian@cs.tum.edu
k.zhang@utwente.nl
katharina.bredies@udk-berlin.de
opensource@telekom.de

    
It has been created with funding from EIT ICT, as part of the activity "Connected Textiles".


This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
 
This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 
You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#import <UIKit/UIKit.h>

extern const float kShakingEffectAngleInRadians;
extern const float kShakingEffectRotationTime;
extern const float kProjectCellScaleEffectDuration;

@class THClientCollectionProjectCell;

@protocol THClientProjectCellDelegate <NSObject>

-(void) didDeleteProjectCell:(THClientCollectionProjectCell*)cell;
-(void) didRenameProjectCell:(THClientCollectionProjectCell*)cell toName:(NSString*) name;
-(void) didDuplicateProjectCell:(THClientCollectionProjectCell*)cell;

@end

@interface THClientCollectionProjectCell : UICollectionViewCell <UITextFieldDelegate>

@property (nonatomic) BOOL editing;

@property (weak, nonatomic) IBOutlet UITextField * nameTextField;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) id<THClientProjectCellDelegate> delegate;

- (IBAction)deleteTapped:(id)sender;
- (IBAction)textChanged:(id)sender;

-(void) startShaking;
-(void) stopShaking;
-(void) scaleEffect;

@end
