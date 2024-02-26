-- drop function ck_p; drop view ck_need_vacuum; drop view ck_need_analyze;
CREATE FUNCTION ck_p(param text, c pg_class) RETURNS float
AS $$
SELECT coalesce(
    -- если параметр хранения задан, то берём его
    (SELECT option_value
     FROM   pg_options_to_table(c.reloptions)
     WHERE  option_name = CASE
              -- для toast-таблиц имя параметра отличается
              WHEN c.relkind = 't' THEN 'toast.' ELSE ''
            END || param
    ),
  -- иначе берём значение конфигурационного параметра
  current_setting(param)
  )::float;
$$ LANGUAGE sql;

CREATE VIEW ck_need_vacuum AS
WITH c AS (
  SELECT c.oid,
    greatest(c.reltuples, 0) reltuples,
    ck_p('autovacuum_vacuum_threshold', c) threshold,
    ck_p('autovacuum_vacuum_scale_factor', c) scale_factor
    -- p('autovacuum_vacuum_insert_threshold', c) ins_threshold,
    -- p('autovacuum_vacuum_insert_scale_factor', c) ins_scale_factor
  FROM pg_class c
  WHERE c.relkind IN ('r', 'm', 't')
)
SELECT st.schemaname || '.' || st.relname AS tablename,
  st.n_dead_tup AS dead_tup,
  c.threshold + c.scale_factor * c.reltuples AS max_dead_tup,
  -- st.n_ins_since_vacuum AS ins_tup,
  -- c.ins_threshold + c.ins_scale_factor * c.reltuples AS mix_ins_tup,
  st.last_autovacuum
FROM pg_stat_all_tables st
  JOIN c ON c.oid = st.relid;

CREATE VIEW ck_need_analyze AS
WITH c AS (
  SELECT c.oid,
    greatest(c.reltuples, 0) reltuples,
    ck_p('autovacuum_analyze_threshold', c) threshold,
    ck_p('autovacuum_analyze_scale_factor', c) scale_factor
  FROM pg_class c
  WHERE c.relkind IN ('r', 'm')
)
SELECT st.schemaname || '.' || st.relname AS tablename,
  st.n_mod_since_analyze AS mod_tup,
  c.threshold + c.scale_factor * c.reltuples AS mox_mod_tup,
  st.last_autoanalyze
FROM pg_stat_all_tables st
  JOIN c ON c.oid = st.relid;

