class SearchJob < ApplicationJob
  queue_as :default

  def perform(query:, pharmacy_slug:, stream_name:)
    config  = PharmacyConfig.load(pharmacy_slug)
    results = cached_results(query, pharmacy_slug) { PharmacyExtractor.new(config).search(query) }

    Turbo::StreamsChannel.broadcast_replace_to(
      stream_name,
      target:  "pharmacy_#{pharmacy_slug}_results",
      partial: "searches/pharmacy_results",
      locals:  { results: results, config: config, query: query }
    )
  rescue => e
    Rails.logger.error("[SearchJob] #{pharmacy_slug}: #{e.message}")

    Turbo::StreamsChannel.broadcast_replace_to(
      stream_name,
      target:  "pharmacy_#{pharmacy_slug}_results",
      partial: "searches/pharmacy_error",
      locals:  { pharmacy_slug: pharmacy_slug, error: e.message }
    )
  end

  def self.cache_key_for(query, pharmacy_slug)
    "search/#{pharmacy_slug}/#{Digest::MD5.hexdigest(query.downcase.strip)}"
  end

  def self.read_cache(query, pharmacy_slug)
    Rails.cache.read(cache_key_for(query, pharmacy_slug))
  end

  private

  def cached_results(query, pharmacy_slug, &block)
    Rails.cache.fetch(self.class.cache_key_for(query, pharmacy_slug), expires_in: 1.hour, &block)
  end
end
