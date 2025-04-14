Sys.time()

tab_out <-                "
SELECT file_info.mode, file_info.time_run, files.path, std_stat_data.*, std_stat_types.stat_name, std_compounds.cmp_name, std_compounds.cmp_mz, std_compounds.cmp_rt1, std_compounds.updated_at
FROM file_info 
LEFT JOIN files ON (file_info.file_md5 = files.file_md5)
LEFT JOIN std_stat_data ON (file_info.file_md5 = std_stat_data.file_md5)
LEFT JOIN std_stat_types ON(std_stat_types.stat_id = std_stat_data.stat_id)
LEFT JOIN std_compounds ON(std_compounds.cmp_id = std_stat_data.cmp_id)
WHERE (file_info.sample_id REGEXP '.*') 
AND (DATE(file_info.time_run) BETWEEN '2000-03-01' AND '2024-03-01') 
#AND (file_info.project in ('CoffeePilotHSST3NOPRE','CoffeePilotPremier','DIMEfecal','DIMEurine','EPO','EPOrerun','FamusFecal','FamusFecalStd','Ida plants std','Karhus2feacalmeta','KlausMuller','M185ms2','M198','M237 PRIMA','M237 PRIMA DDA','M240 Hotfacets','MarlouDirks','MarlouDirksRedo','MarlouDirksRerun','Martin_Karhus','Mcourse','METNEXS','NU-AGE','Orgtrace test','Pesticidtest','PRIMA in vivo metabolomic','PrimaFecal','Pyruvat and Hydroxybutyrate','Restrict','Restrict Carbohydrate','Restrict Enteral','Restrict Fruit','Restrict Legume','Restrict Meat','Restrict Vegetable','SKOT','Spaceomics','STD','Tryptophan metabolites','UntargetedPHL-Serum-Jesper','UntargetedPHL-Urin-Jesper','Urolithin')) 
AND (file_info.mode in ('pos','neg')) 
#AND (file_info.instrument in ('Snew'))
AND std_stat_types.stat_name in ('TF', 'ASF', 'datapoints', 'into', 'sn', 'rt_dev', 'mz_dev_ppm', 'FWHM')

;


" %>% 
                                     dbGetQuery(pool,.) %>% 
                                     as_tibble %>% 
      mutate(across(c(updated_at, time_run), ~as.POSIXct(., tz="UTC", format="%Y-%m-%d %H:%M:%S"))) %>% 
      mutate(time_run = with_tz(time_run, Sys.timezone(location = TRUE))) %>% # time zone fix
      mutate(filename = sub('\\..*$', '', basename(path)))




Sys.time()

tab_out %>% 
 filter(stat_id == stat_name2id("rt_dev")) %>%
                                ggplot(aes(x=time_run, y=value, group=cmp_name, color=cmp_name)) %>% 
                                {std_stats_plot_common(.) + 
                                labs(y = "Retention time deviation (min)", x = "Run time") +
                                ggtitle("Retention time deviation")} %>% 
            
                                ggplotly(dynamicTicks = TRUE, tooltip = c("group", "text", "x", "y")) %>% 
                                plotly_build


Sys.time()

