//
//  CellBackground.m
//  TableDesignRevisited
//
//  Created by Matt Gallagher on 27/04/09.
//  Copyright 2009 Matt Gallagher. All rights reserved.
//
//  This software is provided 'as-is', without any express or implied
//  warranty. In no event will the authors be held liable for any damages
//  arising from the use of this software. Permission is granted to anyone to
//  use this software for any purpose, including commercial applications, and to
//  alter it and redistribute it freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//     claim that you wrote the original software. If you use this software
//     in a product, an acknowledgment in the product documentation would be
//     appreciated but is not required.
//  2. Altered source versions must be plainly marked as such, and must not be
//     misrepresented as being the original software.
//  3. This notice may not be removed or altered from any source
//     distribution.
//

#import "CellBackground.h"
#import "RoundRect.h"
#import <QuartzCore/QuartzCore.h>

static CGGradientRef CellBackgroundGradient(BOOL selected, UIColor *contentColorTop, UIColor *contentColorBottom)
{
	static CGGradientRef backgroundGradient = NULL;
	static CGGradientRef selectedBackgroundGradient = NULL;
	
    if (!contentColorTop && !contentColorBottom) 
    {
        if (selected)
        {
            contentColorTop = [UIColor colorWithRed:0 green:0 blue:0 alpha:.7];
            contentColorBottom = [UIColor colorWithRed:0 green:0 blue:0 alpha:.5];
        }
        else
        {
            contentColorTop = [UIColor colorWithRed:0 green:0 blue:1.0 alpha:1.0];
            contentColorBottom = [UIColor colorWithRed:0 green:0 blue:0.88 alpha:1.0];
        }
    }
    
    
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGFloat backgroundColorComponents[3][4];
    memcpy(
           backgroundColorComponents[0],
           CGColorGetComponents(contentColorTop.CGColor),
           sizeof(CGFloat) * 4);
    memcpy(
           backgroundColorComponents[1],
           CGColorGetComponents(contentColorTop.CGColor),
           sizeof(CGFloat) * 4);
    memcpy(
           backgroundColorComponents[2],
           CGColorGetComponents(contentColorBottom.CGColor),
           sizeof(CGFloat) * 4);
    
    const CGFloat endpointLocations[3] = {0.0, 0.35, 1.0};
    CGGradientRef gradient =
    CGGradientCreateWithColorComponents(
                                        colorspace,
                                        (const CGFloat *)backgroundColorComponents,
                                        endpointLocations,
                                        3);
    CFRelease(colorspace);
    
    if (selected)
    {
        selectedBackgroundGradient = gradient;
        return selectedBackgroundGradient;
    }
    else
    {
        backgroundGradient = gradient;
    }
	
	return backgroundGradient;
}

@implementation CellBackground

@synthesize position;
@synthesize strokeColor     = _strokeColor;
@synthesize topColor        = _topColor;
@synthesize bottomColor     = _bottomColor;


//
// init
//
// Init method for the object.
//
- (id)initWithTableView:(UITableView*)table indexPath:(NSIndexPath*)index selected:(BOOL)isSelected topColor:(UIColor *)top bottomColor:(UIColor *)bottom
{
	self = [super init];
	if (self != nil)
	{
        [self calculatePositionForIndex:index inTableView:table];
		selected = isSelected;
		groupBackground = [table style] == UITableViewStyleGrouped ? YES : NO;
        self.topColor = top;
        self.bottomColor = bottom;
		self.strokeColor = [UIColor lightGrayColor];
		self.backgroundColor = [UIColor clearColor];
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	}
	return self;
}

//
// layoutSubviews
//
// On rotation/resize/rescale, we need to redraw.
//
- (void)layoutSubviews
{
	[super layoutSubviews];
	
	[self setNeedsDisplay];
}

//
// setPosition:
//
// Makes certain the view gets redisplayed when the position changes
//
// Parameters:
//    aPosition - the new position
//
- (void)setPosition:(PageCellGroupPosition)aPosition
{
	if (position != aPosition)
	{
		position = aPosition;
		[self setNeedsDisplay];
	}
}

// Method added to handle position of cell in Tableview
- (void)calculatePositionForIndex:(NSIndexPath*)indexPath inTableView:(UITableView*)table
{
    if ([table numberOfRowsInSection:indexPath.section] == 1) 
    {
        position = PageCellGroupPositionTopAndBottom;
    }
    else if (indexPath.row == 0)
    {
        position = PageCellGroupPositionTop;
    }
    else if (indexPath.row == ([table numberOfRowsInSection:indexPath.section] - 1))
    {
        position = PageCellGroupPositionBottom;
    }
    else 
    {
        position = PageCellGroupPositionMiddle;
    }
}

//
// drawRect:
//
// Draw the view.
//
- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	const CGFloat CellBackgroundRadius = 10.0;
	if (groupBackground)
	{
		if (position != PageCellGroupPositionTop && position != PageCellGroupPositionTopAndBottom)
		{
			rect.origin.y -= CellBackgroundRadius;
			rect.size.height += CellBackgroundRadius;
		}
		
		if (position != PageCellGroupPositionBottom && position != PageCellGroupPositionTopAndBottom)
		{
			rect.size.height += CellBackgroundRadius;
		}
	}
	
	rect = CGRectInset(rect, 0.5, 0.5);
	
	CGPathRef roundRectPath;
	
	if (groupBackground)
	{
		roundRectPath = NewPathWithRoundRect(rect, CellBackgroundRadius);
		
		CGContextSaveGState(context);
		CGContextAddPath(context, roundRectPath);
		CGContextClip(context);
	}
    
    CGPoint startPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
    CGPoint endPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
        
	CGContextDrawLinearGradient(
		context,
		CellBackgroundGradient(selected, self.topColor, self.bottomColor),
		startPoint,
		endPoint,
		0); 
	
	if (groupBackground)
	{
		CGContextRestoreGState(context);

		CGContextSetStrokeColorWithColor(context, strokeColor.CGColor);
		CGContextAddPath(context, roundRectPath);
		CGContextSetLineWidth(context, 1.0);
		CGContextStrokePath(context);
		
		CGPathRelease(roundRectPath);
	
		if (position != PageCellGroupPositionTop && position != PageCellGroupPositionTopAndBottom)
		{
			rect.origin.y += CellBackgroundRadius;
			rect.size.height -= CellBackgroundRadius;

			CGContextMoveToPoint(context, rect.origin.x, rect.origin.y);
			CGContextAddLineToPoint(context, rect.origin.x + rect.size.width, rect.origin.y);
			CGContextStrokePath(context);
		}
	}
	else
	{
		CGContextSetStrokeColorWithColor(context, strokeColor.CGColor);
		CGContextSetLineWidth(context, 1.0);
		CGContextMoveToPoint(context, rect.origin.x, rect.origin.y + rect.size.height);
		CGContextAddLineToPoint(context, rect.origin.x + rect.size.width, rect.origin.y + rect.size.height);
		CGContextStrokePath(context);
	}
}

@end





