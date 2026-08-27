# Paracetacaro

*[Read this in English](README.md)*

Aplicação Rails que pesquisa preços de medicamentos em várias farmácias online em paralelo,
permite escolher o produto realmente equivalente em cada loja e monta um carrinho
comparativo sem fingir que catálogos diferentes combinam automaticamente.

Os resultados chegam por farmácia assim que cada busca termina. Você mantém o controle da
equivalência, dosagem, fabricante e tamanho da embalagem; o Paracetacaro cuida da pesquisa
repetitiva, da comparação de preços e dos links para compra.

## Como funciona

1. Digite o nome de um medicamento ou produto e escolha em quais farmácias pesquisar.
2. Um job roda para cada farmácia selecionada. Buscas em cache retornam imediatamente;
   resultados novos aparecem na página via Turbo Streams.
3. Cada farmácia ganha sua própria linha horizontal de resultados. Escolha o produto que é
   realmente comparável naquela loja ou deixe a farmácia vazia quando não houver opção
   adequada.
4. O carrinho mostra uma coluna por farmácia e uma coluna **Compra ideal**, que escolhe o
   menor preço selecionado para cada item.
5. Em lojas VTEX compatíveis, o carrinho inteiro daquela farmácia pode ser aberto diretamente
   no checkout. As demais seleções levam à página do produto para compra manual.

O Paracetacaro deliberadamente não usa IA nem normalização automática de produtos. Nomes,
dosagens, formas e quantidades variam o suficiente entre lojas para tornar uma escolha manual
e visível mais segura que uma correspondência automática confiante, porém incorreta.

## Destaques

- Buscas paralelas com resultados ao vivo por farmácia.
- Seletor de farmácias, com todas as ativas marcadas por padrão.
- Cards com imagem, fabricante, preço atual, preço original, promoção e indicação de seller
  marketplace quando disponíveis.
- Produtos indisponíveis removidos antes da exibição.
- Carrinho de sessão com uma seleção por item e farmácia.
- Totais por farmácia e estratégia de menor preço item a item.
- Checkout VTEX direto nas lojas compatíveis.
- Cache de aproximadamente uma hora por farmácia e termo, reduzindo requisições repetidas.
- Extratores de farmácia definidos em YAML, nos modos API e HTML.

## Farmácias suportadas

| Farmácia | Busca | Checkout | Observações |
|---|---:|---:|---|
| Pague Menos | Sim | Sim | API VTEX Catalog |
| Drogaria São Paulo | Sim | Sim | API VTEX Catalog |
| Rosário | Sim | Não | A busca funciona; o endpoint de checkout da loja não é compatível |
| Drogasil | Desabilitada | Não | A loja bloqueia os clientes HTTP automatizados disponíveis |

Lojas e APIs de terceiros mudam sem aviso. Uma farmácia marcada como suportada pode precisar
de ajuste no parser quando sua resposta de catálogo ou política antibot mudar.

## Início rápido

### Requisitos

- Docker
- Docker Compose

### Executar localmente

```bash
git clone https://github.com/marcelomogami/paracetacaro.git
cd paracetacaro
docker compose build
docker compose run --rm app bin/rails db:prepare
docker compose up
```

Abra `http://localhost:3000/setup` e crie o primeiro usuário. Essa primeira conta se torna o
administrador local; novos cadastros não ficam abertos depois do setup.

O desenvolvimento local não precisa de credenciais de nenhuma instância hospedada. Para
parar a aplicação:

```bash
docker compose down
```

O Compose é voltado a desenvolvimento e testes. Ele não é um guia de produção e não deve ser
exposto diretamente à internet sem um projeto adequado de deploy e controle de acesso.

## Uso

### Pesquisar e comparar

Digite uma busca como `paracetamol 500mg`, mantenha marcadas as farmácias desejadas e inicie.
Os resultados aparecem de forma independente, então uma loja lenta ou com erro não bloqueia
as demais.

Confira dosagem, forma, fabricante, quantidade e vendedor antes de clicar em **Adicionar**.
Selecionar um produto numa farmácia não obriga a selecionar algo nas outras.

### Montar o carrinho

O carrinho usa uma linha por termo pesquisado e uma coluna por farmácia ativa. Uma célula
vazia é uma decisão válida: significa que nenhum equivalente aceitável foi selecionado
naquela loja.

A coluna **Compra ideal** escolhe o produto selecionado mais barato de cada linha. Ela pode
dividir o pedido entre várias farmácias, então o total é uma comparação de preço, não uma
promessa de checkout único ou frete menor.

### Abrir a loja

Quando a farmácia possui dados de SKU VTEX compatíveis, **Comprar tudo nesta farmácia** monta
uma URL de checkout a partir das seleções da coluna. Nos demais casos, use os links dos
produtos e conclua a compra manualmente no site da farmácia.

## Adicionar ou atualizar uma farmácia

Cada integração fica em `config/pharmacies/<slug>.yml`. O extrator genérico entende APIs JSON
e seletores HTML, portanto a maioria das mudanças de farmácia não exige uma classe Ruby nova.

Uma configuração mínima de API se parece com isto:

```yaml
name: Farmácia Exemplo
slug: exemplo
enabled: true
mode: api

search:
  url: "https://www.example.com/api/products?query={query}"

fields:
  results: "products"
  nome: "name"
  fabricante: "brand"
  preco: "offers[0].price"
  preco_original: "offers[0].listPrice"
  url: "url"
  imagem: "images[0].url"
```

Inspecione o parser contra uma resposta real com:

```bash
docker compose run --rm app bin/rails 'pharmacy:test[exemplo,paracetamol]'
```

