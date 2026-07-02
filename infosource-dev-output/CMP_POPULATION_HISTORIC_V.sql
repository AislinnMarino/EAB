SELECT p.emplid AS "EMPLID", p.strm AS "STRM"
      FROM ps_rpt.CMP_population_mv p
     WHERE p.strm >= (SELECT hf.lookback_term
                        FROM ps_rpt.cmp_filter_historic_v hf)