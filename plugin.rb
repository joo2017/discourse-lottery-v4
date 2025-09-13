# name: discourse-lottery-v4
# about: 基于discourse-calendar技术的抽奖插件
# version: 0.1.0
# authors: Discourse Community
# url: https://github.com/discourse/discourse-lottery-v4

enabled_site_setting :lottery_enabled

after_initialize do
  # 模仿discourse-calendar的模块结构
  module ::DiscourseLottery
    PLUGIN_NAME = "discourse-lottery-v4"
    
    # 抽奖自定义字段（复用calendar的custom field模式）
    LOTTERY_CUSTOM_FIELD = "lottery"
    
    # 全局数据键值（复用calendar的PluginStore模式）
    RUNNING_LOTTERIES_KEY = "running_lotteries"
    
    def self.running_lotteries
      PluginStore.get(PLUGIN_NAME, RUNNING_LOTTERIES_KEY) || []
    end

    def self.running_lotteries=(lottery_ids)
      PluginStore.set(PLUGIN_NAME, RUNNING_LOTTERIES_KEY, lottery_ids)
    end
  end

  # 注册自定义字段（完全复用calendar的模式）
  register_post_custom_field_type(DiscourseLottery::LOTTERY_CUSTOM_FIELD, :json)
  TopicView.default_post_custom_fields << DiscourseLottery::LOTTERY_CUSTOM_FIELD

  # 注册管理员路由（复用calendar的admin route模式）
  add_admin_route "admin.lottery", "lottery"

  # 注册SVG图标（复用calendar的图标注册模式）
  register_svg_icon "dice"
  register_svg_icon "gift"
  register_svg_icon "users"
  register_svg_icon "clock"

  # 注册样式表（复用calendar的asset注册模式）
  register_asset "stylesheets/common/lottery.scss"

  # 事件监听（复用calendar的事件监听模式）
  on(:post_created) do |post, opts, user|
    # 预留：检查是否为抽奖帖子
    if post.custom_fields[DiscourseLottery::LOTTERY_CUSTOM_FIELD]
      Rails.logger.info "检测到抽奖帖子创建: #{post.id}"
    end
  end

  on(:post_edited) do |post, topic_changed, user|
    # 预留：处理抽奖编辑
    if post.custom_fields[DiscourseLottery::LOTTERY_CUSTOM_FIELD]
      Rails.logger.info "检测到抽奖帖子编辑: #{post.id}"
    end
  end
end
