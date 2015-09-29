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

#import "BrickMoveManagerAbstractTest.h"
#import "WaitBrick.h"
#import "SetVariableBrick.h"
#import "ForeverBrick.h"
#import "LoopEndBrick.h"
#import "RepeatBrick.h"
#import "IfLogicBeginBrick.h"
#import "IfLogicElseBrick.h"
#import "IfLogicEndBrick.h"
#import "WhenScript.h"
#import "BrickMoveManager.h"

@interface BrickMoveManagerForeverTests : BrickMoveManagerAbstractTest

@end

@implementation BrickMoveManagerForeverTests

- (void)testMoveNestedForeverBricks {
    [self.viewController.collectionView reloadData];
    
    ForeverBrick *foreverBrickA = [[ForeverBrick alloc] init];
    foreverBrickA.script = self.startScript;
    [self.startScript.brickList addObject:foreverBrickA];
    
    LoopEndBrick *loopEndBrickA = [[LoopEndBrick alloc] init];
    loopEndBrickA.script = self.startScript;
    loopEndBrickA.loopBeginBrick = foreverBrickA;
    [self.startScript.brickList addObject:loopEndBrickA];
    foreverBrickA.loopEndBrick = loopEndBrickA;
    
    ForeverBrick *foreverBrickB = [[ForeverBrick alloc] init];
    foreverBrickB.script = self.startScript;
    [self.startScript.brickList addObject:foreverBrickB];
    
    LoopEndBrick *loopEndBrickB = [[LoopEndBrick alloc] init];
    loopEndBrickB.script = self.startScript;
    loopEndBrickB.loopBeginBrick = foreverBrickB;
    [self.startScript.brickList addObject:loopEndBrickB];
    foreverBrickB.loopEndBrick = loopEndBrickB;
    
    XCTAssertEqual(1, [self.viewController.collectionView numberOfSections]);
    XCTAssertEqual(5, [self.viewController.collectionView numberOfItemsInSection:0]);
    
    NSIndexPath *indexPathFrom = [NSIndexPath indexPathForRow:1 inSection:0];
    NSIndexPath *indexPathTo = [NSIndexPath indexPathForRow:3 inSection:0];
    
    BOOL canMoveInsideForeverBrickEditMode = [[BrickMoveManager sharedInstance] collectionView:self.viewController.collectionView
                                                                                      itemAtIndexPath:indexPathFrom
                                                                                   canMoveToIndexPath:indexPathTo
                                                                                            andObject:self.spriteObject];
    XCTAssertFalse(canMoveInsideForeverBrickEditMode, @"Should not be allowed to move ForeverBrick inside other ForeverBrick");
}

- (void)testMoveIfBrickInsideForeverBrick {
    [self.viewController.collectionView reloadData];
    
    ForeverBrick *foreverBrick = [[ForeverBrick alloc] init];
    foreverBrick.script = self.startScript;
    [self.startScript.brickList addObject:foreverBrick];

    // start if
    IfLogicBeginBrick *ifLogicBeginBrick = [[IfLogicBeginBrick alloc] init];
    ifLogicBeginBrick.script = self.startScript;
    [self.startScript.brickList addObject:ifLogicBeginBrick];
    
    IfLogicElseBrick *ifLogicElseBrick = [[IfLogicElseBrick alloc] init];
    ifLogicElseBrick.script = self.startScript;
    ifLogicElseBrick.ifBeginBrick = ifLogicBeginBrick;
    [self.startScript.brickList addObject:ifLogicElseBrick];
    ifLogicBeginBrick.ifElseBrick = ifLogicElseBrick;

    IfLogicEndBrick *ifLogicEndBrick = [[IfLogicEndBrick alloc] init];
    ifLogicEndBrick.script = self.startScript;
    ifLogicEndBrick.ifBeginBrick = ifLogicBeginBrick;
    ifLogicEndBrick.ifElseBrick = ifLogicElseBrick;
    [self.startScript.brickList addObject:ifLogicEndBrick];
    
    ifLogicBeginBrick.ifEndBrick = ifLogicEndBrick;
    ifLogicElseBrick.ifEndBrick = ifLogicEndBrick;
    // end if
    
    LoopEndBrick *loopEndBrick = [[LoopEndBrick alloc] init];
    loopEndBrick.script = self.startScript;
    loopEndBrick.loopBeginBrick = foreverBrick;
    [self.startScript.brickList addObject:loopEndBrick];
    foreverBrick.loopEndBrick = loopEndBrick;
    
    XCTAssertEqual(1, [self.viewController.collectionView numberOfSections]);
    XCTAssertEqual(6, [self.viewController.collectionView numberOfItemsInSection:0]);
    
    // if brick above forever brick
    NSIndexPath *indexPathFrom = [NSIndexPath indexPathForRow:2 inSection:0];
    NSIndexPath *indexPathTo = [NSIndexPath indexPathForRow:1 inSection:0];
    
    BOOL canMoveAboveForeverBrickEditMode = [[BrickMoveManager sharedInstance] collectionView:self.viewController.collectionView
                                                                                       itemAtIndexPath:indexPathFrom
                                                                                    canMoveToIndexPath:indexPathTo
                                                                                             andObject:self.spriteObject];
    XCTAssertFalse(canMoveAboveForeverBrickEditMode, @"Should not be allowed to move IfBrick inside forever-loop above ForeverBrick");    
}

