SELECT tv.ub_term_value - 110 AS lookback_term
      FROM ps_rpt.ps_ub_term_val_tbl tv
     WHERE tv.ub_term_descr = 'Current/Upcoming Regular - UGRD'