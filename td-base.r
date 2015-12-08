library("quantmod")  
library("ggplot2")
library("rvest")
library("reshape2")
library("lubridate")

get_year <- function(date){
  return(format(date, "%Y")) 
}

count_values <- function(val, vec){
  return(length(vec[vec == val]))
}

get_workdays <- function(start, end, dates_file='data/dates.csv'){
    workdays = as.Date(read.csv(dates_file)[,1])
    workdays = workdays[workdays <= end]
    workdays = workdays[workdays > start]
    return(as.Date(workdays))
}

taxa_diaria <- function(data, lista_juros, n_dias) {
  year = get_year(data)
  t <- (((lista_juros[[year]]/100 + 1))^(1/n_dias) - 1)
  return(t)  
}

valor_futuro <- function(txs_dia, valor_ini){
  
  serie = valor_ini
  for (i in 1:(length(txs_dia)-1)){
    serie = c(serie, serie[i]*(1 + txs_dia[i]))
  }
    
  return(serie)
}

get_fatia_ir <- function(n){

    if (n > 720) {
        imposto <- 15    
    }
    if(n <= 720){
        imposto <- 17.5  
    }
    if(n <= 360){
        imposto <- 20  
    }
    if(n <= 180){
        imposto <- 22.5  
    }
    
    return((100 - imposto)/100)
    
}

get_n_dias <- function(data_fim, data_ini){
    
    return(as.Date(data_fim) - as.Date(data_ini)) 
}

imposto_renda <- function(datas) {
  
    n_dias = unlist(lapply(datas, get_n_dias, head(datas,1)))
    faixas_ir = lapply(n_dias, get_fatia_ir)
    return(unlist(faixas_ir))
}
  
correct_workday <- function(datas, date, increase=TRUE){
    
    while(!(date %in% datas)){
        if (increase){
            date <- date + 1
        }
        else {
            date <- date - 1
        }
    }
    return(date)
}
 
calcular_cupons <- function(serie_td, tx_cupom, data_ini, data_fim){
    
    datas = get_workdays(data_ini, data_fim)
  
    venc = tail(datas,1)
    cupom_dates = c()
    while(venc > head(datas, 1)){
        cupom_dates <- c(cupom_dates, as.Date(venc))
    month(venc) <- month(venc) - 6
    }
    cupom_dates = as.Date(cupom_dates)
    cupom_vals = c()
    c_dates = c()
    for (date in sort(cupom_dates)) {
       c_date = correct_workday(datas, date)
       c_dates = c(c_dates, c_date)
       cupom_vals <- c(cupom_vals, drop(coredata(serie_td[as.Date(c_date)]) * ((1 + tx_cupom/100)^(1/2) - 1)))
    }
    df1 = xts(cupom_vals, sort(as.Date(c_dates)))
    df2 = xts(rep(0, length(datas)), datas)
    df3 = merge.xts(df1, df2)
    return(xts(cumsum(rowSums(df3, na.rm=TRUE)), datas))    
}
 
proj_tesdir <- function(valor_ini, juros_anuais, data_ini, data_fim){ 
  
  datas = get_workdays(data_ini, data_fim)
  
  if (typeof(juros_anuais) == 'double'){
    
    yini = get_year(head(datas, 1))
    yend = get_year(tail(datas, 1))
    yrange = as.character(as.numeric(yini):as.numeric(yend))
    
    val = juros_anuais
    juros_anuais = list()
    for (y in yrange) {
      juros_anuais[[y]] = val
    }
  } 

  txs_dia = unlist(lapply(datas, taxa_diaria, juros_anuais, 252))
  valores_ini = rep(valor_ini, length(datas))
  serie_td = valor_futuro(txs_dia, valor_ini)
  serie_ir = imposto_renda(datas)
  retornos = serie_td - valores_ini
  serie_td = serie_td + retornos*(serie_ir - 1)
  serie_td = xts(serie_td, datas)

  return(serie_td)
  
}

valor_de_resgate <- function(merged_proj, ...) {
    
    vencs = list(...)
    dates = index(merged_proj)
    resgts = xts(rep(0, length(dates)), dates)
    
    for (i in 1:length(vencs)){
        c_date = correct_workday(dates, as.Date(vencs[[i]]), increase=FALSE)
        resgts[c_date] = resgts[c_date] + merged_proj[,i][c_date]
    }
    return(cumsum(resgts))
    
}

extrair_ipca <- function(){
  
  site = read_html("http://www.valor.com.br/valor-data/indices-financeiros/indicadores-de-mercado")
  site %>% 
    html_node("#evolucao-das-aplicacoes-financeiras .row-1.vd-hide .last") %>%
    html_text() -> taxaIPCA
  taxaIPCA <- as.numeric(gsub(",",".",taxaIPCA))  
  
  return(taxaIPCA)
  
}

extrair_selic <- function(){
  
  site = read_html("http://www.valor.com.br/valor-data/indices-financeiros/indicadores-de-mercado")
  site %>% 
    html_node("#evolucao-das-aplicacoes-financeiras .row-2 .last") %>%
    html_text() -> taxaIPCA
  taxaSELIC <- as.numeric(gsub(",",".",taxaIPCA))  
  
  return(taxaSELIC)
  
}

retorno_total <- function(investimento, IR = TRUE, annualized = TRUE){
  
    retorno = tail(investimento$serie, 1)/tail(investimento$montante_ini,1)
    n_dias = length(investimento$datas)
    
    if(annualized){
        
        retorno = retorno^(252/n_dias)
        
    }
    
    if(IR) { imposto = imposto_renda(as.Date(investimento$datas[1]), Sys.Date()) }
    
    else { imposto = 1 }
    
    return((retorno - 1) * 100 * imposto)
}

retorno_instantaneo <- function(investimento,  annualized = TRUE){
    
    retorno = tail(investimento$serie, 2)[2]/tail(investimento$serie, 2)[1]
    
    if(annualized){
        
        retorno = retorno^(252)
        
    }
    
    return((retorno - 1) * 100)
    
}

