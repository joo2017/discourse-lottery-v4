// 基于2025年最新技术的抽奖扩展
import { withPluginApi } from "discourse/lib/plugin-api";

function initializeLottery(api) {
  // 直接扩展现有的post attributes（复用calendar模式）
  api.includePostAttributes("lottery");
  api.includePostAttributes("lottery_participants");
  api.includePostAttributes("lottery_winners"); 
  api.includePostAttributes("lottery_status");

  // 使用最新的renderInOutlet API注册抽奖显示组件
  api.renderInOutlet("post-contents-after-cooked", <template>
    {{#if @outletArgs.post.lottery}}
      <LotteryDisplay @post={{@outletArgs.post}} />
    {{/if}}
  </template>);

  // 使用最新的composer toolbar API
  api.addComposerToolbarPopupMenuOption({
    action: "showLotteryBuilder",
    icon: "dice", 
    label: "lottery.composer.add_lottery",
    condition: () => {
      return api.getCurrentUser() && 
             api.getSiteSettings().lottery_enabled;
    }
  });

  // 注册action处理器
  api.addComposerToolbarPopupMenuOptionCallbacks({
    showLotteryBuilder(toolbar) {
      // 使用最新的modal service
      toolbar.send("showModal", "lottery-builder", {
        model: { composer: toolbar }
      });
    }
  });
}

export default {
  name: "extend-for-lottery",
  initialize() {
    withPluginApi("1.0.0", initializeLottery);
  }
};
