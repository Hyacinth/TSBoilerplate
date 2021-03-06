//  _Group.h
// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Group.h instead.

#import <Foundation/Foundation.h>
#import "ModelObject.h"


@class Member;

@protocol _Group

@end

extern NSString * const kModelPropertyGroupGroupName;

extern NSString * const kModelPropertyGroupMembers;

extern NSString * const kModelDictionaryGroupGroupName;

extern NSString * const kModelDictionaryGroupMembers;

@interface _Group : ModelObject <NSCoding>


@property (nonatomic, strong) NSString* groupName;@property (nonatomic, strong, readonly) NSSet *members;

- (void)addMembersObject:(Member*)value_ settingInverse: (BOOL) setInverse;
- (void)addMembersObject:(Member*)value_;
- (void)removeAllMembers;
- (void)removeMembersObject:(Member*)value_ settingInverse: (BOOL) setInverse;
- (void)removeMembersObject:(Member*)value_;

@end
