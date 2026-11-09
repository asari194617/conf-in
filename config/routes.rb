Rails.application.routes.draw do
  root to: 'home#index'

  devise_for :users, path: 'user'

  resources :users, only: [:show] do
    get :icon, on: :member
    post :send_qr, on: :collection
  end

  resources :events do
    resources :entries, only: [:index, :new, :update, :destroy] do
      collection do
        post :confirm
        post :complete
        get :qr_receive
      end
    end

    resources :event_mails, only: [:index, :show, :new, :create] do
      post :confirm, on: :collection
    end

    member do
      get :admin
      post :resend_entry_mail
    end
  end

  get 'about', to: 'home#about'
  get 'help', to: 'help#index'
end
