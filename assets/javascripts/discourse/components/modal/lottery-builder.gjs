// 2025年最新GJS格式的抽奖构建器
import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import DModal from "discourse/components/d-modal";
import DButton from "discourse/components/d-button";
import TextField from "discourse/components/text-field";
import Textarea from "discourse/components/textarea";
import ComboBox from "select-kit/components/combo-box";
import DateTimeInput from "discourse/components/date-time-input";

export default class LotteryBuilder extends Component {
  @service siteSettings;
  @service currentUser;

  @tracked activityName = "";
  @tracked prizeDescription = "";
  @tracked drawTime = "";
  @tracked winnerCount = 1;
  @tracked specifiedFloors = "";
  @tracked minParticipants = this.siteSettings.lottery_min_participants_global;
  @tracked fallbackStrategy = "continue";
  @tracked additionalNotes = "";
  @tracked errors = [];

  get isValid() {
    return this.activityName?.length > 0 && 
           this.prizeDescription?.length > 0 && 
           this.drawTime?.length > 0 && 
           this.winnerCount > 0 && 
           this.minParticipants >= this.siteSettings.lottery_min_participants_global;
  }

  get minParticipantsError() {
    if (this.minParticipants < this.siteSettings.lottery_min_participants_global) {
      return `参与门槛不能低于${this.siteSettings.lottery_min_participants_global}人`;
    }
    return null;
  }

  get drawTimeError() {
    if (this.drawTime) {
      const drawDate = new Date(this.drawTime);
      const now = new Date();
      if (drawDate <= now) {
        return "开奖时间必须是将来时间";
      }
    }
    return null;
  }

  get lotteryType() {
    return this.specifiedFloors?.trim() ? "specified" : "random";
  }

  get finalWinnerCount() {
    if (this.lotteryType === "specified" && this.specifiedFloors?.trim()) {
      const floors = this.specifiedFloors.split(",").map(f => f.trim()).filter(f => f);
      return floors.length;
    }
    return this.winnerCount;
  }

  get fallbackOptions() {
    return [
      { id: "continue", name: "当开奖时人数不足，继续开奖" },
      { id: "cancel", name: "当开奖时人数不足，取消活动" }
    ];
  }

  @action
  updateTime(time) {
    this.drawTime = time;
  }

  @action
  createLottery() {
    this.errors = [];
    
    // 前端验证
    if (this.minParticipantsError) {
      this.errors.push(this.minParticipantsError);
    }
    if (this.drawTimeError) {
      this.errors.push(this.drawTimeError);
    }
    
    if (!this.isValid || this.errors.length > 0) {
      return;
    }

    // 构建抽奖数据
    const lotteryData = {
      activity_name: this.activityName,
      prize_description: this.prizeDescription,
      draw_time: this.drawTime,
      winner_count: this.finalWinnerCount,
      specified_floors: this.specifiedFloors?.trim() || null,
      min_participants: this.minParticipants,
      fallback_strategy: this.fallbackStrategy,
      additional_notes: this.additionalNotes,
      lottery_type: this.lotteryType
    };

    // 插入到composer
    const composer = this.args.model.composer;
    const lotteryMarkup = this.generateLotteryMarkup(lotteryData);
    
    composer.appEvents.trigger("composer:insert-text", lotteryMarkup);
    
    // 保存数据供后端处理
    composer.set("lottery_data", lotteryData);
    
    this.args.closeModal();
  }

  generateLotteryMarkup(data) {
    return `
[lottery]
activity_name="${data.activity_name}"
prize_description="${data.prize_description}"
draw_time="${data.draw_time}"
winner_count="${data.winner_count}"
min_participants="${data.min_participants}"
fallback_strategy="${data.fallback_strategy}"
${data.specified_floors ? `specified_floors="${data.specified_floors}"` : ''}
${data.additional_notes ? `notes="${data.additional_notes}"` : ''}
[/lottery]
    `.trim();
  }

  <template>
    <DModal 
      @title="创建抽奖活动"
      @closeModal={{@closeModal}}
      class="lottery-builder-modal"
    >
      <:body>
        {{#if this.errors}}
          <div class="alert alert-error">
            {{#each this.errors as |error|}}
              <div>{{error}}</div>
            {{/each}}
          </div>
        {{/if}}

        <div class="control-group">
          <label>活动名称 *</label>
          <TextField 
            @value={{this.activityName}} 
            @placeholderKey="例如：新年抽奖活动"
          />
        </div>

        <div class="control-group">
          <label>奖品说明 *</label>
          <Textarea 
            @value={{this.prizeDescription}} 
            @placeholderKey="详细描述奖品内容"
            rows="3"
          />
        </div>

        <div class="control-group">
          <label>开奖时间 *</label>
          <DateTimeInput
            @value={{this.drawTime}}
            @onChange={{this.updateTime}}
          />
          {{#if this.drawTimeError}}
            <div class="validation-error">{{this.drawTimeError}}</div>
          {{/if}}
        </div>

        <div class="control-group">
          <label>获奖人数 *</label>
          <TextField 
            @value={{this.winnerCount}} 
            @type="number"
            min="1"
            max="50"
          />
          <small>随机抽奖时的获奖人数。如果您想按指定楼层开奖，请填写下面的"指定中奖楼层"。</small>
        </div>

        <div class="control-group">
          <label>指定中奖楼层</label>
          <TextField 
            @value={{this.specifiedFloors}} 
            @placeholderKey="8, 18, 28"
          />
          <small>（可选）填写此项将覆盖随机抽奖。请填写具体的楼层号，用英文逗号分隔。</small>
        </div>

        <div class="control-group">
          <label>参与门槛 *</label>
          <TextField 
            @value={{this.minParticipants}} 
            @type="number"
            min={{this.siteSettings.lottery_min_participants_global}}
          />
          {{#if this.minParticipantsError}}
            <div class="validation-error">{{this.minParticipantsError}}</div>
          {{/if}}
        </div>

        <div class="control-group">
          <label>后备策略 *</label>
          <ComboBox
            @value={{this.fallbackStrategy}}
            @content={{this.fallbackOptions}}
            @nameProperty="name"
            @valueProperty="id"
          />
        </div>

        <div class="control-group">
          <label>补充说明</label>
          <Textarea 
            @value={{this.additionalNotes}} 
            @placeholderKey="活动规则、注意事项等"
            rows="2"
          />
        </div>

        {{#if this.lotteryType}}
          <div class="lottery-preview">
            <strong>抽奖方式：</strong>
            {{#if (eq this.lotteryType "specified")}}
              指定楼层抽奖（{{this.finalWinnerCount}}个中奖楼层）
            {{else}}
              随机抽奖（{{this.finalWinnerCount}}个中奖者）
            {{/if}}
          </div>
        {{/if}}
      </:body>
      
      <:footer>
        <DButton
          @action={{this.createLottery}}
          @disabled={{this.isValid}}
          @label="创建抽奖"
          class="btn-primary"
        />
      </:footer>
    </DModal>
  </template>
}
