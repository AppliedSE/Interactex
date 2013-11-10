//
//  GMPViewController.m
//  iGMP
//
//  Created by Juan Haladjian on 11/6/13.
//  Copyright (c) 2013 Technical University Munich. All rights reserved.
//

#import "GMPViewController.h"
#import "BLE.h"
#import "GMP.h"
#import "GMPBLECommunicationModule.h"

@implementation GMPViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [[BLEDiscovery sharedInstance] startScanningForSupportedUUIDs];
    [BLEDiscovery sharedInstance].discoveryDelegate = self;
    [BLEDiscovery sharedInstance].peripheralDelegate = self;
    
    self.gmpController = [[GMP alloc] init];
    self.gmpController.delegate = self;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark BleDiscoveryDelegate

- (void) discoveryDidRefresh {
}

- (void) peripheralDiscovered:(CBPeripheral*) peripheral {
    [[BLEDiscovery sharedInstance] connectPeripheral:peripheral];
}

- (void) discoveryStatePoweredOff {
    NSLog(@"Powered Off");
}

#pragma mark BleServiceProtocol

-(void) bleServiceDidConnect:(BLEService *)service{
    GMPBLECommunicationModule *communicationModule = [[GMPBLECommunicationModule alloc] init];
    
    service.delegate = self;
    service.dataDelegate = communicationModule;
    service.shouldUseCRC = YES;
    
    communicationModule.bleService = service;
    communicationModule.gmpController = self.gmpController;
    
    self.gmpController.communicationModule = communicationModule;
    
    
    //self.gmpController.delegate = gmpDelegate;
}

-(void) bleServiceDidDisconnect:(BLEService *)service{
    NSLog(@"disconnected");
        self.connectionButton.enabled = YES;
}

-(void) bleServiceIsReady:(BLEService *)service{
    NSLog(@"connected");
    self.connectionButton.enabled = NO;
}


-(void) bleServiceDidReset {
}

-(void) reportMessage:(NSString*) message{
    NSLog(@"%@",message);
}


#pragma mark UI Interaction

- (IBAction)reconnectTapped:(id)sender {
    
    NSArray * peripherals = [BLEDiscovery sharedInstance].foundPeripherals;
    
    if(peripherals.count > 0){
        CBPeripheral * peripheral = [peripherals objectAtIndex:0];
        [[BLEDiscovery sharedInstance] connectPeripheral:peripheral];
    } else {
        [[BLEDiscovery sharedInstance] startScanningForSupportedUUIDs];
    }
}

- (IBAction)sendFirmwareTapped:(id)sender {
    [self.gmpController sendFirmwareRequest];
}

- (IBAction)sendModesTapped:(id)sender {
    
    pin_t pinModes[3];
    
    pinModes[0].index = 4;
    pinModes[1].index = 5;
    pinModes[2].index = 9;
    
    pinModes[0].capability = kGMPPinModeOutput;
    pinModes[1].capability = kGMPPinModeOutput;
    pinModes[2].capability = kGMPPinModePWM;
    
    [self.gmpController sendPinModesForPins:pinModes count:3];
    //[self.gmpController sendPinModeForPin:4 mode:kGMPPinModeOutput];
}

- (IBAction)sendHighTapped:(id)sender {

    [self.gmpController sendDigitalOutputForPin:4 value:1];
}

- (IBAction)sendLOWTapped:(id)sender {
    [self.gmpController sendDigitalOutputForPin:4 value:0];
}

- (IBAction)sendDigitalReadTapped:(id)sender {
    
    [self.gmpController sendDigitalReadForPin:4];
}

- (IBAction)sendAnalogReadTapped:(id)sender {
    [self.gmpController sendAnalogReadForPin:14];
}

