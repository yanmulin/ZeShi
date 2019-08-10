//
//  ClusterAnnotationView.m
//  officialDemo2D
//
//  Created by yi chen on 14-5-15.
//  Copyright (c) 2014年 AutoNavi. All rights reserved.
//

#import "ClusterAnnotationView.h"
#import "ClusterAnnotation.h"


static CGFloat const ScaleFactorAlpha = 0.3;
static CGFloat const ScaleFactorBeta = 0.4;

/* 返回rect的中心. */
CGPoint RectCenter(CGRect rect)
{
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}

/* 返回中心为center，尺寸为rect.size的rect. */
CGRect CenterRect(CGRect rect, CGPoint center)
{
    CGRect r = CGRectMake(center.x - rect.size.width/2.0,
                          center.y - rect.size.height/2.0,
                          rect.size.width,
                          rect.size.height);
    return r;
}

/* 根据count计算annotation的scale. */
CGFloat ScaledValueForValue(CGFloat value)
{
    return 1.0 / (1.0 + expf(-1 * ScaleFactorAlpha * powf(value, ScaleFactorBeta)));
}

#pragma mark -

@interface ClusterAnnotationView ()

@property (nonatomic, strong) UILabel *countLabel;

@end

@implementation ClusterAnnotationView

#pragma mark Initialization

- (id)initWithAnnotation:(id<MAAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        self.image = [UIImage imageNamed:@"restaraunt-icon"];
        [self.imageView sizeToFit];
        [self setupLabel];
        [self setCount:1];        
    }
    
    return self;
}

#pragma mark Utility

- (void)setupLabel
{
    _countLabel = [[UILabel alloc] initWithFrame:self.frame];
    _countLabel.backgroundColor = [UIColor redColor];
    _countLabel.textColor       = [UIColor whiteColor];
    _countLabel.textAlignment   = NSTextAlignmentCenter;
//    _countLabel.shadowColor     = [UIColor colorWithWhite:0.0 alpha:0.75];
//    _countLabel.shadowOffset    = CGSizeMake(0, -1);
    _countLabel.adjustsFontSizeToFitWidth = YES;
    _countLabel.numberOfLines = 1;
    _countLabel.clipsToBounds = YES;
    _countLabel.font = [UIFont boldSystemFontOfSize:12];
    _countLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    [self addSubview:_countLabel];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    NSArray *subViews = self.subviews;
    if ([subViews count] > 1)
    {
        for (UIView *aSubView in subViews)
        {
            if ([aSubView pointInside:[self convertPoint:point toView:aSubView] withEvent:event])
            {
                return YES;
            }
        }
    }
    if (point.x > 0 && point.x < self.frame.size.width && point.y > 0 && point.y < self.frame.size.height)
    {
        return YES;
    }
    return NO;
}

- (void)setCount:(NSUInteger)count
{
    _count = count;
    
    /* 按count数目设置view的大小. */
    CGRect newBounds = CGRectMake(0, 0, roundf(self.image.size.width * ScaledValueForValue(count)), roundf(self.image.size.width * ScaledValueForValue(count)));
    self.frame = CenterRect(newBounds, self.center);
    
    CGRect newLabelBounds = CGRectMake(0, 0, newBounds.size.width / 3, newBounds.size.height / 3);
    self.countLabel.frame = CenterRect(newLabelBounds, CGPointMake(CGRectGetMaxX(newBounds) - newLabelBounds.size.width / 2, newLabelBounds.size.height / 2));
    self.countLabel.layer.cornerRadius = newLabelBounds.size.width / 2;
    self.countLabel.text = [@(_count) stringValue];
    
    [self setNeedsDisplay];
}

#pragma mark - annimation

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
    
    [self addBounceAnnimation];
}

- (void)addBounceAnnimation
{
    CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    
    bounceAnimation.values = @[@(0.05), @(1.1), @(0.9), @(1)];
    bounceAnimation.duration = 0.6;
    
    NSMutableArray *timingFunctions = [[NSMutableArray alloc] initWithCapacity:bounceAnimation.values.count];
    for (NSUInteger i = 0; i < bounceAnimation.values.count; i++)
    {
        [timingFunctions addObject:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    }
    [bounceAnimation setTimingFunctions:timingFunctions.copy];
    
    bounceAnimation.removedOnCompletion = NO;
    
    [self.layer addAnimation:bounceAnimation forKey:@"bounce"];
}

@end
