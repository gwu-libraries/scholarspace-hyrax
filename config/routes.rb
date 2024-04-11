Rails.application.routes.draw do

concern :range_searchable, BlacklightRangeLimit::Routes::RangeSearchable.new
  mount Bulkrax::Engine, at: '/'
  mount Riiif::Engine => 'images', as: :riiif if Hyrax.config.iiif_image_server?

  get '/browse', to: redirect('/catalog')

  get '/etd/:id', to: redirect('/concern/gw_etds/%{id}')
  get '/etds/:id', to: redirect('/concern/gw_etds/%{id}')
  get '/files/:id', to: redirect('concern/gw_works/%{id}')
  get '/works/:id', to: redirect('concern/gw_works/%{id}')
  get '/work/:id', to: redirect('concern/gw_works/%{id}')

  mount Blacklight::Engine => '/'
  mount BlacklightAdvancedSearch::Engine => '/'

  get 'advanced' => 'advanced#index'
  get 'advanced/range_limit' => 'advanced#range_limit'
  
  concern :exportable, Blacklight::Routes::Exportable.new
  concern :searchable, Blacklight::Routes::Searchable.new
  concern :oai_provider, BlacklightOaiProvider::Routes.new

  resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :oai_provider
    concerns :searchable
    concerns :range_searchable

  end

  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks', 
                                    sessions: 'users/sessions' }
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
concern :range_searchable, BlacklightRangeLimit::Routes::RangeSearchable.new
  get 'share' =>'pages#show', key: 'share'

  resources :collections, only: [:index], controller: "collections_page"

  redirect_all_proc = Proc.new { match '(*any)', to: redirect('/'), via: [:get, :post] }

  # Redirects non-privileged users to the application homepage
  authenticate :user, lambda { |u| !u.admin? && !u.contentadmin? } do
    namespace :dashboard, &redirect_all_proc
    namespace :notifications, &redirect_all_proc
  end
end

Bulkrax::Engine.routes.draw do
concern :range_searchable, BlacklightRangeLimit::Routes::RangeSearchable.new
  # Redirects non-privileged users to the application homepage
  redirect_all_proc = Proc.new { match '(*any)', to: redirect('/'), via: [:get, :post] }
  authenticate :user, lambda { |u| !u.admin? && !u.contentadmin? } do
    namespace :importers, &redirect_all_proc
    namespace :exporters, &redirect_all_proc
  end
end