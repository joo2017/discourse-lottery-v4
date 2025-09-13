// 修正版本 - 移除未导入的helper，使用JavaScript比较
import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import DButton from "discourse/components/d-button";
import icon from "discourse-common/helpers/d-icon";

export default class LotteryDisplay extends Component {
  @service currentUser;
  @service modal;
  @service appEvents;
  
  @tracked loading = false;
  @tracked participated = false;
  @tracked error = null;

  constructor() {
    super(...arguments);
    this.checkParticipation();
  }

  get lottery() {
    return this.args.post.lottery;
  }

  get participants() {
    return this.args.post.lottery_participants || [];
  }

  get winners() {
    return this.args.post.lottery_winners || [];
  }

  get status() {
    return this.args.post.lottery_status || "pending";
  }

  get statusText() {
    const statusMap = {
      pending: "🎲 准备中",
      running: "🎲 进行中",
      finished: "🎉 已开奖", 
      cancelled: "❌ 已取消"
    };
    return statusMap[this.status] || "未知状态";
  }

  get canParticipate() {
    return this.currentUser && 
           !this.participated && 
           this.currentUser.id !== this.args.post.user_id &&
           (this.status === "pending" || this.status === "running");
  }

  get isFinished() {
    return this.status === "finished";
  }

  get hasWinners() {
    return this.winners && this.winners.length > 0;
  }

  get formattedDrawTime() {
    if (!this.lottery.draw_time) return "待定";
    return moment(this.lottery.draw_time).format("MM-DD HH:mm");
  }

  checkParticipation() {
    if (this.currentUser) {
      this.participated = this.participants.some(p => 
        p.user_id === this.currentUser.id
      );
    }
  }

  @action
  async participate() {
    if (!this.currentUser) {
      this.modal.show("login");
      return;
    }

    this.loading = true;
    this.error = null;

    try {
      await ajax(`/discourse-post-event/events/${this.args.post.id}/lottery/participate`, {
        type: "PUT"
      });
      
      this.participated = true;
      this.appEvents.trigger("lottery:participation-updated", {
        postId: this.args.post.id,
        userId: this.currentUser.id
      });
      
    } catch (error) {
      this.error = error.jqXHR?.responseJSON?.errors?.[0] || "参与失败";
    } finally {
      this.loading = false;
    }
  }

  <template>
    <div class="lottery-container">
      {{! 抽奖头部 }}
      <div class="lottery-header">
        {{icon "dice" class="lottery-icon"}}
        <span class="lottery-title">
          {{@post.lottery.activity_name}}
        </span>
      </div>

      {{! 状态显示 }}
      <div class="lottery-status status-{{this.status}}">
        {{this.statusText}}
      </div>

      {{! 抽奖信息 }}
      <div class="lottery-info">
        <div class="info-row">
          <label>奖品：</label>
          <span>{{@post.lottery.prize_description}}</span>
        </div>
        <div class="info-row">
          <label>开奖时间：</label>
          <span>{{this.formattedDrawTime}}</span>
        </div>
        <div class="info-row">
          <label>参与情况：</label>
          <span>{{this.participants.length}}/{{@post.lottery.min_participants}}人</span>
        </div>
      </div>

      {{! 参与按钮 }}
      {{#if this.canParticipate}}
        <div class="participate-section">
          <DButton
            @action={{this.participate}}
            @disabled={{this.loading}}
            @label={{if this.participated "已参与" "参与抽奖"}}
            class="btn-primary participate-btn"
          />
          {{#if this.error}}
            <div class="alert alert-error">{{this.error}}</div>
          {{/if}}
        </div>
      {{/if}}

      {{! 中奖结果 - 使用getter而非helper }}
      {{#if this.isFinished}}
        {{#if this.hasWinners}}
          <div class="winners-section">
            <h4>🎉 中奖名单</h4>
            <div class="winners-list">
              {{#each this.winners as |winner|}}
                <div class="winner-item">
                  <img 
                    src={{winner.avatar_template}} 
                    alt={{winner.username}}
                    class="avatar"
                  />
                  <a href="/u/{{winner.username}}" class="username">
                    {{winner.username}}
                  </a>
                  <span class="floor">{{winner.post_number}}楼</span>
                </div>
              {{/each}}
            </div>
          </div>
        {{/if}}
      {{/if}}
    </div>
  </template>
}
