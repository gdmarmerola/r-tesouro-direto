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
