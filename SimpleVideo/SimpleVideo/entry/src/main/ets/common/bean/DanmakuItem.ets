
// path:entry/src/main/ets/common/bean/DanmakuItem.ets

export class DanmakuItem {
  id: string;
  content: string;
  startX: number;   // 数值类型起始位置
  targetX: number;  // 数值类型目标位置
  top: number;
  duration: number;
  position: string = ''; // 添加缺失的position属性
  currentX: number; // 当前X位置
  isFixed: boolean = false; // 是否为固定弹幕（中间显示）
  isAnimating: boolean = false; // 动画状态标识
  animationStartTime: number = 0; // 动画开始时间
  timerId: number = 0; // 定时器ID

  positionY: string = '50%'; // 垂直位置偏移
  visible: boolean = true;   // 是否可见
  progress: number = 0;      // 弹幕出现时的视频进度（单位：秒）
  displayTime: number = 0;   // 弹幕开始显示的时间戳（用于计算2秒消失）

  constructor(id: string, content: string, positionY: string = '50%', progress: number = 0, startX?: number, targetX?: number, top?: number, duration?: number) {
    this.id = id;
    this.content = content;
    this.positionY = positionY;
    this.progress = progress; // 记录弹幕出现时的视频进度
    this.startX = startX || 0;
    this.targetX = targetX || 0;
    this.top = top || 0;
    this.duration = duration || 0;
    this.currentX = startX || 0;
  }
}