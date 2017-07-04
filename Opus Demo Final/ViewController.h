//
//  ViewController.h
//  Opus Demo Final
//
//  Created by iMac on 08/06/17.
//  Copyright © 2017 WOS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "AudioProcessor.h"

@class AudioProcessor;


@interface ViewController : UIViewController
{
    
    // Audio unit
    AudioComponentInstance audioUnit;
    
    // Audio buffers
    AudioBuffer audioBuffer;
    
    
    float gain;

}



@property (weak, nonatomic) IBOutlet UISegmentedControl *modeControl;
@property (retain, nonatomic) ViewController *viewController;
@property (readonly) AudioBuffer audioBuffer;
@property (readonly) AudioComponentInstance audioUnit;
@property (retain, nonatomic) AudioProcessor *audioProcessor;

-(void)start;


@end

