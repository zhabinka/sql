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

select * from ck_need_vacuum; 
select * from ck_need_analyze; 
