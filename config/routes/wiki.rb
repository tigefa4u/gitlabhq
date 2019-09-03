scope(controller: :wikis) do
  scope(path: 'wikis', as: :wikis) do
    get :git_access
    get :pages
    get '/', to: redirect('%{namespace_id}/%{project_id}/wiki_page/home')
    get '/*id', to: redirect('%{namespace_id}/%{project_id}/wiki_page/%{id}')
  end

  scope(path: 'wikis/pages', as: :wiki_pages, format: false) do
    get :new, to: 'wiki_pages#new'
    post '/', to: 'wiki_pages#create'
  end

  scope(path: 'wiki_page', as: :wiki_page, format: false) do
    post '/', to: 'wiki_pages#create'
  end

  scope(path: 'wiki_page/*id', as: :wiki, format: false, controller: :wiki_pages) do
    get :edit
    get :history
    post :preview_markdown
    get '/', action: :show
    put '/', action: :update
    delete '/', action: :destroy
  end

  scope(path: 'wiki_dir/*id', as: :wiki_dir, format: false, controller: :wiki_directories) do
    get '/', action: :show_dir
  end
end
