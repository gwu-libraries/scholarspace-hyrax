module Hyrax
  class FileSetPresenter
    include ModelProxy
    include PresentsAttributes
    include CharacterizationBehavior
    include WithEvents
    include DisplaysImage

    attr_accessor :solr_document, :current_ability, :request

    # @param [SolrDocument] solr_document
    # @param [Ability] current_ability
    # @param [ActionDispatch::Request] request the http request context
    def initialize(solr_document, current_ability, request = nil)
      @solr_document = solr_document
      @current_ability = current_ability
      @request = request
    end

    # CurationConcern methods
    delegate :stringify_keys, :human_readable_type, :collection?, :image?, :video?,
             :audio?, :pdf?, :office_document?, :representative_id, :to_s, to: :solr_document

    # Methods used by blacklight helpers
    delegate :has?, :first, :fetch, to: :solr_document

    # Metadata Methods
    # Added visibility for use in file_sets/media_display views
    delegate :title, :label, :description, :creator, :contributor, :subject,
             :publisher, :language, :date_uploaded,
             :embargo_release_date, :lease_expiration_date,
             :depositor, :keyword, :title_or_label, :keyword,
             :date_created, :date_modified, :itemtype,
             :original_file_id, :visibility,
             to: :solr_document

    def alpha_channels
      []
    end

    def single_use_links
      @single_use_links ||= SingleUseLink.where(itemId: id).map { |link| link_presenter_class.new(link) }
    end

    # The title of the webpage that shows this FileSet.
    def page_title
      "#{human_readable_type} | #{title.first} | ID: #{id} | #{I18n.t('hyrax.product_name')}"
    end

    # The first title assertion
    def first_title
      title.first
    end

    # The link text when linking to the show page of this FileSet
    def link_name
      current_ability.can?(:read, id) ? first_title : 'File'
    end

    def editor?
      current_ability.can?(:edit, solr_document)
    end

    def tweeter
      TwitterPresenter.twitter_handle_for(user_key: depositor)
    end

    def license
      return if solr_document.license.nil?
      solr_document.license.first
    end

    def stats_path
      Hyrax::Engine.routes.url_helpers.stats_file_path(self, locale: I18n.locale)
    end

    def events(size = 100)
      super(size)
    end

    # This overrides the method in WithEvents
    def event_class
      solr_document.to_model.model_name.name
    end

    def fixity_check_status
      Hyrax::FixityStatusPresenter.new(id).render_file_set_status
    end

    def parent
      @parent_presenter ||= fetch_parent_presenter
    end

    def user_can_perform_any_action?
      current_ability.can?(:edit, id) || current_ability.can?(:destroy, id) || current_ability.can?(:download, id)
    end

    # Adding method to create permanent URL for file_set view, for accessibility form
    def permanent_url
      Scholarspace::Application.config.permanent_url_base + "concern/file_sets/#{id}"
    end

    private

      def link_presenter_class
        SingleUseLinkPresenter
      end

      def fetch_parent_presenter
        ids = ActiveFedora::SolrService.query("{!field f=member_ids_ssim}#{id}",
                                              fl: ActiveFedora.id_field)
                                       .map { |x| x.fetch(ActiveFedora.id_field) }
        Hyrax::PresenterFactory.build_for(ids: ids,
                                          presenter_class: WorkShowPresenter,
                                          presenter_args: current_ability).first
      end
  end
end