- (IBAction)startDigitalReadTapped:(id)sender {
    reportingDigital = !reportingDigital;
    [self.gmpController sendReportRequestForDigitalPin:5 reports:reportingDigital];
    
    if(reportingDigital){
        [self.digitalReportButton setTitle:@"Stop Digital Read" forState:UIControlStateNormal];
        self.digitalReportButton.tintColor = [UIColor redColor];
    } else {
        [self.digitalReportButton setTitle:@"Start Digital Read" forState:UIControlStateNormal];
        self.digitalReportButton.tintColor = nil;
    }
}

- (IBAction)startAnalogReadTapped:(id)sender {
    
    reportingAnalog = !reportingAnalog;
    
    [self.gmpController sendReportRequestForAnalogPin:14 reports:reportingAnalog];
    
    if(reportingAnalog){
        [self.analogReportButton setTitle:@"Stop Analog Read" forState:UIControlStateNormal];
        self.analogReportButton.tintColor = [UIColor redColor];
    } else {
        [self.analogReportButton setTitle:@"Start Analog Read" forState:UIControlStateNormal];
        self.analogReportButton.tintColor = nil;
    }
}

- (IBAction)sendAnalogOutputTapped:(id)sender {
    [self.gmpController sendAnalogWriteForPin:9 value:120];
}

//I2C

- (IBAction)sendI2CReadTapped:(id)sender {
    [self.gmpController sendI2CStartReadingAddress:24 reg:40 size:6];//Juan's accelerometer
}

- (IBAction)sendI2CWriteTapped:(id)sender {
    
    uint8_t buf[2];
    [GMPHelper valueAsTwo7bitBytes:39 buffer:buf];
    [self.gmpController sendI2CWriteToAddress:24 reg:32 values:buf numValues:1];
}

- (IBAction)sendI2CStartReadingTapped:(id)sender{
    
    //[self.gmpController sendI2CReadAddress:104 reg:0x3B size:6];//Kyle accelerometer
    [self.gmpController sendI2CStartReadingAddress:24 reg:40 size:6];//Juan's accelerometer
}

- (IBAction)sendI2CStopTapped:(id)sender {
    [self.gmpController sendI2CStopStreamingAddress:104];
}


- (IBAction)sendResetTapped:(id)sender {
    [self.gmpController sendResetRequest];
}


#pragma mark - Firmata Message Handles

-(void) gmpController:(GMP*) gmpController didReceiveFirmwareName: (NSString*) name{
    self.textField.text = [NSString stringWithFormat:@"firmware name: %@\n",name];
    
    [self.gmpController sendResetRequest];
    [self.gmpController sendCapabilitiesRequest];
}

-(void) gmpController:(GMP*) gmpController didReceiveCapabilityResponseForPin:(pin_t) pin{
    NSLog(@"capability: %d %d",pin.index,pin.capability);
    
    self.textField.text = [self.textField.text stringByAppendingString:[NSString stringWithFormat:@"capability received: %d %d\n",pin.index,pin.capability]];
}
/*
-(void) gmpController:(GMP*) gmpController didReceivePinStateResponseForPin:(NSInteger) pin state:(NSInteger) state{
    
    self.textField.text = [NSString stringWithFormat:@"state received: %d %d",pin,state];
}*/

-(void) gmpController:(GMP*) gmpController didReceiveDigitalMessageForPin:(NSInteger) pin value:(BOOL) value{
    
    self.textField.text = [self.textField.text stringByAppendingString:[NSString stringWithFormat:@"digital message received: %d %d",pin,value]];
}

-(void) gmpController:(GMP*) gmpController didReceiveAnalogMessageForPin:(NSInteger) pin value:(NSInteger) value{
    
    self.textField.text = [self.textField.text stringByAppendingString:[NSString stringWithFormat:@"analog message received: %d %d",pin,value]];
}

-(void) gmpController:(GMP*) gmpController didReceiveI2CReply:(uint8_t*) buffer length:(NSInteger) length{
    
    uint8_t value1 = buffer[0];
    uint8_t value2 = buffer[1];
    
    NSInteger value = value1 | (value2 << 7);
    
    self.textField.text = [self.textField.text stringByAppendingString:[NSString stringWithFormat:@"i2c reply received: %d ...",value]];
}

@end