# config/initializers/schoolie_override.rb
module SchoolieHelper
  def schoolie_tags(concern, config = Rails.root.join("config/schoolie.yml"))
    m = load_map(config)
    tags = load_statics(m)
    tags = m["attributes"].each_with_object(tags) do |(k, v), r|
      [concern.send(v)].flatten.each do |z|
        r << tag.meta(name: k, content: z)
      end
    rescue StandardError
      warn("Undefined attribute mapping: #{k} -> #{v}")
    end
    tags.join("\n")
  end

  def load_statics(map)
    map["static"].map do |k, v|
      tag.meta(name: k, content: v)
    end
  end

  def load_map(config)
    @load_map ||= YAML.safe_load(File.open(config, "r"), [Symbol])
  end
end
