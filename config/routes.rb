Nvst::Application.routes.draw do
  root to: 'portfolio#show'

  resource :portfolio, controller: :portfolio

  devise_for :users

  devise_for :admin
  namespace :admin do
    resource :portfolio, controller: :portfolio

    resources :investments do
      member do
        get 'prices'
      end
    end

    resources :tax_docs do
      member do
        get 'form_1065'
        get 'schedule_d'
        get 'schedule_k'
      end
    end

    scope path: :user_summaries, controller: :user_summaries do
      get '',               action: 'index', as: :user_summaries
      get ':year/:user_id', action: 'show',  as: :user_summary
    end
  end
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
end
