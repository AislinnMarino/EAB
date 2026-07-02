SELECT a.EMPLID, MAX (a.STRM) AS STRM
       FROM ps_rpt.PS_STDNT_CAR_TERM a
      WHERE a.EMPLID NOT IN (SELECT i.emplid
                               FROM PS_RPT.ps_srvc_ind_data_v i
                              WHERE i.srvc_ind_cd = 'DUP')
   GROUP BY a.EMPLID