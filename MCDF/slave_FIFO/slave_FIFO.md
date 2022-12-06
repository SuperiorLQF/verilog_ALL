## slave_FIFO 从接收器
#### 参考波形
![](![](2022-12-03-13-43-28.png).png)
#### 测试波形
![](slave_FIFO测试波形.png)


***
**测试现象**：其中可以发现当chx_valid_i为0时的输入没有被FIFO读入，符合接收原则。

**存在问题**：chx_ready没用仔细验证，sivx_req_o的规范有待商榷

**重测试**：打开vcd文件，然后点击`read file`即可
