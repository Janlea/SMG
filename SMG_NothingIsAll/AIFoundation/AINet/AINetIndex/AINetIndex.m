//
//  AINetIndex.m
//  SMG_NothingIsAll
//
//  Created by iMac on 2018/4/20.
//  Copyright © 2018年 XiaoGang. All rights reserved.
//

#import "AINetIndex.h"
#import "AIKVPointer.h"
#import "AIModel.h"
#import "SMGUtils.h"
#import "AINetIndexReference.h"
#import "PINCache.h"

@interface AINetIndex ()

@property (strong,nonatomic) NSMutableArray *models;
@property (strong, nonatomic) AINetIndexReference *reference;

@end

@implementation AINetIndex

-(id) init{
    self = [super init];
    if (self) {
        [self initData];
    }
    return self;
}

-(void) initData{
    NSArray *localModels = [[PINCache sharedCache] objectForKey:FILENAME_Index];
    self.models = [[NSMutableArray alloc] initWithArray:localModels];
}

//MARK:===============================================================
//MARK:                     < method >
//MARK:===============================================================
-(AIPointer*) getDataPointerWithData:(NSNumber*)data algsType:(NSString*)algsType dataSource:(NSString*)dataSource {
    if (!ISOK(data, NSNumber.class)) {
        return nil;
    }
    
    //1. 查找model,没则new
    AINetIndexModel *model = nil;
    for (AINetIndexModel *itemModel in self.models) {
        if ([STRTOOK(algsType) isEqualToString:itemModel.algsType] && [STRTOOK(dataSource) isEqualToString:itemModel.dataSource]) {
            model = itemModel;
            break;
        }
    }
    if (model == nil) {
        model = [[AINetIndexModel alloc] init];
        model.algsType = algsType;
        model.dataSource = dataSource;
        [self.models addObject:model];
    }
    
    //2. 使用二分法查找data
    __block AIPointer *resultPointer;
    [self search:data from:model startIndex:0 endIndex:model.pointerIds.count - 1 success:^(AIPointer *pointer) {
        //3. 找到;
        resultPointer = pointer;
    } failure:^(NSInteger index) {
        //4. 未找到;创建一个;
        NSInteger pointerId = [SMGUtils createPointerId:algsType dataSource:dataSource];
        AIKVPointer *kvPointer = [AIKVPointer newWithPointerId:pointerId folderName:PATH_NET_VALUE algsType:algsType dataSource:dataSource];
        PINDiskCache *pinCache = [[PINDiskCache alloc] initWithName:@"" rootPath:kvPointer.filePath];
        [pinCache setObject:data forKey:FILENAME_Value];
        //[[NSUserDefaults standardUserDefaults] setObject:data forKey:kvPointer.filePath];
        resultPointer = kvPointer;
        
        if (model.pointerIds.count <= index) {
            [model.pointerIds addObject:@(pointerId)];
        }else{
            [model.pointerIds insertObject:@(pointerId) atIndex:index];
        }
        
        //5. 存
        [[PINCache sharedCache] setObject:self.models forKey:FILENAME_Index];
    }];
    
    return resultPointer;
}

/**
 *  MARK:--------------------二分查找--------------------
 *  success:找到则返回相应AIPointer
 *  failure:失败则返回data可排到的下标
 *  要求:ids指向的值是正序的;(即数组下标越大,值越大)
 */
