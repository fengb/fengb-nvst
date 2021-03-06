RailsAdmin.config do |config|
  config.main_app_name = ['NVST', 'Admin']
  config.parent_controller = '::RailsAdminController'
  # config.main_app_name = ->(controller) { [Rails.application.engine_name.titleize, controller.params['action'].titleize] }

  # RailsAdmin may need a way to know who the current user is]
  config.current_user_method { current_admin }
  config.authenticate_with   { authenticate_admin! }

  config.audit_with :history, 'Admin'
  # config.audit_with :paper_trail, 'User'

  # Display empty fields in show views:
  # config.compact_show_view = false

  # Number of default rows per-page:
  # config.default_items_per_page = 20

  config.included_models = %w[Admin User Investment Contribution Transfer Trade Event Expense]

  # Label methods for model instances:
  config.label_methods = [:title, :name]

  config.navigation_static_links = {
    'Portfolio'    => '/admin/portfolio',
    'Transactions' => '/admin/portfolio/transactions',
    'Tax Docs'     => '/admin/tax_docs',
    'Summaries'    => '/admin/summaries',
  }

  config.models_pool.each do |model|
    config.model "#{model}" do
      list do
        exclude_fields :created_at, :updated_at
      end
    end
  end
end
