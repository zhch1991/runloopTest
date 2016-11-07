# runloopTest
一个自定义的runloop小程序
//说明
//实现了一个自定义的子线程runloop
//在子线程中，借助苹果提供的timer方法，构建timer源，加入到runloop中
//runloop设置了1000s寿命
//阻塞等待timer信号就绪，执行timer中挂的处理函数
//观察者观察所有runloop的生命周期事件（kCFRunLoopAllActivities）
//子线程入口函数中，需要手动创建自动释放池，因为自定义runloop需要用C，已脱离ARC内存管理
//自定义源，找不到如何构建响应链的方法，如果真正实现100%自定义源，需要对底层有深刻了解，从内核接口开始，自己构建响应链，而苹果底层其实已经帮助我们设计好了响应链，所以我们在使用OC的控件时，不需要关心（从点击了一个button，硬件是怎么将这个信号通过触摸屏传给CPU，又通过哪个CPU接口将这个信号发出，怎么由主线程runloop捕捉到这个信号，又怎么关联上最终我们定义的target和action，何时触发），只要写一个关联一个target-action就好。
