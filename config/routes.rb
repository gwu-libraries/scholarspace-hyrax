Rails.application.routes.draw do

  mount Bulkrax::Engine, at: '/'
  mount Riiif::Engine => 'images', as: :riiif if Hyrax.config.iiif_image_server?
  mount BrowseEverything::Engine => '/browse'
  
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

  devise_for :users
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
  mount Sidekiq::Web => '/sidekiq'

  match '*path', to: 'errors#not_found', via: :all, format: false, defaults: { format: 'html' }

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
