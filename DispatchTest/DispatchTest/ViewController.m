//
//  ViewController.m
//  DispatchTest
//
//  Created by zhanglei on 15/10/12.
//  Copyright © 2015年 lei.zhang. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSLog(@"-----线性执行线程队列");
    dispatch_queue_t serialQueue = dispatch_queue_create("com.mark.serialQueue", NULL);
    dispatch_async(serialQueue, ^{
        NSLog(@"block on serialQueue");
    });
    
    NSLog(@"-----并发执行线程队列");
    dispatch_queue_t concurrentQueue = dispatch_queue_create("com.mark.concurrentQueue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(concurrentQueue, ^{
        NSLog(@"block on concurrentQueue");
    });
    
    NSLog(@"-----系统Dispatch");
    // 获取Main Dispatch Queue
    dispatch_queue_t mainDispatchQueue = dispatch_get_main_queue();
    // 获取Global Dispatch Queue
    dispatch_queue_t globalDispatchQueueDefault = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
//    dispatch_queue_t globalDispatchQueueHigh = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
//    dispatch_queue_t globalDispatchQueueLow = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
//    dispatch_queue_t globalDispatchQueueBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    // 常用示例
    dispatch_async(globalDispatchQueueDefault, ^{
        // 可执行并发处理
        NSLog(@"block on globalDispatch");
        dispatch_async(mainDispatchQueue, ^{
            // 执行主线程更新操作
            NSLog(@"block on mainDispatchQueue");
        });
    });
    NSLog(@"-----延时执行线程");
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        NSLog(@"Waitted at least 2 seconds");
    });
    
    NSLog(@"-----分组执行线程");
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_async(group, queue, ^{
        NSLog(@"Queue One");
    });
    dispatch_group_async(group, queue, ^{
        NSLog(@"Queue Two");
    });
    dispatch_group_async(group, queue, ^{
        NSLog(@"Queue Three");
    });
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSLog(@"Queues Done");
    });
    // 也可以这样执行,每二参数用于表示超时时间
    //dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
//    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 1ull *NSEC_PER_SEC);
//    long result = dispatch_group_wait(group, time);
//    if (0 == result) {
//        NSLog(@"Queue Done");
//        // 属于Dispatch Group的全部处理执行结束
//    }
//    else {
//        NSLog(@"Queue in deal");
//        // 属于Dispatch Group的某一个处理在超过指定时限后还在执行中
//    }
    
    NSLog(@"-----可重复执行的线程");
    dispatch_apply(10, queue, ^(size_t index){
        NSLog(@"%zu", index);
    });
    // Param1 : Block执行次数
    // Param2 : Block追回的队列
    // Param3 : Block执行的次数索引
    // 高效遍历数据元素(无序遍历)
//    dispatch_apply([array count], queue, ^(size_t index){
//        NSLog(@"array element of index %d: %@", index, [array objectAtIndex:index]);
//    });
    NSLog(@"-----排他形式的线程控制");
    // Create dispatch_semaphore
    // semaphore value初始化为1
    // 保证可访问NSMutableArray类对象的线程同时只有一个
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (int i = 0; i < 100; i++) {
        dispatch_async(queue, ^{
            // Waiting for dispatch semaphore, 直到semaphore值达到大于等于1
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            // 由于Dispatch semaphore的计数值达到大于等于1
            // 所以将Dispatch semaphore的计数值减1
            // dispatch_semaphore_wait函数执行返回
            // 即执行到此时的Dispatch semaphore计数值恒为0
            // 由于可访问NSMutableArray类对象的线程只有一个
            // 因此可安全进行更新
            [array addObject:[NSNumber numberWithInt:i]];
            // 排他控制处理结束
            // 所以通过dispatch_semaphore_signal函数
            // 将Dispatch semaphore的计数值加1
            // 如果有通过dispatch_semaphore_wait函数等待Dispatch semaphore的
            // 计数值增加的线程，由最先等待的线程执行
            dispatch_semaphore_signal(semaphore);
        });
    }
    
    NSLog(@"-----只执行一次的线程控制");
    // dispatch_once函数简化如下
    static int initialized = NO;
    if (NO == initialized) {
        // 初始化
        initialized = YES;
    }
    
    // dispatch_once函数使用如下
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        NSLog(@"single Mode");
        // 初始化，这里多用于单例的模式
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
