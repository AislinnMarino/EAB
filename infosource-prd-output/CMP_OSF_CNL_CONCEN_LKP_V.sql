SELECT a.ACAD_SUB_PLAN AS CONCENTRATION_CD, a.DESCR AS CONCENTRATION_DESC
       FROM ps_rpt.PS_ACAD_SUBPLN_TBL a
      WHERE     1 = 1
            AND a.EFFDT = (SELECT MAX (aa.EFFDT)
                             FROM ps_rpt.PS_ACAD_SUBPLN_TBL aa
                            WHERE aa.ACAD_SUB_PLAN = a.ACAD_SUB_PLAN)
   ORDER BY 1