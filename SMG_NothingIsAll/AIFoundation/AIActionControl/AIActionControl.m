//
//  AIActionControl.m
//  SMG_NothingIsAll
//
//  Created by 贾  on 2017/12/7.
//  Copyright © 2017年 XiaoGang. All rights reserved.
//

#import "AIActionControl.h"
#import "AINode.h"
#import "AIStringAlgs.h"
#import "PINCache.h"
#import "AIImvAlgs.h"
#import "AICustomAlgs.h"
#import "AIStringAlgsModel.h"
#import "ImvAlgsModelBase.h"
#import "AINet.h"

@implementation AIActionControl

static AIActionControl *_instance;
+(AIActionControl*) shareInstance{
    if (_instance == nil) {
        _instance = [[AIActionControl alloc] init];
    }
    return _instance;
}

-(void) commitInput:(id)input{
    if (ISOK(input, [NSString class])) {
        [AIStringAlgs commitInput:input];
    }
}

-(void) commitInputIMV:(IMVType)type value:(NSInteger)value{
    [AIImvAlgs commitInputIMV:type value:value];
}

-(void) commitCustom:(CustomInputType)type value:(NSInteger)value{
    [AICustomAlgs commitCustom:type value:value];
}


//MARK:===============================================================
//MARK:                     < search >
//MARK:===============================================================
//1. 事务控制器负责协调action任务;
//2. 将类比检索数据
-(AINode*) searchNodeForDataType:(NSString*)dataType dataSource:(NSString *)dataSource{
    return [[AINet sharedInstance] searchNodeForDataType:dataType dataSource:dataSource];
}

-(AINode*) searchNodeForDataType:(NSString*)dataType dataSource:(NSString *)dataSource autoCreate:(AIModel*)createModel{
    AINode *absNode = [self searchNodeForDataType:dataType dataSource:dataSource];
    if (absNode && !ARRISOK(absNode.conPorts)) {
        AINode *newAbsNode = [self insertModel:createModel dataSource:nil];//构建抽象点仅指定dataType
        [self updateNode:absNode abs:newAbsNode];
        return newAbsNode;
    }
    return absNode;
}

-(AINode*) searchNodeForDataModel:(AIModel*)model {
    return [[AINet sharedInstance] searchNodeForDataModel:model];
}

-(AINode*) searchNodeForDataObj:(id)obj {
    return [[AINet sharedInstance] searchNodeForDataObj:obj];
}


//MARK:===============================================================
//MARK:                     < insert >
//MARK:===============================================================
-(AINode*) insertModel:(AIModel*)model dataSource:(NSString*)dataSource{
    return [theNet insertModel:model dataSource:dataSource energy:10];
}


//MARK:===============================================================
//MARK:                     < update >
//MARK:===============================================================
-(void) updateNetModel:(AINode*)model{
    [theNet updateNetModel:model];
}

-(void) updateNode:(AINode*)node abs:(AINode*)abs{
    [[AINet sharedInstance] updateNode:node abs:abs];
}

-(void) updateNode:(AINode *)node propertyNode:(AINode *)propertyNode{
    [[AINet sharedInstance] updateNode:node propertyNode:propertyNode];
}

-(void) updateNode:(AINode *)node changeNode:(AINode *)changeNode{
    [[AINet sharedInstance] updateNode:node changeNode:changeNode];
}

-(void) updateNode:(AINode *)node logicNode:(AINode *)logicNode{
    [[AINet sharedInstance] updateNode:node logicNode:logicNode];
}

@end

//1. 联想点亮区域
//NSArray *lightAreaArr = [SMGUtils lightArea_LightModels:models];
//[SMGUtils lightArea_AILineTypeIsLaw:thinkModel];