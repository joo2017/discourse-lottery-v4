// 直接扩展核心DiscoursePostEvent而非重建
import { withPluginApi } from "discourse/lib/plugin-api";

function extendPostEventForLottery(api) {
  // 扩展现有的post-event serializer
  api.modifyClass("model:post", {
    get isLottery() {
      return this.custom_fields?.lottery;
    },
    
    get lotteryData() {
      return this.custom_fields?.lottery;
    }
  });

  // 扩展现有的post-event显示
  api.renderInOutlet("post-event-after", <template>
    {{#if @outletArgs.post.isLottery}}
      <div class="lottery-extension">
        <h4>🎲 抽奖活动</h4>
        <div class="lottery-info">
          <p><strong>活动：</strong>{{@outletArgs.post.lotteryData.activity_name}}</p>
          <p><strong>奖品：</strong>{{@outletArgs.post.lotteryData.prize_description}}</p>
        </div>
      </div>
    {{/if}}
  </template>);

  // 扩展现有的event creation flow
  api.modifyClass("controller:composer", {
    actions: {
      createLotteryEvent() {
        // 复用现有的post-event创建流程
        this.send("showModal", "discourse-post-event-builder", {
          model: { 
            isLottery: true,
            composer: this 
          }
        });
      }
    }
  });
}

export default {
  name: "extend-post-event-for-lottery", 
  initialize() {
    withPluginApi("1.0.0", extendPostEventForLottery);
  }
};
