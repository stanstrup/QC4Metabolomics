SELECT if(count(*) > 0, 1, 0) FROM information_schema.TABLES WHERE (TABLE_SCHEMA = DATABASE()) AND (TABLE_NAME IN ('cont_data', 'cont_cmp'))
