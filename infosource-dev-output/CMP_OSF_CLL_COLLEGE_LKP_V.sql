SELECT DISTINCT a.ACAD_GROUP AS COLLEGE_CD, a.DESCR AS COLLEGE_DESC
       FROM ps_rpt.PS_ACAD_GROUP_TBL a
      WHERE     1 = 1
            --  AND a.ACAD_CAREER IN ('UGRD')
            AND a.EFFDT = (SELECT MAX (EFFDT)
                             FROM ps_rpt.PS_ACAD_GROUP_TBL b
                            WHERE b.ACAD_GROUP = a.ACAD_GROUP)
   ORDER BY 1