- (void)testMoveWaitBrickBelowForeverBrickInsideIfBrick {
    [self.viewController.collectionView reloadData];
    
    // start if
    IfLogicBeginBrick *ifLogicBeginBrick = [[IfLogicBeginBrick alloc] init];
    ifLogicBeginBrick.script = self.startScript;
    [self.startScript.brickList addObject:ifLogicBeginBrick];
    
    ForeverBrick *foreverBrick1 = [[ForeverBrick alloc] init];
    foreverBrick1.script = self.startScript;
    [self.startScript.brickList addObject:foreverBrick1];
    
    LoopEndBrick *loopEndBrick1 = [[LoopEndBrick alloc] init];
    loopEndBrick1.script = self.startScript;
    loopEndBrick1.loopBeginBrick = foreverBrick1;
    [self.startScript.brickList addObject:loopEndBrick1];
    foreverBrick1.loopEndBrick = loopEndBrick1;
    
    IfLogicElseBrick *ifLogicElseBrick = [[IfLogicElseBrick alloc] init];
    ifLogicElseBrick.script = self.startScript;
    ifLogicElseBrick.ifBeginBrick = ifLogicBeginBrick;
    [self.startScript.brickList addObject:ifLogicElseBrick];
    ifLogicBeginBrick.ifElseBrick = ifLogicElseBrick;
    
    ForeverBrick *foreverBrick2 = [[ForeverBrick alloc] init];
    foreverBrick2.script = self.startScript;
    [self.startScript.brickList addObject:foreverBrick2];
    
    WaitBrick *waitBrick = [[WaitBrick alloc] init];
    waitBrick.script = self.startScript;
    [self.startScript.brickList addObject:waitBrick];
    
    LoopEndBrick *loopEndBrick2 = [[LoopEndBrick alloc] init];
    loopEndBrick2.script = self.startScript;
    loopEndBrick2.loopBeginBrick = foreverBrick2;
    [self.startScript.brickList addObject:loopEndBrick2];
    foreverBrick2.loopEndBrick = loopEndBrick2;
    
    IfLogicEndBrick *ifLogicEndBrick = [[IfLogicEndBrick alloc] init];
    ifLogicEndBrick.script = self.startScript;
    ifLogicEndBrick.ifBeginBrick = ifLogicBeginBrick;
    ifLogicEndBrick.ifElseBrick = ifLogicElseBrick;
    [self.startScript.brickList addObject:ifLogicEndBrick];
    
    ifLogicBeginBrick.ifEndBrick = ifLogicEndBrick;
    ifLogicElseBrick.ifEndBrick = ifLogicEndBrick;
    // end if
    
    XCTAssertEqual(1, [self.viewController.collectionView numberOfSections]);
    XCTAssertEqual(9, [self.viewController.collectionView numberOfItemsInSection:0]);
    
    // wait brick below forever end brick of if branch
    NSIndexPath *indexPathFrom = [NSIndexPath indexPathForRow:7 inSection:0];
    NSIndexPath *indexPathTo = [NSIndexPath indexPathForRow:5 inSection:0];
    
    BOOL canMoveBelowForeverEndBrickEditMode = [[BrickMoveManager sharedInstance] collectionView:self.viewController.collectionView
                                                                                 itemAtIndexPath:indexPathFrom
                                                                              canMoveToIndexPath:indexPathTo
                                                                                       andObject:self.spriteObject];
    XCTAssertFalse(canMoveBelowForeverEndBrickEditMode, @"Should not be allowed to move WaitBrick below forever-loop of if-branch");
}

@end