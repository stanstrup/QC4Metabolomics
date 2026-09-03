SELECT CASE
  WHEN (SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME IN ('cont_data', 'cont_cmp')) < 2 THEN 0
  ELSE (SELECT IF(COUNT(*) > 0, 1, 0) FROM cont_cmp)
END
