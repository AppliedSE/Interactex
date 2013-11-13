/*
THClientAppViewController.m
Interactex Designer

Created by Juan Haladjian on 10/07/2013.

Interactex Designer is a configuration tool to easily setup, simulate and connect e-Textile hardware with smartphone functionality. Interactex Client is an app to store and replay projects made with Interactex Designer.

www.interactex.org

Copyright (C) 2013 TU Munich, Munich, Germany; DRLab, University of the Arts Berlin, Berlin, Germany; Telekom Innovation Laboratories, Berlin, Germany
	
Contacts:
juan.haladjian@cs.tum.edu
katharina.bredies@udk-berlin.de
opensource@telekom.de

    
The first version of the software was designed and implemented as part of "Wearable M2M", a joint project of UdK Berlin and TU Munich, which was founded by Telekom Innovation Laboratories Berlin. It has been extended with funding from EIT ICT, as part of the activity "Connected Textiles".

Interactex is built using the Tango framework developed by TU Munich.

In the Interactex software, we use the GHUnit (a test framework for iOS developed by Gabriel Handford) and cocos2D libraries (a framework for building 2D games and graphical applications developed by Zynga Inc.). 
www.cocos2d-iphone.org
github.com/gabriel/gh-unit

Interactex also implements the Firmata protocol. Its software serial library is based on the original Arduino Firmata library.
www.firmata.org

All hardware part graphics in Interactex Designer are reproduced with kind permission from Fritzing. Fritzing is an open-source hardware initiative to support designers, artists, researchers and hobbyists to work creatively with interactive electronics.
www.frizting.org


This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
 
This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 
You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#import "THClientAppViewController.h"
#import "THSimulableWorldController.h"
#import "THClientProject.h"

#import "THView.h"
#import "THiPhone.h"
#import "THClientProjectProxy.h"

#import "THLilyPad.h"
#import "THBoardPin.h"
#import "THPinValue.h"
#import "THElementPin.h"
#import "THCompass.h"

#import "THLabel.h"
#import "THBLECommunicationModule.h"

@implementation THClientAppViewController
/*
-(void) pushLilypadStateToAllVirtualClients{
    THClientProject * project = [THSimulableWorldController sharedInstance].currentProject;
    NSArray * lilypins = project.lilypad.pins;
    NSMutableArray * pins = [NSMutableArray array];
    
    for (THBoardPin * pin in lilypins) {
        if(pin.mode == kPinModeDigitalOutput && pin.hasChanged){
            THPinValue * pinValue = [[THPinValue alloc] init];
            pinValue.type = pin.type;
            pinValue.value = pin.currentValue;
            pinValue.number = pin.number;
 
            //dont send if value is reserved for protocol (change protocol in future)
            [pins addObject:pinValue];
            pin.hasChanged = NO;
            
            NSLog(@"iPad sending %d %d",pin.number,pin.currentValue);
        }
    }
    
    [_transferAgent queueAction:kTransferActionPinState withObject:pins];
}*/

/*
-(void) pushLilypadStateToRealClient{
    THClientProject * project = [THSimulableWorldController sharedInstance].currentProject;
    NSArray * lilypins = project.lilypad.pins;
    
    for (THBoardPin * pin in lilypins) {
        if((pin.mode == kPinModeDigitalOutput || pin.mode == kPinModePWM || pin.mode == kPinModeBuzzer) && pin.hasChanged){
            NSLog(@"ble sending %d %d",pin.number,pin.currentValue);
            
            //if(pin.currentValue != kMsgPinValueStarted && pin.currentValue != kMsgPinModeStarted){
                [_bleService outputPin:pin.number value:pin.currentValue];
            //}
            pin.hasChanged = NO;
        }
    }
}
*/

-(NSString*) title{
    THClientProject * project = [THSimulableWorldController sharedInstance].currentProject;
    return project.name;
}

