HyperCheese::Application.routes.draw do
  devise_controllers = {
    sessions: 'user/sessions',
    passwords: 'user/passwords',
    registrations: 'user/registrations',
  }

  if Rails.application.config.use_omniauth
    devise_controllers[:omniauth_callbacks] = 'user/omniauth_callbacks'
  end

  devise_for :users, controllers: devise_controllers

  devise_scope :user do
    get "/users/pending", to: "user/registrations#pending"
    get "/users/choose", to: "user/sessions#choose"
  end

  scope path: '/api' do
    get 'activity', to: 'home#activity'

    resources :items do
      collection do
        post :add_tags
        post :remove_tag
        get :download
        post :shares
      end
      get :details
      post :toggle_star
      post :toggle_bullhorn
      post :rate
    end

    resources :comments

    resources :tags

  end

  resources :shares do
    get :download
    get :items
  end

  root to: 'home#index'

  get 'items/(*path)' => 'home#index'
  get 'search/(*path)' => 'home#index'
  get 'tags/(*path)' => 'home#index'
end
