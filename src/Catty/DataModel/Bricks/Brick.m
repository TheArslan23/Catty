/**
 *  Copyright (C) 2010-2015 The Catrobat Team
 *  (http://developer.catrobat.org/credits)
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Affero General Public License as
 *  published by the Free Software Foundation, either version 3 of the
 *  License, or (at your option) any later version.
 *
 *  An additional term exception under section 7 of the GNU Affero
 *  General Public License, version 3, is available at
 *  (http://developer.catrobat.org/license_additional_term)
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  GNU Affero General Public License for more details.
 *
 *  You should have received a copy of the GNU Affero General Public License
 *  along with this program.  If not, see http://www.gnu.org/licenses/.
 */
#import "Brick.h"
#import "Script.h"
#import "BrickManager.h"
#import "NSString+CatrobatNSStringExtensions.h"
#import "IfLogicElseBrick.h"
#import "IfLogicBeginBrick.h"
#import "IfLogicEndBrick.h"
#import "LoopEndBrick.h"
#import "RepeatBrick.h"
#import "Formula.h"
#import "Util.h"
#import "CBMutableCopyContext.h"

@interface Brick()

@property (nonatomic, readwrite) kBrickCategoryType brickCategoryType;
@property (nonatomic, readwrite) kBrickType brickType;

@end

@implementation Brick

- (id)init
{
    self = [super init];
    if (self) {
        NSString *subclassName = NSStringFromClass([self class]);
        BrickManager *brickManager = [BrickManager sharedBrickManager];
        self.brickType = [brickManager brickTypeForClassName:subclassName];
        self.brickCategoryType = [brickManager brickCategoryTypeForBrickType:self.brickType];
    }
    return self;
}

- (BOOL)isSelectableForObject
{
    return YES;
}

- (NSString*)description
{
    return @"Brick (NO SPECIFIC DESCRIPTION GIVEN! OVERRIDE THE DESCRIPTION METHOD!";
}

-(SKAction*)action
{
    NSError(@"%@ (NO SPECIFIC Action GIVEN! OVERRIDE THE action METHOD!", self.class);
    return nil;
}


- (void)performFromScript:(Script*)script
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

-(dispatch_block_t)actionBlock
{
    return ^{
        NSError(@"%@ (NO SPECIFIC Action GIVEN! OVERRIDE THE actionBlock METHOD!", self.class);
    };
}

- (BOOL)isEqualToBrick:(Brick*)brick
{
    NSArray *firstPropertyList = [[Util propertiesOfInstance:self] allValues];
    NSArray *secondPropertyList = [[Util propertiesOfInstance:brick] allValues];
    
    if([firstPropertyList count] != [secondPropertyList count])
        return NO;
    
    NSUInteger index;
    for(index = 0; index < [firstPropertyList count]; index++) {
        NSObject *firstObject = [firstPropertyList objectAtIndex:index];
        NSObject *secondObject = [secondPropertyList objectAtIndex:index];
        
        if(![Util isEqual:firstObject toObject:secondObject])
            return NO;
    }
    
    return YES;
}

#pragma mark - Copy
// This function must be overriden by Bricks with references to other Bricks (e.g. ForeverBrick)
- (id)mutableCopyWithContext:(CBMutableCopyContext*)context
{
    return [self mutableCopyWithContext:context AndErrorReporting:true];
}


- (id)mutableCopyWithContext:(CBMutableCopyContext*)context AndErrorReporting:(BOOL)reportError
{
    if(!context) NSError(@"%@ must not be nil!", [CBMutableCopyContext class]);
    
    Brick *brick = [[self class] new];
    [context updateReference:self WithReference:brick];
    
    NSDictionary *properties = [Util propertiesOfInstance:self];
    
    for (NSString *propertyKey in properties) {
        id propertyValue = [properties objectForKey:propertyKey];
        
        if([propertyValue conformsToProtocol:@protocol(CBMutableCopying)]) {
            id updatedReference = [context updatedReferenceForReference:propertyValue];
            if(updatedReference) {
                [brick setValue:updatedReference forKey:propertyKey];
            } else {
                id propertyValueClone = [propertyValue mutableCopyWithContext:context];
                [brick setValue:propertyValueClone forKey:propertyKey];
            }
        } else if([propertyValue conformsToProtocol:@protocol(NSMutableCopying)]) {
            // standard datatypes like NSString are already conforming to the NSMutableCopying protocol
            id propertyValueClone = [propertyValue mutableCopyWithZone:nil];
            [brick setValue:propertyValueClone forKey:propertyKey];
        } else if(reportError) {
            NSError(@"Property %@ of class %@ in Brick of class %@ does not conform to CBMutableCopying protocol. Implement mutableCopyWithContext method in %@", propertyKey, [propertyValue class], [self class], [self class]);
        }
    }
    
    return brick;
}

@end