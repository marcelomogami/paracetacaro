require "faraday"
require "nokogiri"
require "ferrum"

class PharmacyExtractor
  USER_AGENT = "paracetacaro/1.0 (comparador de preços, uso pessoal)"

  # Flags necessárias para o Chromium iniciar dentro de container (roda como
  # root, sem /dev/shm dimensionado). Sem no-sandbox o browser nem sobe.
  CHROME_OPTIONS = {
    "no-sandbox"            => nil,
    "disable-dev-shm-usage" => nil,
    "disable-gpu"           => nil
  }.freeze

  def initialize(config)
    @config = config
  end

  def search(query)
    url  = @config.search_url(query)
    body = fetch(url)

    @config.api? ? parse_api(body) : parse_html(body)
  end

  private

  def fetch(url)
    @config.needs_js? ? fetch_with_ferrum(url) : fetch_with_faraday(url)
  end

  def fetch_with_faraday(url)
    conn = Faraday.new(headers: { "User-Agent" => USER_AGENT }) do |f|
      f.response :raise_error
    end
    conn.get(url).body
  end

  def fetch_with_ferrum(url)
    browser = Ferrum::Browser.new(
      headless:        true,
      browser_path:    ENV["FERRUM_CHROME_PATH"],
      process_timeout: 20,
      timeout:         20,
      browser_options: CHROME_OPTIONS
    )
    browser.goto(url)
    begin
      browser.network.wait_for_idle(timeout: 8)
    rescue Ferrum::TimeoutError
      # SPA pode manter conexões abertas; segue com o que já renderizou
    end
    browser.body
  ensure
    browser&.quit
  end

  # --- API (JSON) ---

  def parse_api(body)
    items = JSON.parse(body)
    Array(items)
      .select { |item| disponivel?(item) }
      .map { |item| build_result_from_api(item) }
  end

  def build_result_from_api(item)
    f = @config.fields
    PharmacyResult.new(
      farmacia_slug:  @config.slug,
      farmacia_nome:  @config.name,
      nome:           dig_path(item, f["nome"]),
      preco:          dig_path(item, f["preco"]).to_f,
      url:            dig_path(item, f["url"]).to_s,
      fabricante:     dig_path(item, f["fabricante"]),
      apresentacao:   dig_path(item, f["apresentacao"]),
      preco_original: dig_path(item, f["preco_original"])&.to_f,
      imagem:         dig_path(item, f["imagem"]),
      sku_id:         dig_path(item, f["sku_id"])&.to_s,
      promocao:       format_teaser(dig_path_first(item, f["promocao"])),
      vendedor:       marketplace_seller(item, f)
    )
  end

  def format_teaser(text)
    return nil if text.nil?
    text.sub(/\A(\d+)\s+/, '-\1% ')
  end

  def marketplace_seller(item, f)
    return nil unless f["vendedor_id"] && f["vendedor_nome"]
    seller_id = dig_path(item, f["vendedor_id"]).to_s
    seller_id == "1" ? nil : dig_path(item, f["vendedor_nome"])
  end

  def disponivel?(item)
    path = @config.fields["disponivel"]
    return true if path.nil?
    dig_path(item, path) != false
  end

  # Aceita string ou array de paths — retorna o primeiro resultado não-nil
  def dig_path_first(obj, path_or_paths)
    Array(path_or_paths).each do |path|
      result = dig_path(obj, path)
      return result if result.present?
    end
    nil
  end

  # Resolve paths like "items[0].sellers[0].commertialOffer.Price"
  def dig_path(obj, path)
    return nil if path.nil? || path.strip.empty?

    tokens = path.scan(/[^\.\[\]]+|\d+(?=\])/).map { |t| t =~ /\A\d+\z/ ? t.to_i : t }
    tokens.reduce(obj) do |current, key|
      break nil if current.nil?
      current.is_a?(Array) ? current[key] : current[key.to_s]
    end
  end

  # --- HTML (Nokogiri) ---

  def parse_html(body)
    doc = Nokogiri::HTML(body)
    doc.css(@config.selectors["results"]).map { |node| build_result_from_html(node) }
  end

  def build_result_from_html(node)
    s = @config.selectors
    PharmacyResult.new(
      farmacia_slug:  @config.slug,
      farmacia_nome:  @config.name,
      nome:           extract(node, s["nome"]),
      preco:          to_price(extract(node, s["preco"])),
      url:            extract(node, s["url"]),
      fabricante:     extract(node, s["fabricante"]),
      apresentacao:   extract(node, s["apresentacao"]),
      preco_original: to_price(extract(node, s["preco_original"])),
      imagem:         extract(node, s["imagem"]),
      sku_id:         nil,
      promocao:       nil,
      vendedor:       nil
    )
  end

  def extract(node, selector_config)
    return nil if selector_config.nil?

    if selector_config.is_a?(Hash)
      el = node.css(selector_config["selector"]).first
      return nil unless el

      value = selector_config["attribute"] ? el[selector_config["attribute"]] : el.text.strip
      apply_transform(value, selector_config["transform"])
    else
      node.css(selector_config).first&.text&.strip
    end
  end

  def apply_transform(value, transform)
    return value unless transform == "strip_currency"
    # R$ 1.299,99 → "1299.99"
    value.to_s.gsub(/R\$\s*/, "").gsub(".", "").gsub(",", ".").strip
  end

  def to_price(value)
    return nil if value.nil? || value.to_s.strip.empty?
    value.to_s.gsub(/[^\d.]/, "").to_f.then { |f| f.zero? ? nil : f }
  end
end
