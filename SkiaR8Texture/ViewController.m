//
//  ViewController.m
//  SkiaR8Texture
//
//  Created by lvpengwei on 2021/7/15.
//

#import "ViewController.h"
#import "SkiaLayer.h"

@interface ViewController ()

@property (nonatomic, weak) SkiaLayer *skiaLayer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    SkiaLayer *skiaLayer = [[SkiaLayer alloc] init];
    skiaLayer.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    [self.view.layer addSublayer:skiaLayer];
    self.skiaLayer = skiaLayer;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.skiaLayer draw];
}

@end