-(void) search:(NSNumber*)data from:(AINetIndexModel*)model startIndex:(NSInteger)startIndex endIndex:(NSInteger)endIndex success:(void(^)(AIPointer *pointer))success failure:(void(^)(NSInteger index))failure{
    if (ISOK(model, AINetIndexModel.class) && ARRISOK(model.pointerIds)) {
        //1. index越界检查
        NSArray *ids = model.pointerIds;
        startIndex = MAX(0, startIndex);
        endIndex = MIN(ids.count - 1, endIndex);
        
        //2. io方法
        typedef void(^ GetDataAndCompareCompletion)(NSComparisonResult compareResult,AIPointer *pointer);
        void (^ getDataAndCompare)(NSInteger,GetDataAndCompareCompletion) = ^(NSInteger index,GetDataAndCompareCompletion completion)
        {
            NSNumber *pointerIdNumber = ARR_INDEX(ids, index);
            long pointerId = [NUMTOOK(pointerIdNumber) longValue];
            AIKVPointer *pointer = [AIKVPointer newWithPointerId:pointerId folderName:PATH_NET_VALUE algsType:model.algsType dataSource:model.dataSource];
            PINDiskCache *pinCache = [[PINDiskCache alloc] initWithName:@"" rootPath:pointer.filePath];
            NSNumber *value = [pinCache objectForKey:FILENAME_Value];
            //NSNumber *value = [[NSUserDefaults standardUserDefaults] objectForKey:pointer.filePath];
            NSComparisonResult compareResult = [value compare:data];
            completion(compareResult,pointer);
        };
        
        if (labs(startIndex - endIndex) <= 1) {
            //3. 与start对比
            getDataAndCompare(startIndex,^(NSComparisonResult compareResult,AIPointer *pointer){
                if (compareResult == NSOrderedDescending) {      //比小的小
                    if (failure) failure(startIndex);
                }else if (compareResult == NSOrderedSame){       //相等
                    if (success) success(pointer);
                }else {                                         //比小的大
                    if(startIndex == endIndex) {
                        if (failure) failure(startIndex + 1);
                    }else{
                        //4. 与end对比
                        getDataAndCompare(endIndex,^(NSComparisonResult compareResult,AIPointer *pointer){
                            if (compareResult == NSOrderedAscending) { //比大的大
                                if (failure) failure(endIndex + 1);
                            }else if (compareResult == NSOrderedSame){ //相等
                                if (success) success(pointer);
                            }else {                                 //比大的小
                                if (failure) failure(endIndex);
                            }
                        });
                    }
                }
            });
        }else{
            //5. 与mid对比
            NSInteger midIndex = (startIndex + endIndex) / 2;
            
            getDataAndCompare(midIndex,^(NSComparisonResult compareResult,AIPointer *pointer){
                if (compareResult == NSOrderedAscending) { //比中心大(检查mid到endIndex)
                    [self search:data from:model startIndex:midIndex endIndex:endIndex success:success failure:failure];
                }else if (compareResult == NSOrderedSame){ //相等
                    if (success) success(pointer);
                }else {                                     //比中心小(检查startIndex到mid)
                    [self search:data from:model startIndex:startIndex endIndex:midIndex success:success failure:failure];
                }
            });
        }
    }else{
        if (failure) failure(0);
    }
}

//MARK:===============================================================
//MARK:                     < itemIndex指向相关 >
//MARK:===============================================================
-(AINetIndexReference *)reference{
    if (_reference == nil) {
        _reference = [[AINetIndexReference alloc] init];
    }
    return _reference;
}

-(void) setIndexReference:(AIKVPointer*)indexPointer port:(AIPort*)port difValue:(int)difValue{
    [self.reference setReference:indexPointer port:port difValue:difValue];
}

-(NSArray*) getIndexReference:(AIKVPointer*)indexPointer limit:(NSInteger)limit{
    return [self.reference getReference:indexPointer limit:limit];
}

@end


//MARK:===============================================================
//MARK:                     < 内存DataSortModel (一组index) >
//MARK:===============================================================
@implementation AINetIndexModel : NSObject

//MARK:===============================================================
//MARK:                     < method >
//MARK:===============================================================
-(NSMutableArray *)pointerIds{
    if (_pointerIds == nil) {
        _pointerIds = [NSMutableArray new];
    }
    return _pointerIds;
}

/**
 *  MARK:--------------------NSCoding--------------------
 */
- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.pointerIds = [aDecoder decodeObjectForKey:@"pointerIds"];
        self.algsType = [aDecoder decodeObjectForKey:@"algsType"];
        self.dataSource = [aDecoder decodeObjectForKey:@"dataSource"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.pointerIds forKey:@"pointerIds"];
    [aCoder encodeObject:self.algsType forKey:@"algsType"];
    [aCoder encodeObject:self.dataSource forKey:@"dataSource"];
}

@end

