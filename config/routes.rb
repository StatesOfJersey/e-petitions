Rails.application.routes.draw do
  direct(:states_assembly) { "https://statesassembly.gov.je/" }

  constraints Site.constraints_for_public do
    controller 'parishes' do
      get '/parishes', action: 'index', as: :parishes
    end

    controller 'pages' do
      get '/',        action: 'index', as: :home
      get '/help',    action: 'help'
      get '/privacy', action: 'privacy'

      scope format: true do
        get '/browserconfig', action: 'browserconfig', constraints: { format: 'xml'  }
        get '/manifest',      action: 'manifest',      constraints: { format: 'json' }
      end
    end

    controller 'feedback' do
      scope '/feedback' do
        get  '/',       action: 'new',    as: :feedback
        post '/',       action: 'create', as: nil
        get  '/thanks', action: 'thanks', as: :thanks_feedback
      end
    end

    controller 'local_petitions' do
      scope '/petitions/local' do
        get '/',        action: 'index', as: :local_petitions
        get '/:id',     action: 'show',  as: :local_petition
        get '/:id/all', action: 'all',   as: :all_local_petition
      end
    end

    resources :petitions, only: %i[new show index] do
      collection do
        get  'check'
        get  'check_results'
        post 'new', action: 'create', as: nil
      end

      member do
        get 'count'
        get 'thank-you'
        get 'gathering-support'
        get 'moderation-info'
      end

      resources :sponsors, only: %i[new create], shallow: true do
        collection do
          post 'new', action: 'confirm', as: :confirm
          get  'thank-you'
        end

        member do
          get 'verify'
          get 'sponsored', action: 'signed', as: :signed
        end
      end

      resources :signatures, only: %i[new create], shallow: true do
        collection do
          post 'new', action: 'confirm', as: :confirm
          get  'thank-you'
        end

        member do
          get 'verify'
          get 'unsubscribe'
          get 'signed'
        end
      end
    end
  end

  constraints Site.constraints_for_moderation do
    get '/', to: redirect('/admin')

    namespace :admin do
      mount Delayed::Web::Engine, at: '/delayed'

      root to: 'admin#index'

      resource :parliament, only: %i[show update]
      resource :search, only: %i[show]

      resources :admin_users
      resources :profile, only: %i[edit update]
      resources :user_sessions, only: %i[create]

      resources :invalidations, except: %i[show] do
        post :cancel, :count, :start, on: :member
      end

      resource :moderation_delay, only: %i[new create], path: 'moderation-delay'

      resources :petitions, only: %i[show index] do
        resources :emails, controller: 'petition_emails', except: %i[index show]
        resource  :lock, only: %i[show create update destroy]
        resource  :moderation, controller: 'moderation', only: %i[update]

        scope only: %i[show update] do
          resource :debate_outcome, path: 'debate-outcome'
          resource :government_response, path: 'ministers-response', controller: 'government_response', as: 'ministers_response'
          resource :notes
          resource :details, controller: 'petition_details'
          resource :schedule_debate, path: 'schedule-debate', controller: 'schedule_debate'
          resource :tags, controller: 'petition_tags'
          resource :take_down, path: 'take-down', controller: 'take_down'
        end
      end

      resource :rate_limits, path: 'rate-limits', only: %i[edit update]
      resource :site, only: %i[edit update]
      resource :holidays, only: %i[edit update]

      resources :signatures, only: %i[index destroy] do
        post :validate, :invalidate, on: :member
        post :subscribe, :unsubscribe, on: :member

        collection do
          delete :destroy, action: :bulk_destroy
          post   :validate, action: :bulk_validate
          post   :invalidate, action: :bulk_invalidate
          post   :subscribe, action: :bulk_subscribe
          post   :unsubscribe, action: :bulk_unsubscribe
        end
      end

      resources :tags, except: %i[show]

      scope 'stats', controller: 'statistics' do
        get '/', action: 'index', as: :stats
        get '/moderation/:period', action: 'moderation', as: :moderation_stats, period: /week|month/
      end

      controller 'user_sessions' do
        get '/logout',   action: 'destroy'
        get '/login',    action: 'new'
        get '/continue', action: 'continue'
        get '/status',   action: 'status'
      end
    end
  end

  get 'ping', to: 'ping#ping'

  if defined?(JasmineRails)
    mount JasmineRails::Engine, at: '/specs'
  end
end
