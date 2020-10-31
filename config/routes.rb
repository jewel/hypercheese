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
        get :convert
        post :shares
        post :visibility
      end
      get :details
      post :toggle_star
      post :toggle_bullhorn
      post :rate
    end

    resources :comments

    resources :tags

  end

  scope :shares do
    get ':share_id' => 'shares#show'
    get ':share_id/download' => 'shares#download'
    get ':share_id/items' => 'shares#items'
    get ':share_id/download_item/:item_id' => 'shares#download_item'
    get ':share_id/(*path)' => 'shares#show'
  end

  root to: 'home#index'

  get 'items/(*path)' => 'home#index'
  get 'search/(*path)' => 'home#index'
  get 'tags/(*path)' => 'home#index'

  get 'data/resized/:size/:item_id.:ext' => 'items#resized', constraints: { item_id: /\d+/ }
end
