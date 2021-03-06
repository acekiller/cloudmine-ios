#import "SPKVONotificationCenter.h"
#import <libkern/OSAtomic.h>
#import <objc/message.h>

// Inspired by http://www.mikeash.com/svn/MAKVONotificationCenter/MAKVONotificationCenter.m


static NSString *SPKVOContext = @"SPKVObservation";
typedef void (*SPKVOCallbackFunc)(id, SEL, NSDictionary*, id, NSString *);

@interface SPKVObservation ()
@property(nonatomic, assign) id observer;
@property(nonatomic, assign) id observed;
@property(nonatomic, copy)   NSString *keyPath;
@property(nonatomic)         SEL selector;
@property(nonatomic, copy) SPKVOCallback callback;
@end


@implementation SPKVObservation
@synthesize observer = _observer, observed = _observed, selector = _sel, keyPath = _keyPath, callback = _callback;
-(id)initWithObserver:(id)observer observed:(id)observed keyPath:(NSString*)keyPath selector:(SEL)sel callback:(SPKVOCallback)callback options:(NSKeyValueObservingOptions)options;
{
	_observer = observer;
	_observed = observed;
	_sel = sel;
	self.callback = callback;
	self.keyPath = keyPath;
	[_observed addObserver:self forKeyPath:keyPath options:options context:SPKVOContext];
	return self;
}
-(void)dealloc;
{
	[self invalidate];
	[_keyPath release];
	[super dealloc];
}
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if(context != SPKVOContext) return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	
	if(_callback)
		_callback(change, object, keyPath);
	else if(_sel)
		((SPKVOCallbackFunc)objc_msgSend)(_observer, _sel, change, object, keyPath);
	else
		[_observer observeValueForKeyPath:keyPath ofObject:object change:change context:self];
}
-(id)invalidate;
{
	[_observed removeObserver:self forKeyPath:_keyPath];
	_observed = nil;
	return self;
}
@end



@implementation SPKVONotificationCenter
+ (id)defaultCenter
{
	static SPKVONotificationCenter *center = nil;
	if(!center)
	{
		SPKVONotificationCenter *newCenter = [self new];
		if(!OSAtomicCompareAndSwapPtrBarrier(nil, newCenter, (void *)&center))
			[newCenter release];
	}
	return center;
}
-(SPKVObservation*)addObserver:(id)observer toObject:(id)observed forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options;
{
	return [self addObserver:observer toObject:observed forKeyPath:keyPath options:options selector:NULL];
}
-(SPKVObservation*)addObserver:(id)observer toObject:(id)observed forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options selector:(SEL)sel;
{
	SPKVObservation *helper = [[[SPKVObservation alloc] initWithObserver:observer observed:observed keyPath:keyPath selector:sel callback:nil options:options] autorelease];
	return helper;
}
-(SPKVObservation*)addObserver:(id)observer toObject:(id)observed forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options callback:(SPKVOCallback)callback;
{
	SPKVObservation *helper = [[[SPKVObservation alloc] initWithObserver:observer observed:observed keyPath:keyPath selector:NULL callback:callback options:options] autorelease];
	return helper;
}
@end

@implementation NSObject (SPKVONotificationCenterAddition)
-(SPKVObservation*)sp_addObserver:(NSObject*)observer forKeyPath:(NSString*)kp options:(NSKeyValueObservingOptions)options selector:(SEL)sel
{
	return [[SPKVONotificationCenter defaultCenter] addObserver:observer toObject:self forKeyPath:kp options:options selector:sel];
}
-(SPKVObservation*)sp_addObserver:(NSObject*)observer forKeyPath:(NSString*)kp options:(NSKeyValueObservingOptions)options callback:(void(^)(NSDictionary*, id, NSString*))callback
{
	return [[SPKVONotificationCenter defaultCenter] addObserver:observer toObject:self forKeyPath:kp options:options callback:callback];
}
@end