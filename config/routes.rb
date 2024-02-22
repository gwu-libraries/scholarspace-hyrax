Rails.application.routes.draw do

  mount Bulkrax::Engine, at: '/'
  mount Riiif::Engine => 'images', as: :riiif if Hyrax.config.iiif_image_server?

  get '/browse', to: redirect('/catalog')

  get '/etd/:id', to: redirect('/concern/gw_etds/%{id}')
  get '/etds/:id', to: redirect('/concern/gw_etds/%{id}')
  get '/files/:id', to: redirect('concern/gw_works/%{id}')
  get '/works/:id', to: redirect('concern/gw_works/%{id}')
  get '/work/:id', to: redirect('concern/gw_works/%{id}')

  mount Blacklight::Engine => '/'
  
  concern :exportable, Blacklight::Routes::Exportable.new
  concern :searchable, Blacklight::Routes::Searchable.new
  concern :oai_provider, BlacklightOaiProvider::Routes.new

  resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :oai_provider
    concerns :searchable
  end
=begin
  if Rails.env.production?
    devise_for :users, :skip => [:registrations], path_names: { sign_in: 'auth/saml'}, controllers: { omniauth_callbacks: 'users/omniauth_callbacks', sessions: 'users/sessions'}, registrations: 'users/registrations' }
    devise_scope :user do
      get 'users/auth/saml', to: 'users/omniauth_authorize#passthru', defaults: { provider: :saml }, as: 'new_gwss_session'
    end
  end

  if Rails.env.development?
    devise_for :users
  end
=end
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
  mount Hydra::RoleManagement::Engine => '/'

  mount Qa::Engine => '/authorities'
  mount Hyrax::Engine, at: '/'
  resources :welcome, only: 'index'
  root 'hyrax/homepage#index'
  curation_concerns_basic_routes

  resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
    concerns :exportable
  end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete 'clear'
    end
  end

  require 'sidekiq/web'
  
  authenticate :user, lambda { |u| u.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end
  
  match '*path', to: 'errors#not_found', via: :all, format: false, defaults: { format: 'html' }

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end

Hyrax::Engine.routes.draw do
  get 'share' =>'pages#show', key: 'share'
end