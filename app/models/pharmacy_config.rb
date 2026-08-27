require "dry-schema"

class PharmacyConfig
  class InvalidConfig < StandardError; end

  BASE_SCHEMA = Dry::Schema.Params do
    required(:name).filled(:string)
    required(:slug).filled(:string)
    required(:mode).filled(:string, included_in?: %w[api html])
    required(:search).hash do
      required(:url).filled(:string)
      optional(:needs_js).value(:bool)
    end
    optional(:enabled).value(:bool)
  end

  API_SCHEMA = Dry::Schema.Params do
    required(:fields).hash do
      required(:nome).filled(:string)
      required(:preco).filled(:string)
      required(:url).filled(:string)
      optional(:results).value(:string)
      optional(:fabricante).filled(:string)
      optional(:apresentacao).filled(:string)
      optional(:preco_original).filled(:string)
      optional(:imagem).filled(:string)
      optional(:sku_id).filled(:string)
    end
  end

  HTML_SCHEMA = Dry::Schema.Params do
    required(:selectors).hash do
      required(:results).filled(:string)
      required(:nome).filled
      required(:preco).filled
      required(:url).filled
      optional(:fabricante).filled
      optional(:apresentacao).filled
      optional(:preco_original).filled
      optional(:imagem).filled
    end
  end

  attr_reader :name, :slug, :mode, :search, :fields, :selectors

  def self.load(slug, base_path: Rails.root.join("config/pharmacies"))
    path = Pathname.new(base_path).join("#{slug}.yml")
    raise Errno::ENOENT, path.to_s unless path.exist?

    raw = YAML.safe_load_file(path)
    new(raw)
  end

  def self.load_all(base_path: Rails.root.join("config/pharmacies"))
    Dir[Pathname.new(base_path).join("*.yml")].filter_map do |path|
      slug = File.basename(path, ".yml")
      config = load(slug, base_path: base_path)
      config.enabled? ? config : nil
    rescue InvalidConfig => e
      Rails.logger.warn("[PharmacyConfig] #{slug}.yml inválido: #{e.message}")
      nil
    end
  end

  def initialize(attrs)
    validate!(attrs)
    @name      = attrs["name"]
    @slug      = attrs["slug"]
    @mode      = attrs["mode"]
    @enabled   = attrs.fetch("enabled", true)
    @checkout  = attrs.fetch("checkout", true)
    @search    = attrs["search"]
    @fields    = attrs["fields"]
    @selectors = attrs["selectors"]
  end

  def api?
    mode == "api"
  end

  def html?
    mode == "html"
  end

  def enabled?
    @enabled
  end

  def needs_js?
    html? && search.fetch("needs_js", false)
  end

  def site_url
    uri = URI.parse(search["url"].gsub("{query}", "x"))
    "#{uri.scheme}://#{uri.host}"
  end

  def vtex?
    api? && fields&.key?("sku_id")
  end

  def checkout?
    vtex? && @checkout
  end

  def search_url(query)
    search["url"].gsub("{query}", URI.encode_uri_component(query))
  end

  private

  def validate!(attrs)
    base = BASE_SCHEMA.call(attrs)
    raise InvalidConfig, base.errors.to_h.to_s if base.failure?

    mode_schema = attrs["mode"] == "api" ? API_SCHEMA : HTML_SCHEMA
    mode_result = mode_schema.call(attrs)
    raise InvalidConfig, mode_result.errors.to_h.to_s if mode_result.failure?
  end
end
