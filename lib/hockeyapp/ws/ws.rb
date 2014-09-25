require 'httmultiparty'
require 'active_support/core_ext/hash'

module HockeyApp
  class WS
    include HTTMultiParty
    base_uri 'https://rink.hockeyapp.net/api/2'
    headers 'Accept' => 'application/json'
    format :json


    def initialize (options = {})
      @options = Config.to_h.merge(options)
      raise "No API Token Given" if (@options[:token].nil?)
      self.class.headers 'X-HockeyAppToken' => @options[:token]
      self.class.base_uri @options[:base_uri] if @options[:base_uri].present?
    end


    def get_apps
      self.class.get '/apps'
    end


    def get_crashes app_id, options = {}
      self.class.get "/apps/#{app_id}/crashes", options
    end

    def get_crash_groups app_id, options = {}
      self.class.get "/apps/#{app_id}/crash_reasons", options
    end

    def get_crash_groups_for_version app_id, version_id, options = {}
      self.class.get "/apps/#{app_id}/app_versions/#{version_id}/crash_reasons", options
    end

    def get_crashes_for_group app_id, group_id, options = {}
      self.class.get "/apps/#{app_id}/crash_reasons/#{group_id}", options
    end

    # this is damn not thread safe !
    def get_crash_log app_id, crash_id, options = {}
      self.class.format :plain
      log = self.class.get "/apps/#{app_id}/crashes/#{crash_id}?format=log", options
      self.class.format :json
      log
    end

    # this is damn not thread safe !
    def get_crash_description app_id, crash_id, options = {}
      self.class.format :plain
      description = self.class.get "/apps/#{app_id}/crashes/#{crash_id}?format=text", options
      self.class.format :json
      description
    end

    def get_versions app_id, options = {}
      self.class.get "/apps/#{app_id}/app_versions", options
    end

    def post_new_version(
        app_id,
            ipa,
            dsym=nil,
            notes="New version",
            notes_type=Version::NOTES_TYPES_TO_SYM.invert[:textile],
            notify=Version::NOTIFY_TO_BOOL.invert[:none],
            status=Version::STATUS_TO_SYM.invert[:allow],
            tags=''
    )
      params = {
          :ipa => ipa ,
          :dsym => dsym ,
          :notes => notes,
          :notes_type => notes_type,
          :notify => notify,
          :status => status,
          :tags => tags
      }
      params.reject!{|_,v|v.nil?}
      self.class.post "/apps/#{app_id}/app_versions/upload", :body => params
    end


    def remove_app app_id
      self.class.format :plain
      response = self.class.delete "/apps/#{app_id}"
      self.class.format :json
      response
    end

    def post_new_app(file_ipa, file_dsym=nil, options={})
      options = options.with_indifferent_access
      options[:notes]       ||= "New App"
      options[:notes_type]    = App::NOTES_TYPES_TO_SYM.invert[ options[:notes_type] || :textile ]
      options[:notify]        = App::NOTIFY_TO_BOOL.invert[ !!options[:notify] ]
      options[:status]        = App::STATUS_TO_SYM.invert[ options[:status] || :allow ]
      options[:release_type]  = App::RELEASETYPE_TO_SYM.invert[ options[:release_type] ] if options[:release_type]
      options[:ipa]           = file_ipa    if file_ipa
      options[:dsym]          = file_dsym   if file_dsym
      self.class.post "/apps/upload", :body => options
    end

    def post_new_app_without_file(options={})
      options = options.with_indifferent_access
      options[:title]           ||= "My Awesome App"
      options[:release_type]  = App::RELEASETYPE_TO_SYM.invert[ options[:release_type] ] if options[:release_type]
      self.class.post "/apps/new", :body => options
    end

  end
end
