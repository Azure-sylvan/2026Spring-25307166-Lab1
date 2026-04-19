/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import { VideoPlayer } from '../view/VideoPlayer';
import {
  MARGIN_FONT_SIZE,
  COMMON_NUM_FONT_WEIGHT,
  ALL_PERCENT,
  STACK_STYLE,
  DANMAKU_HEIGHT
} from '../common/constants/CommonConstants';
import { VideoPlayerModel } from '../model/VideoPlayerModel';
import preferences from '@ohos.data.preferences';
import { Danmaku } from '../components/Danmaku';
import { DanmakuItem } from '../common/bean/DanmakuItem';
import common from '@ohos.app.ability.common';
interface DialogAction {
  value: Resource;
  action: () => void;
}

interface DialogConfig {
  title: string;
  customDialog: boolean;
  confirm: DialogAction;
  cancel: DialogAction;
  builder: () => ColumnAttribute;
}
@Builder
export function VideoPlayerPageBuilder() {
  VideoPlayerPage()
}

/**
 * Second page.
 */
@Component
export struct VideoPlayerPage {
  private startIconResource: Resource = $r('app.media.ic_public_play');
  private backIconResource: Resource = $r('app.media.ic_back');
  @Provide videoPlayerModel: VideoPlayerModel = new VideoPlayerModel();
  private pathStack: NavPathStack = new NavPathStack();
  @StorageLink('source') source: ResourceStr = '';
  @State showInput: boolean = false;
  @State inputText: string = '';
  @State danmakuList: DanmakuItem[] = [];
  @State videoProgress: number = 0; // 视频播放进度
  private storage: preferences.Preferences | null = null;
  private screenWidth: number = 0; // 添加屏幕宽度变量
  async aboutToAppear() {
    // 获取屏幕宽度
    this.screenWidth = vp2px(100) * 10; // 示例值，实际需用display.get()
    console.log("[弹幕调试] 屏幕宽度:", this.screenWidth);

    // 初始化storage
    this.storage = await preferences.getPreferences(this.context, 'danmakuData');
    
    console.log("[弹幕调试] 页面初始化开始");
  }

  // 创建弹幕的辅助方法
  private createDanmaku(content: string, positionY: string = '50%'): DanmakuItem {
    return new DanmakuItem(
      Date.now().toString(),
      content,
      positionY
    );
  }
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;

  onPageHide() {
    this.videoPlayerModel.controller.pause();
  }
  onPageShow() {
    // 不再加载历史弹幕
    console.log("[弹幕调试] 页面显示，跳过历史弹幕加载");
  }
  
  aboutToDisappear() {
    // 不再保存弹幕历史记录
    console.log("[弹幕调试] 页面消失，跳过弹幕保存");
  }

  build() {
    NavDestination() {
      Row() {
        Image(this.backIconResource)
          .width(MARGIN_FONT_SIZE.FOURTH_MARGIN)
          .height(MARGIN_FONT_SIZE.FOURTH_MARGIN)
          .margin({ left: MARGIN_FONT_SIZE.FOURTH_MARGIN })
          .onClick(() => {
            this.pathStack.pop();
          })
        Text($r('app.string.back'))
          .fontColor(Color.White)
          .fontSize(MARGIN_FONT_SIZE.FOURTH_MARGIN)
          .fontWeight(COMMON_NUM_FONT_WEIGHT)
          .margin({ left: MARGIN_FONT_SIZE.FIRST_MARGIN })
      }
      .width(ALL_PERCENT)
      .margin({
        left: MARGIN_FONT_SIZE.FIRST_MARGIN,
        top: MARGIN_FONT_SIZE.FIRST_MARGIN
      })
      .justifyContent(FlexAlign.Start)

      Stack() {
        if (!this.videoPlayerModel.isPlay && !this.videoPlayerModel.isLoading) {
          Image(this.startIconResource)
            .width(MARGIN_FONT_SIZE.FIFTH_MARGIN)
            .height(MARGIN_FONT_SIZE.FIFTH_MARGIN)
            .zIndex(STACK_STYLE.IMAGE_Z_INDEX)
        }
        if (this.videoPlayerModel.isLoading) {
          Progress({
            value: STACK_STYLE.PROGRESS_VALUE,
            total: STACK_STYLE.PROGRESS_TOTAL,
            type: ProgressType.ScaleRing
          })
            .color(Color.Grey)
            .value(this.videoPlayerModel.progressVal)
            .width(STACK_STYLE.PROGRESS_WIDTH)
            .style({
              strokeWidth: STACK_STYLE.PROGRESS_STROKE_WIDTH,
              scaleCount: STACK_STYLE.PROGRESS_SCALE_COUNT,
              scaleWidth: STACK_STYLE.PROGRESS_SCALE_WIDTH
            })
            .zIndex(STACK_STYLE.PROGRESS_Z_INDEX)
        }
        VideoPlayer({
          source: this.source
        })
          .zIndex(0)
        // 添加Danmaku组件到UI树
        Danmaku({ danmakuList: this.danmakuList })
          .width('100%')
          .height(DANMAKU_HEIGHT)
          .zIndex(999)
          .position({ y: '30%' }) // 关键修改：定位到视频中间
          .opacity(1)
          .visibility(Visibility.Visible)

        // 弹幕发送提示文字
        Text('点击此处发送弹幕')
          .fontSize(16)
          .fontColor('#4CAF50') // 绿色
          .position({ x: '50%', y: '85%' })
          .zIndex(1000)
          .margin({ top: 10 })
          .onClick(() => {
            this.showInput = true;
          })

        // 弹幕输入框
        if (this.showInput) {
          Column() {
            TextInput({ text: this.inputText, placeholder: '输入弹幕内容' })
              .width('90%')
              .height(40)
              .backgroundColor(Color.White)
              .margin(10)
              .onChange((value: string) => {
                this.inputText = value;
              })

            Row() {
              Button('取消')
                .onClick(() => {
                  this.showInput = false;
                  this.inputText = '';
                })

              Button('发送')
                .margin({ left: 20 })
                .onClick(() => {
                  this.sendDanmaku();
                })
            }
          }
          .width('100%')
          .height(100)
          .backgroundColor('#F5F5F5')
          .position({ x: 0, y: '80%' }) // 调整到视频正下方
          .zIndex(1001)
        }
      }
    }
    .hideTitleBar(true)
    .hideToolBar(true)
    .height(ALL_PERCENT)
    .backgroundColor(Color.Black)
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    });
  }
  // 发送弹幕方法（关联视频进度）
  async sendDanmaku(): Promise<void> {
    if (this.inputText.trim()) {
      // 创建带进度时间戳的新弹幕
      const newDanmaku = this.createDanmaku(this.inputText.trim(), this.videoProgress.toString());

      // 使用concat创建新数组触发UI更新
      this.danmakuList = this.danmakuList.concat([newDanmaku]);
      this.showInput = false;
      this.inputText = '';

      // 保存弹幕到本地存储
      if (this.storage) {
        await this.storage.put('danmakuData', JSON.stringify(this.danmakuList));
        await this.storage.flush();
      }
    }
  }
}