-(void) loadUIObjects{
        
    THiPhone * iPhone = self.currentProject.iPhone;
    
    CGSize size = iPhone.currentView.view.frame.size;
    
    self.view = iPhone.currentView.view;
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    
    THIPhoneType type = screenHeight < 500;
    CGFloat viewHeight = self.view.bounds.size.height;
    
    //CGFloat navigationBarOffset = screenHeight - viewHeight;
    
    for (THView * object in self.currentProject.iPhoneObjects) {

        if(!self.showingPreset){
/*
            NSLog(@"pos y: %f",object.position.y);
            NSLog(@"iphone pos y: %f",iPhone.position.y);*/
            
            float relx = (object.position.x - iPhone.position.x + size.width/2) / kiPhoneFrames[type].size.width;
            float rely = (object.position.y - iPhone.position.y + size.height/2) / kiPhoneFrames[type].size.height;
            
            CGPoint translatedPos = CGPointMake(relx * screenWidth ,rely * viewHeight);
            
            object.position = translatedPos;
        }
        
        [object addToView:self.view];
    }
    
    [self.currentProject startSimulating];
}

-(void) stopActivityIndicator {
    
    self.view.userInteractionEnabled = YES;
    self.view.alpha = 1.0f;
    if(_activityIndicator != nil){
        [_activityIndicator removeFromSuperview];
        _activityIndicator = nil;
    }
}

-(void) startActivityIndicator {
    
    self.view.userInteractionEnabled = NO;
    
    self.view.alpha = 0.5f;
    
    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    
    _activityIndicator.center = self.view.center;
    [_activityIndicator startAnimating];
    
    [self.view addSubview:_activityIndicator];
}

-(void) viewDidLoad{
    
    [super viewDidLoad];
    
    [BLEDiscovery sharedInstance].discoveryDelegate = self;
    [BLEDiscovery sharedInstance].peripheralDelegate = self;
    
    self.gmpController = [[GMP alloc] init];
    self.gmpController.delegate = self;
}

-(void) viewWillAppear:(BOOL)animated{
    
    self.currentProject = [THSimulableWorldController sharedInstance].currentProject;
    
    if(self.currentProject){
        
        [[BLEDiscovery sharedInstance] startScanningForSupportedUUIDs];
        
        
        [self setTitle:self.currentProject.name];
        
        [self loadUIObjects];
        [self addPinObservers];
        
        //[self updateStartButton];
    }
}

-(void) viewWillDisappear:(BOOL)animated{
    
    if(!self.showingPreset){
        UIImage * image = [THUtils screenshot];
        THClientProjectProxy * proxy = [THSimulableWorldController sharedInstance].currentProjectProxy;
        proxy.image = image;
    }
    
    [self removePinObservers];
    [self disconnectFromBle];
    
    /*
    if(!proxy.image){
        
        NSString *screenshotFile = [self.currentProject.name stringByAppendingString:@".png"];
        NSString *screenshotPath = [TFFileUtils dataFile:screenshotFile inDirectory:kProjectImagesDirectory];
        proxy.image = image;
        
        //[TFFileUtils saveImageToFile:image file:screenshotPath];
    }*/
}

-(void) viewDidDisappear:(BOOL)animated{
    
    [THSimulableWorldController sharedInstance].currentProjectProxy = nil;
    [THSimulableWorldController sharedInstance].currentProject = nil;
}

- (void)viewDidUnload {
    [super viewDidUnload];
}
/*
-(void) updateStartButton{
    
    if([BLEDiscovery sharedInstance].connectedService){
        
        self.startButton.tintColor = [UIColor redColor];
        self.startButton.title = @"Stop";
        self.startButton.enabled = YES;
        
    } else {
        
        self.startButton.tintColor = nil;
        self.startButton.title = @"Start";
        
        if([BLEDiscovery sharedInstance].foundPeripherals.count > 0){
            
            self.startButton.enabled = YES;
            
        } else {
            
            self.startButton.enabled = NO;
        }
    }
}*/

#pragma mark Pins Observing

-(void) addPinObservers{
    
    THClientProject * project = [THSimulableWorldController sharedInstance].currentProject;
    
    for (THBoardPin * pin in project.lilypad.pins) {
        [pin addObserver:self forKeyPath:@"value" options:NSKeyValueObservingOptionNew context:nil];
    }
}

