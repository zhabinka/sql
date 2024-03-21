-- Период запуска autovacuum worker для каждой "активной" базы данных из списка
show autovacuum_naptime;
-- Максимальное количество воркеров
show autovacuum_max_workers;

-- Размер фрагмента памяти для накопления идентификаторов версий при ручной очистке
show maintenance_work_mem;
-- При автоматической очистке
-- Если равен -1, используется значение maintenance_work_mem;
show autovacuum_work_mem;

-- Пороговое значение неактуальных (мёртвых) версий строк для запуска автоочистки
show autovacuum_vacuum_threshold;
show autovacuum_vacuum_scale_factor;

-- Пороговое значение изменённых с момента прошлого анализа строк для запуска анализа
show autovacuum_analyze_threshold;
show autovacuum_analyze_scale_factor;

-- Регулирование автоочистки
show vacuum_cost_limit;
show autovacuum_vacuum_cost_limit;
show autovacuum_vacuum_cost_delay;


-- 21.03.2024
-- Размер буферного кеша
SHOW shared_buffers;

-- Размер базы данных
SELECT pg_size_pretty(pg_database_size(current_database()));

-- Распределение буферов

-- DROP FUNCTION buffercache;
-- DROP EXTENSION pg_buffercache;

CREATE EXTENSION pg_buffercache;

CREATE FUNCTION buffercache(rel regclass)
RETURNS TABLE(
  bufferid INTEGER, relfork TEXT, relblk BIGINT,
  isdirty BOOLEAN, usagecount SMALLINT, pins INTEGER
) AS $$
SELECT bufferid,
  CASE relforknumber
    WHEN 0 THEN 'main'
    WHEN 1 THEN 'fsm'
    WHEN 2 THEN 'vm'
  END,
  relblocknumber,
  isdirty,
  usagecount,
  pinning_backends
FROM pg_buffercache
WHERE relfilenode = pg_relation_filenode(rel)
ORDER BY relforknumber, relblocknumber;
$$ LANGUAGE sql;

SELECT usagecount, count(*) FROM pg_buffercache
GROUP BY usagecount
ORDER BY usagecount;

SELECT c.relname,
  count(*) blocks,
  round ( 100.0 * 8192 * count(*) /
    pg_table_size(c.oid) ) AS "% of rel",
  round( 100.0 * 8192 * count(*) FILTER (WHERE b.usagecount > 1) /
    pg_table_size(c.oid) ) AS "% hot"
FROM pg_buffercache b
 JOIN pg_class c ON pg_relation_filenode(c.oid) =  b.relfilenode
WHERE b.reldatabase IN (
  0, -- общие объекты кластера
  (SELECT oid FROM pg_database WHERE datname = current_database())
)
AND b.usagecount IS NOT NULL
GROUP BY c.relname, c.oid
ORDER BY 2 DESC
LIMIT 250;

SELECT c.relname,
  count(*) blocks,
  round ( 100.0 * 8192 * count(*) /
    pg_table_size(c.oid) ) AS "% of rel",
  round( 100.0 * 8192 * count(*) FILTER (WHERE b.usagecount > 1) /
    pg_table_size(c.oid) ) AS "% hot"
FROM pg_buffercache b
 JOIN pg_class c ON pg_relation_filenode(c.oid) =  b.relfilenode
WHERE b.reldatabase IN (
  0, -- общие объекты кластера
  (SELECT oid FROM pg_database WHERE datname = current_database())
)
AND b.usagecount IS NOT NULL
GROUP BY c.relname, c.oid
ORDER BY 2 ASC
LIMIT 250;

-- Сканирование индексов
SELECT 
  schemaname || '.' || relname AS table,
  indexrelname AS index,
  pg_size_pretty(pg_relation_size(i.indexrelid)) AS index_size,
  idx_scan AS index_scans_count
FROM pg_stat_user_indexes ui
JOIN pg_index i ON ui.indexrelid = i.indexrelid
WHERE NOT indisunique AND pg_relation_size(relid) > 5 * 8192
ORDER BY pg_relation_size(i.indexrelid) / NULLIF(idx_scan, 0) DESC NULLS FIRST, pg_relation_size(i.indexrelid) DESC
LIMIT 250;

SELECT 
  schemaname || '.' || relname AS table,
  indexrelname AS index,
  pg_size_pretty(pg_relation_size(i.indexrelid)) AS index_size,
  idx_scan AS index_scans_count
FROM pg_stat_user_indexes ui
JOIN pg_index i ON ui.indexrelid = i.indexrelid
WHERE NOT indisunique AND pg_relation_size(relid) > 5 * 8192
ORDER BY pg_relation_size(i.indexrelid) / NULLIF(idx_scan, 0) DESC NULLS FIRST, pg_relation_size(i.indexrelid) ASC
LIMIT 250;

-- Необходимо ли делать analyze или vacuum
-- Создать функции из файла analyze.sql
SELECT * FROM ck_need_vacuum ORDER BY max_dead_tup DESC LIMIT 250; 
SELECT * FROM ck_need_vacuum ORDER BY last_autovacuum ASC LIMIT 250; 
SELECT * FROM ck_need_analyze ORDER BY max_dead_tup DESC LIMIT 250; 
SELECT * FROM ck_need_analyze ORDER BY last_autovacuum ASC LIMIT 250; 

