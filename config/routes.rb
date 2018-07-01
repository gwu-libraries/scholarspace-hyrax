Rails.application.routes.draw do
  
  get '/etd/:id', to: redirect('/concern/gw_etds/%{id}')
  get '/etds/:id', to: redirect('/concern/gw_etds/%{id}')
  get '/files/:id', to: redirect('concern/gw_works/%{id}')
  get '/works/:id', to: redirect('concern/gw_works/%{id}')
  get '/work/:id', to: redirect('concern/gw_works/%{id}')

  mount Blacklight::Engine => '/'
  
    concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :searchable
  end

  devise_for :users
  mount Hydra::RoleManagement::Engine => '/'

  mount Qa::Engine => '/authorities'
  mount Hyrax::Engine, at: '/'
  resources :welcome, only: 'index'
  root 'hyrax/homepage#index'
  curation_concerns_basic_routes
  concern :exportable, Blacklight::Routes::Exportable.new

  resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
    concerns :exportable
  end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete 'clear'
    end
  end

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
