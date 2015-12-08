### r-tesouro-direto ###
### Projecões de Investimentos no Tesouro Direto ###

# colocar aqui o working directory
# windows: usar barras duplas -> '\\'
setwd('your-path/r-tesouro-direto')

# compilar o script base
source('your-path/td-base.r')

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

### Gerar projecões ###

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

### Tesouro IPCA (NTN-B Principal) ###

# vencimento em 2019, montante inicial de 10000, taxa de 6%
ipca_2019 = list(montante_ini = 10000, 
                 tx_anual = 6.00 + extrair_ipca(),
                 data_ini = "2016-01-01",
                 data_venc = "2019-05-15")

# série temporal
serie_ipca_2019 = proj_tesdir(ipca_2019[['montante_ini']],
                              ipca_2019[['tx_anual']],
                              ipca_2019[['data_ini']],
                              ipca_2019[['data_venc']])

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

# unindo os dataframes que serão plotados
to_plot = cbind(data.frame(merged_proj), 
                data.frame(imobilizado),
                data.frame(resgates),
                data.frame(dates = index(merged_proj)))

# formatando o dataframe na forma adequada para o ggplo2
plot_df = melt(to_plot, 'dates')

# criando o gráfico
plt = ggplot(plot_df,aes(x=dates,y=value,group=variable,color=variable)) 
plt + geom_line() + scale_x_date() + ggtitle("Portfolio corrente")




