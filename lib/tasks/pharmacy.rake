namespace :pharmacy do
  desc "Testa o parser de uma farmácia ao vivo. Ex.: rake 'pharmacy:test[paguemenos,dove antitranspirante]'"
  task :test, [ :slug, :query ] => :environment do |_t, args|
    slug  = args[:slug].to_s.strip
    query = args[:query].to_s.strip

    if slug.empty? || query.empty?
      abort <<~USO
        Uso: rake 'pharmacy:test[slug,termo de busca]'
        Ex.: rake 'pharmacy:test[paguemenos,dove antitranspirante]'

        Slugs disponíveis: #{Dir[Rails.root.join('config/pharmacies/*.yml')].map { |f| File.basename(f, '.yml') }.sort.join(', ')}
      USO
    end

    config =
      begin
        PharmacyConfig.load(slug)
      rescue Errno::ENOENT
        abort "Farmácia '#{slug}' não encontrada em config/pharmacies/#{slug}.yml"
      rescue PharmacyConfig::InvalidConfig => e
        abort "YAML de '#{slug}' inválido: #{e.message}"
      end

    puts "Farmácia: #{config.name} (#{config.slug})  ·  mode: #{config.mode}"
    puts "Busca:    #{query}"
    puts "URL:      #{config.search_url(query)}"
    puts "-" * 76

    results =
      begin
        PharmacyExtractor.new(config).search(query)
      rescue => e
        abort "Falha ao buscar/parsear: #{e.class} — #{e.message}"
      end

    if results.empty?
      abort "Nenhum resultado. O parser não extraiu nada — confira o caminho de 'results' no YAML."
    end

    campos = %i[nome preco preco_original fabricante apresentacao promocao sku_id imagem url]

    results.each_with_index do |r, i|
      puts "##{i + 1} #{r.nome}"
      campos.each do |campo|
        next if campo == :nome
        puts "    #{campo.to_s.ljust(15)} #{r.public_send(campo).inspect}"
      end
      puts ""
    end

    total = results.size
    puts "-" * 76
    puts "#{total} resultado(s). Cobertura por campo (preenchidos / total):"
    campos.each do |campo|
      preenchidos = results.count { |r| r.public_send(campo).present? }
      flag = preenchidos.zero? ? "  ← vazio em todos" : ""
      puts "    #{campo.to_s.ljust(15)} #{preenchidos}/#{total}#{flag}"
    end
  end
end
