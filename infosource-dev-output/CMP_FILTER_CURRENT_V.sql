SELECT MIN (tt.strm) AS lookback_term
      FROM ps_rpt.ps_term_tbl tt
     WHERE tt.term_end_dt >= SYSDATE - 365