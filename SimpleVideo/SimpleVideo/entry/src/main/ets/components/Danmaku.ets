
// path:entry/src/main/ets/components/Danmaku.ets
import { DanmakuItem } from '../common/bean/DanmakuItem';
import { STACK_STYLE } from '../common/constants/CommonConstants';

const DANMAKU_SPEED_FACTOR = 0.8; // 弹幕速度因子
const MIN_DANMAKU_WIDTH = 100; // 最小弹幕宽度（vp）
const DANMAKU_HEIGHT = 200; // 弹幕区域高度（vp）
const DANMAKU_DURATION = 10000; // 弹幕动画默认时长（毫秒）
@Component
export struct Danmaku {
  @Link danmakuList: DanmakuItem[];
  private timers: Map<string, number> = new Map();
  private areaWidth: number = 0; // 添加缺失的areaWidth属性
  @Prop currentProgress: number = 0; // 当前视频进度（秒）

  aboutToDisappear() {
    // 清除所有定时器
    this.timers.forEach(timer => clearTimeout(timer));
    this.timers.clear();
  }

  aboutToUpdate() {
    // 当视频进度变化时更新弹幕可见性
    this.updateDanmakuVisibility();
  }

  build() {
    Stack() {
      ForEach(this.danmakuList, (item: DanmakuItem) => {
        if (item.visible) {
          Text(item.content)
            .fontSize(16)
            .fontColor(Color.White)
            .backgroundColor(Color.Transparent)
            .textShadow({ radius: 2, color: Color.Black, offsetX: 1, offsetY: 1 })
            .position({ x: '50%', y: item.positionY }) // 根据位置偏移量显示
            .textAlign(TextAlign.Center)
            .zIndex(STACK_STYLE.IMAGE_Z_INDEX) // 与播放按钮同层级
            .opacity(item.visible ? 1 : 0) // 控制可见性
        }
      })
    }
    .width('100%')
    .height(DANMAKU_HEIGHT)
  }

  // 添加带进度信息的弹幕
  public addDanmaku(content: string, progress: number) {
    // 计算弹幕宽度（避免过短的弹幕移动太快）
    const contentWidth = Math.max(content.length * 12, MIN_DANMAKU_WIDTH);
    const newItem = new DanmakuItem(
      Date.now().toString(),
      content,
      `${Math.random() * 100}%`, // positionY参数
      progress, // 弹幕出现时的视频进度
      this.areaWidth, // startX参数
      -contentWidth,  // targetX参数
      Math.random() * (DANMAKU_HEIGHT - 20), // top参数
      DANMAKU_DURATION * (1 + Math.random() * DANMAKU_SPEED_FACTOR) // duration参数
    );
    
    // 立即添加到列表确保组件初始化
    this.danmakuList = [...this.danmakuList, newItem];

    // 延迟设置目标位置
    const timer = setTimeout(() => {
      const index = this.danmakuList.findIndex(i => i.id === newItem.id);
      if (index !== -1) {
        // 创建新数组避免直接修改@Link属性
        const updatedList = [...this.danmakuList];
        updatedList[index].position = `-${contentWidth}vp`;
        this.danmakuList = updatedList;  // 触发UI更新
      }
    }, 10);
    this.timers.set(newItem.id, timer);
  }

  // 根据视频进度更新弹幕可见性
  private updateDanmakuVisibility(): void {
    const currentTime = Date.now();

    this.danmakuList.forEach(item => {
      // 如果弹幕进度在±1秒范围内且未设置显示时间
      if (Math.abs(this.currentProgress - item.progress) < 1 && !item.displayTime) {
        item.visible = true;
        item.displayTime = currentTime; // 记录显示开始时间
      }

      // 如果弹幕已显示超过2秒，则隐藏
      if (item.displayTime && currentTime - item.displayTime > 2000) {
        item.visible = false;
      }
    });

    // 刷新UI
    this.danmakuList = [...this.danmakuList];
  }

  // 重置所有弹幕状态（用于重新播放）
  public resetDanmakuState(): void {
    this.danmakuList.forEach(item => {
      item.visible = true; // 重置为可见
      item.displayTime = 0; // 重置显示时间
    });
    this.danmakuList = [...this.danmakuList];
  }

  private removeDanmaku(id: string) {
    this.danmakuList = this.danmakuList.filter(item => item.id !== id);
    // 清除定时器
    const timer = this.timers.get(id);
    if (timer) {
      clearTimeout(timer);
      this.timers.delete(id);
    }
  }
}