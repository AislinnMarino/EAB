SELECT DISTINCT a.CRSE_GRADE_INPUT AS GRADE_CD, a.DESCR AS GRADE_DESC
     FROM ps_rpt.PS_GRADE_TBL a
          JOIN ps_rpt.PS_TERM_TBL dates ON dates.TERM_BEGIN_DT >= a.EFFDT
    WHERE     1 = 1
          AND a.DESCR = (SELECT MAX (DESCR)
                           FROM ps_rpt.PS_GRADE_TBL
                          WHERE a.CRSE_GRADE_INPUT = CRSE_GRADE_INPUT)