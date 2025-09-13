// 完全复用discourse-calendar的初始化模式
import { withPluginApi } from "discourse/lib/plugin-api";
import { ajax } from "discourse/lib/ajax";
import showModal from "discourse/lib/show-modal";

function initializeLottery(api) {
  // 复用calendar的custom field模式
  api.includePostAttributes("lottery");
  
  // 复用calendar的composer decorator模式
  api.decorateComposerEvent("topicCreated", (topic) => {
    if (topic.lottery) {
      console.log("抽奖主题已创建:", topic);
    }
  });

  // 复用calendar的post decorator模式  
  api.decorateWidget("post-contents:after-cooked", (dec) => {
    const post = dec.attrs;
    if (post.lottery) {
      return dec.widget.attach("lottery-display", {
        post: post,
        lottery: post.lottery
      });
    }
  });

  // 复用calendar的composer button模式
  api.addComposerToolbarPopupMenuOption({
    action: "insertLottery",
    icon: "dice",
    label: "lottery.composer.add_lottery",
    condition: "canCreateLottery"
  });

  // 复用calendar的action处理模式
  api.addComposerToolbarPopupMenuOptionCallbacks({
    insertLottery() {
      showModal("create-lottery-modal", {
        model: {
          composer: this
        }
      });
    },
    canCreateLottery() {
      return this.siteSettings.lottery_enabled && 
             this.currentUser && 
             this.currentUser.can_create_topic;
    }
  });
}

export default {
  name: "extend-for-lottery",
  initialize() {
    withPluginApi("0.8.31", initializeLottery);
  }
};
