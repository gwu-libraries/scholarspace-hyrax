# frozen_string_literal: true

require 'json'
require 'nokogiri'
namespace :schoolie do
  task sitemap: :environment do
    date_field = 'system_modified_dtsi'
    result = Hyrax::SolrService.new.get("has_model_ssim:GwEtd NOT keyword_tesim:*",
                                        fl: "id,#{date_field}",
                                        rows: 1_000_000)
    ids = result['response']['docs'].map do |x|
      ["https://scholarspace.library.gwu.edu/etd/#{x['id'].to_s}", x[date_field].to_s]
    end
    builder = Nokogiri::XML::Builder.new do |sitemap|
      sitemap.urlset("xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance",
                 xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9",
                 "xsi:schemaLocation": "http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd") {
                   ids.each { |url, date|
                     sitemap.url {
                       sitemap.loc url
                       sitemap.lastmod date
                     }
                   }
                 }
    end
    File.open(Rails.root.join("public", "sitemap.xml"), "w") { |f| f.write(builder.to_xml) }
  end
end