O comando imprime todos os campos extraídos e um resumo de cobertura. Um campo vazio em todos
os resultados normalmente indica que o path do YAML deixou de corresponder à resposta.
Depois da alteração, rode as specs do extrator:

```bash
docker compose run --rm app bundle exec rspec spec/services/pharmacy_extractor_spec.rb
```

APIs VTEX podem exigir headers semelhantes aos de um navegador. Use o extrator da aplicação
para inspecionar respostas em vez de presumir que um `curl` simples é equivalente.

## Configuração hospedada opcional

O desenvolvimento local funciona sem estes valores. Um deploy de produção pode fornecê-los
pelo ambiente:

| Variável | Finalidade |
|---|---|
| `APP_HOST` | Host usado nos links gerados pelos mailers |
| `MAILER_FROM` | Remetente completo usado pelos mailers do Devise |
| `RESEND_API_KEY` | Credencial SMTP para recuperação de senha |
| `CLOUDFLARE_ACCESS_ISSUER` | Issuer HTTPS opcional do team no Cloudflare Access |
| `CLOUDFLARE_ACCESS_AUD` | Audience tag opcional usada para verificar JWTs do Access |
| `RAILS_MASTER_KEY` | Chave Rails padrão das credenciais criptografadas do deploy |

`APP_HOST`, `MAILER_FROM` e `RESEND_API_KEY` são obrigatórios no ambiente de produção atual.
Os valores do Cloudflare Access são opcionais; sem ambos, o auto-login pelo proxy fica
desabilitado e o login normal do Devise continua disponível.

## Verificações de desenvolvimento

Prepare o banco de teste e rode a suíte completa:

```bash
docker compose run --rm -e RAILS_ENV=test app bin/rails db:prepare
docker compose run --rm -e RAILS_ENV=test app bundle exec rspec
```

O workflow de CI também executa:

```bash
docker compose run --rm app bin/rubocop
docker compose run --rm app bin/brakeman --no-pager
docker compose run --rm app bin/bundler-audit
docker compose run --rm app bin/importmap audit
```

Mudanças no código da aplicação seguem Red, Green, Refactor: escreva primeiro a spec que
falha, implemente a menor mudança funcional e refatore mantendo a suíte verde.

## Arquitetura

O Paracetacaro usa Ruby 3.4 e Rails 8.1. O SQLite armazena os dados da aplicação e também
sustenta Solid Queue, Solid Cache e Solid Cable, portanto o app não depende de PostgreSQL ou
Redis. Cada farmácia selecionada é pesquisada por um job independente, e Turbo Streams
entregam sua linha de resultados assim que ela fica pronta.

O extrator genérico usa Faraday e Nokogiri para APIs JSON e páginas HTML. O Ferrum fica
disponível como fallback para integrações que exigem JavaScript. A interface usa Bootstrap
5.3, Bootstrap Icons, Turbo e Stimulus.

## Segurança e dados

- A primeira conta local fica no SQLite com hash de senha do Devise. Use uma senha de
  desenvolvimento, não uma senha reutilizada em outros serviços.
- As buscas fazem requisições reais a sites de farmácias. Disponibilidade, termos, limites e
  respostas desses serviços permanecem fora do controle do projeto.
- Resultados ficam em cache temporário; o Paracetacaro não é uma base histórica de preços.
- Links de produto e checkout saem da aplicação e abrem sites de terceiros. Sempre confirme
  produto, quantidade, vendedor, preço, frete e exigências de receita na loja antes de
  comprar.
- Credenciais, acesso a instâncias hospedadas e procedimentos específicos de produção ficam
  intencionalmente fora deste README público.

## Limitações conhecidas

- A equivalência entre produtos é manual. A aplicação não garante que dois medicamentos
  selecionados tenham o mesmo princípio ativo, dosagem, forma ou quantidade.
- A comparação de preço por unidade ainda não foi implementada, então embalagens diferentes
  exigem atenção adicional.
- Scrapers podem quebrar quando uma farmácia altera sua API, HTML ou proteção antibot.
- Preços e disponibilidade podem variar por região, conta, programa de fidelidade ou seller
  marketplace.
- O checkout se limita a configurações VTEX compatíveis; não automatiza login, pagamento,
  entrega ou tratamento de receita.
- Os carrinhos são orientados à sessão. Carrinhos nomeados por usuário e histórico de buscas
  não fazem parte do escopo atual.

## Estrutura

```text
app/
  controllers/             # busca, carrinho, setup, sessões e administração de usuários
  jobs/search_job.rb        # busca em background, cache e broadcasts Turbo Stream
  models/                   # usuários, carrinhos, configuração de farmácia e resultados
  services/
    pharmacy_extractor.rb   # extração genérica por API/HTML
    vtex_checkout_service.rb
config/
  pharmacies/              # um parser YAML por farmácia
spec/                       # modelos, serviços, jobs, requests e views em RSpec
```

## Contribuindo

Issues e pull requests são bem-vindos. Em mudanças de parser, inclua o slug da farmácia, um
termo de exemplo, a cobertura de campos observada e as specs relevantes. Rode as
verificações acima antes de abrir um pull request e nunca inclua credenciais reais, dados de
usuários ou detalhes privados de deploy.

## Escopo atual

O Paracetacaro é uma ferramenta pequena e self-hosted para comparar um conjunto limitado de
farmácias online brasileiras. O código pode ser estudado, modificado e estendido, mas não há
serviço hospedado público, garantia de cobertura das lojas ou suporte comercial.

A interface e o vocabulário de domínio permanecem intencionalmente em português do Brasil.
O Paracetacaro é localizado para usuários e farmácias brasileiras; o inglês é usado na
documentação pública principal, não como idioma do produto.

## Licença

[MIT](LICENSE). Feito para uso pessoal, mas livre para usar, modificar e adaptar.
