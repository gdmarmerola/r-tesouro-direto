# r-tesouro-direto

## Projeções de Investimentos no Tesouro Direto com R

No período recente de alta da taxa de juros e inflação crescente (2014-2015), o Tesouro Direto tem se mostrado uma boa opção de investimento. Visualizar a evolução de diversas carteiras hipotéticas e compará-las ao longo do tempo pode ajudar significativamente o investidor a fazer uma alocação de recursos alinhada com seus objetivos. Este pacote usa alguns recursos de *web scraping* e o pacote gráfico *ggplot2* do R para fazer algumas estimativas e projeções de investimentos no tesouro direto.

* **Modalidades implementadas:**
	*  Tesouro Prefixado (LTN)
	*  Tesouro IPCA (NTN-B Principal)
	*  Tesouro IPCA com Juros Semestrais (NTN-B)
*  **Não-implementadas (to-do):**
	* Tesouro Prefixado com Juros Semestrais (NTN-F)
	* Tesouro Selic (LFT)
* **Pacotes necessários:**
	* quantmod: séries temporais, modelagem financeira 
	* ggplot2: gráficos
	* rvest: web scraping
	* reshape2: formatação de *dataframes*
	* lubridate: trabalhar com datas

### Funcionamento

O objetivo do pacote é criar séries temporais a partir de informações de investimentos. São utilizadas duas funções básicas:

#### proj_tesdir: criar série temporal de investimento

```{r}
proj_tesdir(valor_ini, juros_anuais, data_ini, data_fim)
```

* valor_ini: montante inicial do investimento
* juros_anuais: número que represente a média prevista dos juros no período, ou lista que associe um valor de juros por ano (mais na seção **Funcionalidades**)
* data_ini, data_fim: datas de início e fim do investimento

#### calcular_cupons: calcular pagamento de cupons

```{r}
calcular_cupons(serie_td, tx_cupom, data_ini, data_fim)
```
* serie_td: série temporal do principal
* juros_anuais: juros associados ao pagamento de cupons
* data_ini, data_fim: datas de início e fim do investimento

Para entender melhor como essas funções são utilizadas segue um exemplo de utilização.

### Exemplo de utilização

