(SELECT DISTINCT
           a.ACAD_STNDNG_ACTN AS ACADEMIC_STANDING_CODE,
           a.DESCR AS ACADEMIC_STANDING_DESC
      FROM ps_rpt.PS_ACAD_STACTN_TBL a
     WHERE     1 = 1
           AND a.EFFDT = (SELECT MAX (EFFDT)
                            FROM ps_rpt.PS_ACAD_STACTN_TBL
                           WHERE ACAD_STNDNG_ACTN = a.ACAD_STNDNG_ACTN)
						 union all
                           select 'UNKN', 'Unknown' from dual)