-(void) removePinObservers{
    THClientProject * project = [THSimulableWorldController sharedInstance].currentProject;
    
    for (THBoardPin * pin in project.lilypad.pins) {
        [pin removeObserver:self forKeyPath:@"value"];
    }
}

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    
    if([keyPath isEqualToString:@"value"]){
        
        THBoardPin * pin = object;
                
        if(pin.mode == kPinModeDigitalOutput){
            
            [self sendDigitalOutputForPin:pin];
            
        } else if(pin.mode == kPinModePWM){
            
            [self sendAnalogOutputForPin:pin];
        }
    }
}

#pragma mark UI Interaction

-(IBAction)startButtonTapped:(id)sender {
    if([BLEDiscovery sharedInstance].connectedService){
        
        [self disconnectFromBle];
        
    } else {
        
        [self updateStartButtonToStarting];
        [self connectToBle];
    }
}

#pragma mark Ble Interaction

-(void) connectToBle{
    
    if(![BLEDiscovery sharedInstance].currentPeripheral && [BLEDiscovery sharedInstance].foundPeripherals.count> 0){
        CBPeripheral * peripheral = [[BLEDiscovery sharedInstance].foundPeripherals objectAtIndex:0];
        [[BLEDiscovery sharedInstance] connectPeripheral:peripheral];
    }
}

-(void) disconnectFromBle{
    if([BLEDiscovery sharedInstance].currentPeripheral){
        [[BLEDiscovery sharedInstance].connectedService stop];
        [[BLEDiscovery sharedInstance] disconnectCurrentPeripheral];
    }
}

#pragma mark LeDiscoveryDelegate

- (void) discoveryDidRefresh {
    //[self updateModeButton];
    
    /*
     self.bleService.delegate = self;
     
     [self.currentlyConnectedLabel setText:[peripheral name]];
     [self.currentlyConnectedLabel setEnabled:YES];*/
}

- (void) peripheralDiscovered:(CBPeripheral*) peripheral {
    
    //[self updateStartButton];
    
    //[[LeDiscovery sharedInstance] connectPeripheral:peripheral];
}

- (void) discoveryStatePoweredOff {
    //[self updateStartButton];
    
    NSLog(@"Powered Off");
}


#pragma mark BleServiceProtocol

-(void) updateStartButtonToStarting{
    
    self.startButton.tintColor = nil;
    self.startButton.title = @"Starting";
    self.startButton.enabled = NO;
}

-(void) updateStartButtonToStop{
    
    self.startButton.tintColor = [UIColor redColor];
    self.startButton.title = @"Stop";
    self.startButton.enabled = YES;
}

-(void) updateStartButtonToStart{
    
    self.startButton.tintColor = nil;
    self.startButton.title = @"Start";
    self.startButton.enabled = YES;
}

-(void) bleServiceDidConnect:(BLEService*) service{
    service.delegate = self;
    service.shouldUseCRC = YES;
    service.shouldUseTurnBasedCommunication = YES;
}

-(void) bleServiceDidDisconnect:(BLEService*) service{
    
    NSLog(@"disconnected");
    
    service.delegate = nil;
    service.dataDelegate = nil;
    
    [self updateStartButtonToStart];
}

-(void) bleServiceIsReady:(BLEService*) service{
    NSLog(@"is ready");
    
    [self updateStartButtonToStop];
    
    THBLECommunicationModule * bleCommunicationModule = [[THBLECommunicationModule alloc] init];
    bleCommunicationModule.bleService = service;
    bleCommunicationModule.gmpController = self.gmpController;
    
    service.dataDelegate = bleCommunicationModule;
    
    self.gmpController.communicationModule = bleCommunicationModule;
    
    [self.gmpController sendFirmwareRequest];
}

- (void) bleServiceDidReset {
    NSLog(@"ble service reseted");
    //_bleService = nil;
}

#pragma mark GMP Sending

