//
//  UIButton+CLExtensions.m
//  CLMediaPicker
//
// Copyright [2015] [Cromulent Labs, Inc.]
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "UIButton+CLExtensions.h"
#import <objc/runtime.h>

static const NSString *kIndexPathKey = @"IndexPath";
static const NSString *kHitTestEdgeInsets = @"HitTestEdgeInsets";

@implementation UIButton (CLExtensions)

@dynamic indexPath;
@dynamic hitTestEdgeInsets;

- (void)setIndexPath:(NSIndexPath *)indexPath {
	objc_setAssociatedObject(self, &kIndexPathKey, indexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSIndexPath *)indexPath {
	NSIndexPath *indexPath = (NSIndexPath *)objc_getAssociatedObject(self, &kIndexPathKey);
	if (indexPath) {
		return indexPath;
	}
	else {
		return nil;
	}
}

- (void)setHitTestEdgeInsets:(UIEdgeInsets)hitTestEdgeInsets
{
	NSValue *value = [NSValue value:&hitTestEdgeInsets withObjCType:@encode(UIEdgeInsets)];
	objc_setAssociatedObject(self, &kHitTestEdgeInsets, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIEdgeInsets)hitTestEdgeInsets
{
	NSValue *value = objc_getAssociatedObject(self, &kHitTestEdgeInsets);
	if(value)
	{
		UIEdgeInsets edgeInsets; [value getValue:&edgeInsets];
		return edgeInsets;
	}
	else
	{
		return UIEdgeInsetsZero;
	}
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
	if (UIEdgeInsetsEqualToEdgeInsets(self.hitTestEdgeInsets, UIEdgeInsetsZero) || !self.enabled || self.hidden)
	{
		return [super pointInside:point withEvent:event];
	}
	
	CGRect relativeFrame = self.bounds;
	CGRect hitFrame = UIEdgeInsetsInsetRect(relativeFrame, self.hitTestEdgeInsets);
	BOOL hit = CGRectContainsPoint(hitFrame, point);
	return hit;
}

@end
