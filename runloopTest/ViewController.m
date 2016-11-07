//
//  ViewController.m
//  runloopTest
//
//  Created by nnandzc on 16/11/6.
//  Copyright © 2016年 nnandzc. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, assign) BOOL end;

@end

@implementation ViewController
//说明
//实现了一个自定义的子线程runloop
//在子线程中，借助苹果提供的timer方法，构建timer源，加入到runloop中
//runloop设置了1000s寿命
//阻塞等待timer信号就绪，执行timer中挂的处理函数
//观察者观察所有runloop的生命周期事件（kCFRunLoopAllActivities）
//子线程入口函数中，需要手动创建自动释放池，因为自定义runloop需要用C，已脱离ARC内存管理
//自定义源，找不到如何构建响应链的方法，如果真正实现100%自定义源，需要对底层有深刻了解，从内核接口开始，自己构建响应链，而苹果底层其实已经帮助我们设计好了响应链，所以我们在使用OC的控件时，不需要关心（从点击了一个button，硬件是怎么将这个信号通过触摸屏传给CPU，又通过哪个CPU接口将这个信号发出，怎么由主线程runloop捕捉到这个信号，又怎么关联上最终我们定义的target和action，何时触发），只要写一个关联一个target-action就好。
#pragma mark - lifeCycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    //开启一个子线程，子线程中有一个runloop，事件源是
    [NSThread detachNewThreadSelector:@selector(observerRunLoop) toTarget:self withObject:nil];
    NSLog(@"ok.");
    NSLog(@"main thread = %@", [NSThread currentThread]);
}

#pragma mark - sub thread entry method
- (void)observerRunLoop {

    //建立自动释放池
    @autoreleasepool {
    
    //获得当前thread的Run loop
    NSRunLoop *myRunLoop = [NSRunLoop currentRunLoop];
    
    //设置Run loop observer的运行环境
    CFRunLoopObserverContext context = {0, NULL, NULL, NULL, NULL};
    
    //创建Run loop observer对象
    //第一个参数用于分配observer对象的内存
    //第二个参数用以设置observer所要关注的事件，详见回调函数myRunLoopObserver中注释
    //第三个参数用于标识该observer是在第一次进入run loop时执行还是每次进入run loop处理时均执行
    //第四个参数用于设置该observer的优先级
    //第五个参数用于设置该observer的回调函数
    //第六个参数用于设置该observer的运行环境
    CFRunLoopObserverRef observer = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 0, &myRunLoopObserver, &context);
    
    
    if (observer) {
        //将Cocoa的NSRunLoop类型转换成Core Foundation的CFRunLoopRef类型
        CFRunLoopRef cfRunLoop = [myRunLoop getCFRunLoop];
        //将新建的observer加入到当前thread的run loop
        CFRunLoopAddObserver(cfRunLoop, observer, kCFRunLoopDefaultMode);
    }
    
    //用子线程timer触发timer类型item
        [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(doFireTimer:) userInfo:nil repeats:YES];
        
    //自定义源
        CFRunLoopSourceRef source;
        CFRunLoopSourceContext source_context;
        bzero(&source_context, sizeof(source_context));
        source_context.perform = _perform;
        source = CFRunLoopSourceCreate(NULL, 0, &source_context);
        CFRunLoopAddSource([myRunLoop getCFRunLoop], source, kCFRunLoopCommonModes);
    
    NSInteger loopCount = 10;
    
    do {
        //启动当前thread的loop直到所指定的时间到达，在loop运行时，run loop会处理所有来自与该run loop联系的input source的数据
        //对于本例与当前run loop联系的input source只有一个Timer类型的source。
        //该Timer每隔0.1秒发送触发事件给run loop，run loop检测到该事件时会调用相应的处理方法。
        
        //由于在run loop添加了observer且设置observer对所有的run loop行为都感兴趣。
        //当调用runUnitDate方法时，observer检测到run loop启动并进入循环，observer会调用其回调函数，第二个参数所传递的行为是kCFRunLoopEntry。
        //observer检测到run loop的其它行为并调用回调函数的操作与上面的描述相类似。
        [myRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1000]];
        //当run loop的运行时间到达时，会退出当前的run loop。observer同样会检测到run loop的退出行为并调用其回调函数，第二个参数所传递的行为是kCFRunLoopExit。
        
        loopCount--;
    } while (loopCount);
    
    //释放自动释放池
    }
}

void myRunLoopObserver(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    NSDate *currentDate = [NSDate date];//获取当前时间，日期
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYY/MM/dd hh:mm:ss SS"];
    NSString *dateString = [dateFormatter stringFromDate:currentDate];
    switch (activity) {
            //The entrance of the run loop, before entering the event processing loop.
            //This activity occurs once for each call to CFRunLoopRun and CFRunLoopRunInMode
        case kCFRunLoopEntry:
            NSLog(@"run loop entry");
            break;
            //Inside the event processing loop before any timers are processed
        case kCFRunLoopBeforeTimers:
            NSLog(@"run loop before timers");
            break;
            //Inside the event processing loop before any sources are processed
        case kCFRunLoopBeforeSources:
            NSLog(@"run loop before sources");
            break;
            //Inside the event processing loop before the run loop sleeps, waiting for a source or timer to fire.
            //This activity does not occur if CFRunLoopRunInMode is called with a timeout of 0 seconds.
            //It also does not occur in a particular iteration of the event processing loop if a version 0 source fires
        case kCFRunLoopBeforeWaiting:
            NSLog(@"run loop before waiting");
            break;
            //Inside the event processing loop after the run loop wakes up, but before processing the event that woke it up.
            //This activity occurs only if the run loop did in fact go to sleep during the current loop
        case kCFRunLoopAfterWaiting:
            NSLog(@"run loop after waiting");
            break;
            //The exit of the run loop, after exiting the event processing loop.
            //This activity occurs once for each call to CFRunLoopRun and CFRunLoopRunInMode
        case kCFRunLoopExit:
            NSLog(@"run loop exit");
            break;
            /*
             A combination of all the preceding stages
             case kCFRunLoopAllActivities:
             break;
             */
        default:  
            break;  
    }  
}

- (void)doFireTimer:(NSTimer *)timer
{
    NSLog(@"timer is fire");
}

static void _perform(void *info __unused)
{
    printf("hello\n");
}

@end