-(void) sendDigitalOutputForPin:(THBoardPin*) pin{
    [self.gmpController sendDigitalOutputForPin:pin.number value:pin.value];
}

-(void) sendAnalogOutputForPin:(THBoardPin*) pin{
    [self.gmpController sendAnalogWriteForPin:pin value:pin.value];
}

-(void) sendPinModes{
    
    THClientProject * project = [THSimulableWorldController sharedInstance].currentProject;
    
    for (THBoardPin * pin in project.lilypad.pins) {
        
        if(pin.type == kPintypeDigital && pin.mode != kPinModeUndefined && pin.attachedElementPins.count > 0){
            
            [self.gmpController sendPinModeForPin:pin.number mode:pin.mode];
        }
    }
}

-(void) sendInputRequests{
    
    THClientProject * project = [THSimulableWorldController sharedInstance].currentProject;
    
    for (THBoardPin * pin in project.lilypad.pins) {
        
        if(pin.attachedElementPins.count > 0){
            
            if(pin.mode == kPinModeDigitalInput && pin.attachedElementPins.count > 0){
                
                [self.gmpController sendReportRequestForDigitalPin:pin.number reports:YES];
                
            } else if(pin.mode == kPinModeAnalogInput && pin.attachedElementPins.count > 0){
                
                [self.gmpController sendReportRequestForAnalogPin:pin.number reports:YES];
            }
        }
    }
}

#pragma mark - GMP Message Handles

-(void) gmpController:(GMP*) gmpController didReceiveFirmwareName: (NSString*) name{
    
    if([name isEqualToString:kGMPFirmwareName]){
        [self.gmpController sendResetRequest];
        
        [self sendPinModes];
        [self sendInputRequests];
    }
}

-(void) gmpController:(GMP*) gmpController didReceiveCapabilityResponseForPins:(uint8_t*) buffer count:(NSInteger) count{
    
}

-(void) gmpController:(GMP*) gmpController didReceivePinStateResponseForPin:(NSInteger) pin mode:(GMPPinMode) mode{
    
    NSLog(@"received mode %d %d",pin,mode);
}

-(void) gmpController:(GMP *)gmpController didReceiveDigitalMessageForPin:(NSInteger)pin value:(BOOL)value{
    
    //NSLog(@"digital msg for pin: %d",pin);
    
    THClientProject * project = [THSimulableWorldController sharedInstance].currentProject;
    
    for (THBoardPin * pinObj in project.lilypad.pins) {
        if(pinObj.number == pin){
            
            [pinObj removeObserver:self forKeyPath:@"value"];
            pinObj.value = value;
            [pinObj addObserver:self forKeyPath:@"value" options:NSKeyValueObservingOptionNew context:nil];
            
            break;
        }
    }
}

-(void) gmpController:(GMP *)gmpController didReceiveAnalogMessageForPin:(NSInteger)pin value:(NSInteger)value{
    
    NSLog(@"analog msg for pin: %d",pin);
    /*
    GMPPin * pinObj = [self.analogPins objectAtIndex:pin];
    pinObj.value = value;*/
}

-(void) gmpController:(GMP*) gmpController didReceiveI2CReply:(uint8_t*) buffer length:(NSInteger) length {
    
    //uint8_t address = buffer[2] + (buffer[3] << 7);
    // NSInteger registerNumber = buffer[4];
    /*
    GMPI2CComponent * component = nil;
    for (GMPI2CComponent * aComponent in self.i2cComponents) {
        if(aComponent.address == address){
            component = aComponent;
        }
    }*/
    
    /*
     GMPI2CRegister * reg = [component registerWithNumber:registerNumber];
     if(reg){
     uint8_t values[reg.size];
     NSInteger parseBufCount = 6;
     for (int i = 0; i < reg.size; i++) {
     uint8_t byte1 = buffer[parseBufCount++];
     uint8_t value = byte1 + (buffer[parseBufCount++] << 7);
     values[i] = value;
     }
     NSData * data = [NSData dataWithBytes:values length:reg.size];
     reg.value = data;
     
     }*/
}


@end
