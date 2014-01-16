/*
THClientConnectionController.m
Interactex Client

Created by Juan Haladjian on 24/09/2012.

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

#import "THClientConnectionController.h"
#import "THClientScene.h"
#import "THClientAppViewController.h"
#import "THClientScene.h"
#import "THLilyPad.h"
#import "THPinValue.h"
#import "THPin.h"
#import "THBoardPin.h"
#import "THClientProject.h"
#import "THAssetCollection.h"

@implementation THClientConnectionController

-(id) init{
    self = [super init];
    if(self){
        //servers = [NSMutableArray array];
    }
    return self;
}

-(BOOL)isConnectedToServer {
    return (self.connectedPeerID);
}

-(void)startClient {
    if(session){
        [self stopClient];
    }
    session = [[GKSession alloc] initWithSessionID:kGameKitSessionId displayName:nil sessionMode:GKSessionModeClient];
    [session setDelegate:self];
    [session setDataReceiveHandler:self withContext:nil];
    [session setAvailable:YES];
}

-(void)stopClient {
    if(session){
        [session disconnectFromAllPeers];
        [session setAvailable:NO];
        [session setDataReceiveHandler:nil withContext:nil];
        [session setDelegate:nil];
        session = nil;
        self.connectedPeerID = nil;
    }
}

-(void)disconnectFromServer {
    if(self.isConnectedToServer){
        [session cancelConnectToPeer:self.connectedPeerID];
        [session disconnectFromAllPeers];
    }
    self.connectedPeerID = nil;
    transferAgent = nil;
}

-(void)connectToServerWithPeerID:(NSString*)peerID {
    
    if(!self.isConnectedToServer){
        //[self disconnectFromServer];
        
        //connectedPeerID = peerID;
        [session connectToPeer:peerID withTimeout:10];
    }
}

#pragma mark - Session Delegate

-(void)session:(GKSession *)aSession
          peer:(NSString *)peerID
didChangeState:(GKPeerConnectionState)state {
    
    switch (state) {
        case GKPeerStateUnavailable:{
            //[self removeServerWithPeerId:peerID];
            transferAgent = nil;
            break;
        }
            
        case GKPeerStateAvailable:{//connect to first thing available
            
            [self connectToServerWithPeerID:peerID];
            
            break;
        }

        case GKPeerStateConnected:{
            self.connectedPeerID = peerID;
            
            transferAgent = [THTransferAgent slaveAgentForServerPeerID:peerID session:session];
            transferAgent.delegate = self;
            break;
        }

        case GKPeerStateDisconnected:{
            if([peerID isEqualToString:self.connectedPeerID]){
                self.connectedPeerID = nil;
                transferAgent = nil;
            }
            break;
        }
            
        default:
            break;
    }
}

-(void) session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error{
    NSLog(@"connection failed: %@",error);
}

-(void) session:(GKSession *)session didFailWithError:(NSError *)error{
    NSLog(@"failed %@",error);
}

- (void)receiveData:(NSData *)data
           fromPeer:(NSString *)peer
          inSession:(GKSession *)session
            context:(void *)context {
    
    if(transferAgent)
        [transferAgent receiveData:data];
}

#pragma mark - Transfer Agent Delegate

-(void) agent:(THTransferAgent *)agent madeProgressForCurrentAction:(float)progress{
       
    [self.delegate didMakeProgressForCurrentProject:progress];
}

- (void)agent:(THTransferAgent*)anAgent willBeginAction:(THTransferAgentAction)action {
   
}

- (void)agent:(THTransferAgent*)agent didFinishAction:(THTransferAgentAction)action withObject:(id)object {
    
    if(action == kTransferActionSceneName){
        
        [self.delegate didStartReceivingProjectNamed:object];
        
    } else if(action == kTransferActionScene){
        
        [self.delegate didFinishReceivingProject:object];
        
    } else if(action == kTransferActionAssets){
        /*
        if([object isKindOfClass:[NSArray class]]){
            NSLog(@"asset list");
            
            NSArray * assetDescriptions = [THAssetCollection assetDescriptionsWithMissingAssetsIn:(NSArray*) object];
            [transferAgent queueAction:kTransferActionMissingAssets withObject:assetDescriptions];
            
        } else if([object isKindOfClass:[THAssetCollection class]]){
            // Received exported assets, import to local library and finish
            NSLog(@"<TA:Client> Finished receiving exported assets object from server");
            NSArray * assets = (NSArray*)object;
            [THAssetCollection importAssets:assets];
        }*/
    }
}

- (void)agent:(THTransferAgent *)agent didChangeQueueLengthTo:(NSUInteger)items {
    
}

@end
