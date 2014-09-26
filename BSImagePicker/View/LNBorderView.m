//
//  LNBorderView.m
//  Pods
//
//  Created by Esteban Torres on 25/9/14.
//
//

#import "LNBorderView.h"

@implementation LNBorderView

- (void)drawRect:(CGRect)rect {
	// Create selection border
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGRect frame = self.bounds;
	[[UIColor colorWithRed:0.341f green:0.78f blue:0.0f alpha:1.0f] set];
	CGContextSetLineWidth(context, 4.0f);
	UIRectFrame(frame);
}

@end
