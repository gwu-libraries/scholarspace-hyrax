class GwAffiliationAttributeRenderer < Hyrax::Renderers::AttributeRenderer
  def attribute_value_to_html(value)
    %(<span itemprop="gw_affiliation">#{::GwAffiliationsService.label(value)}</span>)
  end
end
