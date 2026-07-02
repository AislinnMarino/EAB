SELECT CAMPUS AS CAMPUS_CD, DESCR AS CAMPUS_DESC
     FROM ps_rpt.PS_CAMPUS_TBL a
    WHERE     1 = 1
          AND a.EFFDT =
                 (SELECT MAX (EFFDT)
                    FROM ps_rpt.PS_CAMPUS_TBL
                   WHERE INSTITUTION = a.INSTITUTION AND DESCR = a.DESCR)