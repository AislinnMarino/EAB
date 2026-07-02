SELECT p.emplid AS "EMPLID", p.strm AS "STRM"
      FROM ps_rpt.CMP_population_mv p
     WHERE p.strm >= (SELECT cf.lookback_term
                        FROM ps_rpt.cmp_filter_current_v cf)