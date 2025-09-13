# 复用calendar的路由模式
Discourse::Application.routes.draw do
  scope "/admin/plugins" do
    get "/lottery" => "admin/plugins#index", constraints: StaffConstraint.new
    get "/lottery/settings" => "admin/lottery#settings", constraints: StaffConstraint.new
    get "/lottery/active" => "admin/lottery#active", constraints: StaffConstraint.new
    put "/lottery/:id/cancel" => "admin/lottery#cancel", constraints: StaffConstraint.new
  end
end
