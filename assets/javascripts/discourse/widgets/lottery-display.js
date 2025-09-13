// 完全复用discourse-calendar的widget模式
import { createWidget } from "discourse/widgets/widget";
import { h } from "virtual-dom";
import { iconNode } from "discourse-common/lib/icon-library";
import showModal from "discourse/lib/show-modal";

export default createWidget("lottery-display", {
  tagName: "div.lottery-container",

  buildKey: (attrs) => `lottery-display-${attrs.post.id}`,

  defaultState() {
    return {
      loading: false,
      participated: false
    };
  },

  // 复用calendar的渲染结构
  html(attrs, state) {
    const lottery = attrs.lottery;
    if (!lottery) return;

    const contents = [];

    // 抽奖头部（复用calendar的header模式）
    contents.push(
      h("div.lottery-header", [
        iconNode("dice", { class: "lottery-icon" }),
        h("span.lottery-title", lottery.activity_name || "抽奖活动")
      ])
    );

    // 抽奖状态（复用calendar的status模式）
    contents.push(
      h(`div.lottery-status.${lottery.status}`, 
        this.getStatusText(lottery.status)
      )
    );

    // 抽奖信息（复用calendar的info grid模式）
    contents.push(
      h("div.lottery-info", [
        h("div.info-item", [
          h("label", "奖品说明："),
          h("span", lottery.prize_description || "待公布")
        ]),
        h("div.info-item", [
          h("label", "开奖时间："),
          h("span", this.formatTime(lottery.draw_time))
        ]),
        h("div.info-item", [
          h("label", "中奖人数："),
          h("span", `${lottery.winner_count}人`)
        ]),
        h("div.info-item", [
          h("label", "参与门槛："),
          h("span", `至少${lottery.min_participants}人`)
        ])
      ])
    );

    // 参与统计
    const currentCount = lottery.participants?.length || 0;
    contents.push(
      h("div.participation-stats", [
        h("span.current-count", `当前参与：${currentCount}人`),
        h("span.required-count", `需要：${lottery.min_participants}人`)
      ])
    );

    // 参与按钮（复用calendar的button模式）
    if (lottery.status === "running") {
      contents.push(this.participateButton(attrs, state));
    }

    // 中奖结果（如果已开奖）
    if (lottery.status === "finished" && lottery.winners) {
      contents.push(this.winnersDisplay(lottery.winners));
    }

    return contents;
  },

  participateButton(attrs, state) {
    const canParticipate = this.currentUser && 
                          !state.participated && 
                          !this.isPostOwner(attrs.post);
    
    return h("div.participate-section", [
      this.attach("button", {
        className: "participate-button",
        label: state.participated ? "已参与" : "参与抽奖",
        disabled: !canParticipate || state.loading,
        action: "participateLottery"
      })
    ]);
  },

  winnersDisplay(winners) {
    return h("div.winners-section", [
      h("h4", "🎉 中奖名单"),
      h("div.winners-list", 
        winners.map(winner => 
          h("div.winner-item", [
            h("img.avatar", { src: winner.avatar_url }),
            h("span.username", winner.username),
            h("span.floor", `${winner.floor}楼`)
          ])
        )
      )
    ]);
  },

  // 复用calendar的工具方法
  getStatusText(status) {
    const statusMap = {
      running: "🎲 抽奖进行中",
      finished: "🎉 已开奖",
      cancelled: "❌ 已取消"
    };
    return statusMap[status] || "未知状态";
  },

  formatTime(timeString) {
    if (!timeString) return "待定";
    return moment(timeString).format("YYYY-MM-DD HH:mm");
  },

  isPostOwner(post) {
    return this.currentUser && this.currentUser.id === post.user_id;
  },

  // 复用calendar的action模式
  participateLottery() {
    if (!this.currentUser) {
      showModal("login");
      return;
    }

    this.state.loading = true;
    this.scheduleRerender();

    // 预留API调用
    console.log("参与抽奖", this.attrs.post.id);
    
    // 模拟参与成功
    setTimeout(() => {
      this.state.participated = true;
      this.state.loading = false;
      this.scheduleRerender();
    }, 1000);
  }
});
