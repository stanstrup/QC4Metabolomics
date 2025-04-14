SELECT if(count(*) > 0, 1, 0) FROM information_schema.TABLES WHERE (TABLE_SCHEMA = 'qc_db') AND (TABLE_NAME IN ('warner_stat_types','warner_rules')) 
