SELECT if(count(*) > 0, 1, 0)FROM information_schema.TABLES WHERE (TABLE_SCHEMA = 'qc_db') AND (TABLE_NAME IN ('std_stat_data','std_compounds','std_stat_types')) 