Um [script de exemplo](https://github.com/gdmarmerola/r-tesouro-direto/blob/master/td-exemplo.r) é fornecido no repositório. Para começar a usar as funções, devemos compilar o script base:

```{r}
# colocar aqui o working directory
# windows: usar barras duplas -> '\\'
setwd('your-path/r-tesouro-direto')

# compilar o script base
source('your-path/td-base.r')
```

Utilizando as funções mencionadas anteriormente, podemos estimar projeções para as modalidades disponíveis de investimento.

#### Tesouro Prefixado

Uma maneira organizada de gerenciar as informações é criar um objeto *list()* e utilizar suas entradas como argumentos da função *proj_tesdir*:

```{r}
### Tesouro Prefixado (LTN) ###

# valor inicial: 3000, taxa prefixada 13% a.a.
# duracão do investimento: 1 ano (01-01-2016 até 01-01-2017)
prefix_2017 = list(montante_ini = 3000, 
                   tx_anual = 13,
                   data_ini = "2016-01-01",
                   data_venc = "2017-01-01")

# cria uma série temporal (xts) com a projecão do investimento
serie_prefix_2017 = proj_tesdir(prefix_2017[['montante_ini']],
                                prefix_2017[['tx_anual']],
                                prefix_2017[['data_ini']],
                                prefix_2017[['data_venc']])

```

#### Tesouro IPCA

Aqui é utilizada a função *extrair_ipca()* para buscar o valor (12 meses) do IPCA no site do Valor Econômico. É importante ressaltar que dessa forma existe a aproximação que o IPCA não mudará ao longo do investimento. Porém, é possível definir uma lista com um valor de IPCA por ano, para um ajuste mais fino (como mostrado na seção **Funcionalidades**).  

```{r}
### Tesouro IPCA (NTN-B Principal) ###

# vencimento em 2019, montante inicial de 10000, taxa de 6%
ipca_2019 = list(montante_ini = 10000, 
                 tx_anual = 6.00 + extrair_ipca(), # 6% rendimento real
                 data_ini = "2016-01-01",
                 data_venc = "2019-05-15")

# série temporal
serie_ipca_2019 = proj_tesdir(ipca_2019[['montante_ini']],
                              ipca_2019[['tx_anual']],
                              ipca_2019[['data_ini']],
                              ipca_2019[['data_venc']])
```

#### Tesouro IPCA com Juros Semestrais

Nesta modalidade há o pagamento de juros semestrais. Portanto, no objeto *list()* é colocada uma entrada *tx_cupom* para representar os juros semestrais. Ao final, são criadas duas séries, uma representando o montante principal e outra o pagamento de cupons.

```{r}
### Tesouro IPCA com cupons semestrais (NTN-B) ###

# supondo VNA de 3000 e compra de 2 unidades: 6000
vna_exemplo = 3000

ipca_2020 = list(montante_ini = 2*vna_exemplo,
                 tx_anual = extrair_ipca(),
                 tx_cupom = 6,
                 data_ini = "2016-02-01",
                 data_venc = "2020-08-15"
                 )

# série temporal
serie_ipca_2020 = proj_tesdir(ipca_2020[['montante_ini']],
                              ipca_2020[['tx_anual']],
                              ipca_2020[['data_ini']],
                              ipca_2020[['data_venc']])

# calcula os cupons com base na série principal
ipca_2020_cups = calcular_cupons(serie_ipca_2020,
                                 ipca_2020[['tx_cupom']],
                                 ipca_2020[['data_ini']],
                                 ipca_2020[['data_venc']])
```

#### Fluxo de caixa

Após criar as séries temporais, podem ser criadas mais duas séries de apoio:

* *imobilizado*: representa o total investido
* *resgates*: mostra o fluxo de pagamentos

Dessa forma, é possível visualizar uma estimativa do fluxo de caixa do investidor ao longo do tempo, informação valiosa no ato de alocar recursos. No pacote isso é feito da seguinte maneira:

```{r}

## desempenho geral

# juntar projecões em um único dataframe
merged_proj = merge.xts(serie_prefix_2017, serie_ipca_2019, 
                        serie_ipca_2020, ipca_2020_cups) #["/2015-09-04"]

# série que mostra o fluxo de pagamentos
fluxo_resgate = valor_de_resgate(merged_proj,
                                 "2017-01-01",
                                 "2019-05-15",
                                 "2020-08-15")
      
# série que mostra o total investido 
imobilizado = rowSums(merged_proj[,1:3], na.rm=TRUE)

# fluxo de pagamentos: removendo NAs
resgates = rowSums(merge.xts(merged_proj[,4], fluxo_resgate), na.rm=TRUE)

```

#### Gerar gráficos

Antes de gerar os gráficos, é feita uma etapa de pré-processamento de forma que as séries estejam em um formato fácil de ser utilizado com o ggplot. 

```{r}
# unindo os dataframes que serão plotados
to_plot = cbind(data.frame(merged_proj), 
                data.frame(imobilizado),
                data.frame(resgates),
                data.frame(dates = index(merged_proj)))

# formatando o dataframe na forma adequada para o ggplo2
plot_df = melt(to_plot, 'dates')
```

Finalmente, podemos plotar as séries.

```{r}
# criando o gráfico
plt = ggplot(plot_df,aes(x=dates,y=value,group=variable,color=variable)) 
plt + geom_line(aes(group=variable),size=1) + scale_x_date() + ggtitle("Portfolio corrente") 
```

Em azul escuro, é mostrado o total investido e sua evolução com o tempo. Em lilás, o "fluxo de caixa" do investidor. Cada investimento é representado por uma linha (se não houver pagamento de cupons) ou duas (se houver pagamento de cupons). 

![](https://github.com/gdmarmerola/r-tesouro-direto/blob/master/exemplo-plot.png)

### Funcionalidades

Nesta seção são mostradas algumas funcionalidades interessantes do pacote.

#### Funções de apoio

Funções simples e úteis utilizadas para criar as séries temporais. 

``` {r}

### Funcões úteis ###

# 1) Extrair dias úteis entre duas datas:
# (usa o arquivo ./data/dates.csv como base)
# formato deve ser 'YYYY-MM-DD'
print( get_workdays('2015-01-01', '2015-01-10') ) 

# 2) Número de dias entre duas datas (corridos)
print( get_n_dias('2015-01-10', '2015-01-01') )

# 3) Retornar fatia do IR correspondente ao intervalo de dias
print( get_fatia_ir(100) ) # 1a faixa
print( get_fatia_ir(200) ) # 2a faixa
print( get_fatia_ir(400) ) # 3a faixa
print( get_fatia_ir(800) ) # 4a faixa

# 4) Extrair IPCA do site Valor Econômico (12 meses) 
print( extrair_ipca() )

# 5) Extrair Selic do site Valor Econômico (12 meses)
print( extrair_selic() )

``` 

#### Cálculo automático do IR

O Imposto de Renda é calculado e descontado automaticamente nas projeções, segundo as regras do [tesouro direto](http://www.tesouro.fazenda.gov.br/detalhes-da-tributacao-do-tesouro-direto). Nos momentos em que há mudança de faixa na alíquota de imposto é possível observar pequenos saltos na rentabilidade:

``` {r}
plot(serie_ipca_2019)
```

![](https://github.com/gdmarmerola/r-tesouro-direto/blob/master/exemplo-ir.png)

#### Definição de lista de juros anuais

Para sanar o problema de utilizar uma única taxa de juros para todo o período de um investimento, é possível criar uma lista em que cada entrada corresponde à uma taxa prevista para um ano. Vamos utilizar 3 exemplos: 

* IPCA constante ao longo do investimento
* IPCA crescente ao longo do investimento
* IPCA decrescente ao longo do investimento

Nota: a variação das taxas são um pouco exageradas de forma que as diferenças entre os exemplos sejam visíveis.

#### IPCA constante

A projeção neste caso é feita da mesma forma mostrada no script exemplo:

``` {r} 
taxa_constante = 10

ipca_constante = list(montante_ini = 10000, 
                      tx_anual = taxa_constante,
                      data_ini =  "2015-01-01",
                      data_venc = "2019-05-15")

# série temporal
serie_ipca_constante = proj_tesdir(ipca_constante[['montante_ini']],
                                   ipca_constante[['tx_anual']],
                                   ipca_constante[['data_ini']],
                                   ipca_constante[['data_venc']])

plot(serie_ipca_constante)
```

![](https://github.com/gdmarmerola/r-tesouro-direto/blob/master/ipca-constante.png)

#### IPCA crescente

Neste caso, vamos supor que o IPCA aumente no ritmo de 2% ao ano. Para representar isto, utilizamos um objeto do tipo *list()*, *taxa_crescente*.

``` {r}
# ipca aumentando 2% a cada ano
taxa_crescente = list('2015' = 10,
                      '2016' = 12,
                      '2017' = 14,
                      '2018' = 16,
                      '2019' = 18) 

ipca_crescente = list(montante_ini = 10000, 
                      tx_anual = taxa_crescente,
                      data_ini =  "2015-01-01",
                      data_venc = "2019-05-15")

# série temporal
serie_ipca_crescente = proj_tesdir(ipca_crescente[['montante_ini']],
                                   ipca_crescente[['tx_anual']],
                                   ipca_crescente[['data_ini']],
                                   ipca_crescente[['data_venc']])

plot(serie_ipca_crescente)
```

![](https://github.com/gdmarmerola/r-tesouro-direto/blob/master/ipca-crescente.png)

#### IPCA decrescente

Finalmente, aqui vemos o caso inverso do anterior, em que o IPCA cai 2% ao ano até o fim do investimento.

```{r}
# fazer a projecão de um IPCA 2019 utilizando taxas previstas para cada ano

# ipca diminuindo 2% a cada ano 
taxa_decrescente = list('2015' = 10,
                        '2016' = 8,
                        '2017' = 6,
                        '2018' = 4,
                        '2019' = 2) 

ipca_decrescente = list(montante_ini = 10000, 
                        tx_anual = taxa_decrescente,
                        data_ini =  "2015-01-01",
                        data_venc = "2019-05-15")

# série temporal
serie_ipca_decrescente = proj_tesdir(ipca_decrescente[['montante_ini']],
                                     ipca_decrescente[['tx_anual']],
                                     ipca_decrescente[['data_ini']],
                                     ipca_decrescente[['data_venc']])

plot(serie_ipca_decrescente)
```

![](https://github.com/gdmarmerola/r-tesouro-direto/blob/master/ipca-decrescente.png)
