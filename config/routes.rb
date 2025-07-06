HyperCheese::Application.routes.draw do
  devise_controllers = {
    sessions: 'user/sessions',
    passwords: 'user/passwords',
    registrations: 'user/registrations',
  }

  devise_for :users, controllers: devise_controllers

  devise_scope :user do
    get "/users/pending", to: "user/registrations#pending"
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
      get :similar
      post :toggle_star
      post :toggle_bullhorn
      post :rate
    end

    resources :albums do
      member do
        post :add_items
        delete 'remove_item/:item_id', action: :remove_item
        post :share
      end
    end

    get 'users/albums', to: 'albums#user_albums'
    resources :comments

    resources :tags
    get 'users/current', to: 'current_user#current'
  end

  scope :shares do
    get ':share_id' => 'shares#show'
    get ':share_id/download' => 'shares#download'
    get ':share_id/items' => 'shares#items'
    get ':share_id/download_item/:item_id' => 'shares#download_item'
    get ':share_id/(*path)' => 'shares#show'
  end

  scope :album_shares do
    get ':share_id' => 'album_shares#show'
    get ':share_id/download' => 'album_shares#download'
    get ':share_id/items' => 'album_shares#items'
    get ':share_id/download_item/:item_id' => 'album_shares#download_item'
    post ':share_id/upload' => 'album_shares#upload'
    get ':share_id/(*path)' => 'album_shares#show'
  end

  root to: 'home#index'

  get 'faces/mistagged/:tag_id' => 'faces#mistagged'
  get 'faces/untagged/:tag_id' => 'faces#untagged'
  resources :faces do
    collection do
      get 'unclustered'
    end

    member do
      post 'uncanonize'
      post 'canonize'
    end
  end


  get 'items/(*path)' => 'home#index'
  get 'search/(*path)' => 'home#index'
  get 'tags/(*path)' => 'home#index'
  get 'albums/(*path)' => 'home#index'
  get 'upload' => 'home#index'

  scope :files do
    post 'auth', to: 'files#authenticate'
    post 'manifest', to: 'files#manifest'
    post 'hashes', to: 'files#hashes'
    put 'upload', to: 'files#upload'
  end

  get 'data/resized/:size/:item_id.:ext' => 'items#resized', constraints: { item_id: /\d+/ }
end
