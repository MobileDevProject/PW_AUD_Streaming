//
//  ViewController.m
//  Opus Demo Final
//
//  Created by iMac on 08/06/17.
//  Copyright © 2017 WOS. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreAudioKit/CoreAudioKit.h>

// return max value for given values
#define max(a, b) (((a) > (b)) ? (a) : (b))
// return min value for given values
#define min(a, b) (((a) < (b)) ? (a) : (b))

#define kOutputBus 0
#define kInputBus 1

// our default sample rate
#define SAMPLE_RATE 8000.00


@interface ViewController ()<socketDemo>
{
    
    __weak IBOutlet UISegmentedControl *segment;
    NSString *strIP;
    NSString *strPort;
    
    __weak IBOutlet UILabel *lblStatus;
    __weak IBOutlet UITextField *txtIp;
    __weak IBOutlet UITextField *txtPort;
    __weak IBOutlet UILabel *lbltitle;

}
@end

@implementation ViewController
@synthesize viewController, audioUnit, audioBuffer, audioProcessor;


- (void)viewDidLoad {
    [super viewDidLoad];
    
    gain = 0;
    

    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        if (granted) {
            
            if (audioProcessor == nil) {
                 audioProcessor = [[AudioProcessor alloc] init];
            }
         
            audioProcessor.delegate = self;
            [audioProcessor start];
            
            audioProcessor.strIp = txtIp.text;
            audioProcessor.strPort = txtPort.text;
            //Encode
            audioProcessor.audioType = 1;
            
            NSLog(@"Microphone Enable...");

            
        }
        else {
            NSLog(@"Microphone Disable...");
            
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"Please enable the Microphone Permission!"
                                         message:@""
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            
            
            UIAlertAction* yesButton = [UIAlertAction
                                        actionWithTitle:@"Setting"
                                        style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * action) {
                                            
                                            // Setting
                                            NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                                            if (url != nil) {
                                                [[UIApplication sharedApplication] openURL:url options:[NSDictionary new] completionHandler:nil];
                                            }

                                        }];
            
            UIAlertAction* noButton = [UIAlertAction
                                       actionWithTitle:@"Cancel"
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction * action) {

                                       //Cancel
                                           
                                       }];
            
            [alert addAction:yesButton];
            [alert addAction:noButton];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentViewController:alert animated:YES completion:nil];
            });

            
            // Microphone disabled code
            
        }
    }];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    
    
    // Do any additional setup after loading the view, typically from a nib.
}
- (void) viewWillAppear:(BOOL)animated{
    //Encode
    audioProcessor.audioType = 1;
    
}

-(void)connectionStatus:(NSString *)status
{
    lbltitle.text = status;
}

-(void)start;
{
    // start the audio unit. You should hear something, hopefully :)
    OSStatus status = AudioOutputUnitStart(audioUnit);
    [self hasError:status:__FILE__:__LINE__];
}


#pragma mark Error handling

-(void)hasError:(int)statusCode:(char*)file:(int)line
{
    if (statusCode) {
        printf("Error Code responded %d in file %s on line %d\n", statusCode, file, line);
        exit(-1);
    }
}

- (IBAction)segment:(UISegmentedControl*)sender {
    
    if(sender.selectedSegmentIndex == 0)
    {
        //Local
        
        audioProcessor.audioType = 0;
    }
    else if(sender.selectedSegmentIndex == 1)
    {
        //Encode
        
        audioProcessor.audioType = 1;

        
    }
    else if(sender.selectedSegmentIndex == 2)
    {
        //Socket
        
        audioProcessor.audioType = 2;

    }
}

- (IBAction)btnConnect:(id)sender {
    
    audioProcessor.strIp = txtIp.text;
    audioProcessor.strPort = txtPort.text;
    
    [audioProcessor connect];
}

-(IBAction)btnDisconnect:(id)sender
{
    audioProcessor.strIp = txtIp.text;
    audioProcessor.strPort = txtPort.text;
    
    [audioProcessor disconnect];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dismissKeyboard {
    [self.view endEditing:YES];
}

@end
