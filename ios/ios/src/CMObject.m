//
//  CMObject.m
//  cloudmine-ios
//
//  Copyright (c) 2011 CloudMine, LLC. All rights reserved.
//  See LICENSE file included with SDK for details.
//

#import "CMObject.h"
#import "NSString+UUID.h"
#import "CMObjectSerialization.h"

@implementation CMObject
@synthesize objectId;

- (id)init {
    return [self initWithObjectId:[NSString stringWithUUID]];
}

- (id)initWithObjectId:(NSString *)theObjectId {
    if (self = [super init]) {
        objectId = theObjectId;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        objectId = [aDecoder decodeObjectForKey:CMInternalObjectIdKey];
        // Introspect and inflate where keys == property
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.objectId forKey:CMInternalObjectIdKey];
    // Introspect and deflate and make property == key in coder
}

- (NSSet *)propertySerializationOverrides {
    return [NSSet set];
}

- (NSDictionary *)additionalMethodsForSerialization {
    return [NSDictionary dictionary];
}

- (NSString *)objectId {
    return objectId;
}

- (NSString *)className {
    return NSStringFromClass([self class]);
}

- (BOOL)isEqual:(id)object {
    return [self.objectId isEqualToString:[object objectId]];
}

@end
