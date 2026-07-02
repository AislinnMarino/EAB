SELECT pr.EMPLID AS STUDENT_ID,
          plt.DESCR AS MINOR_DESCRIPTION,
          ' ' AS RANK_NO
     FROM ps_rpt.ps_acad_prog pr
          JOIN ps_rpt.ps_acad_plan pl
             ON     pr.emplid = pl.emplid
                AND pr.acad_career = pl.acad_career
                AND pr.stdnt_car_nbr = pl.stdnt_car_nbr
                AND pr.effdt = pl.effdt
                AND pr.effseq = pl.effseq
          JOIN ps_rpt.ps_acad_plan_tbl plt -- join to acad_plan_tbl to get minors
             ON     plt.acad_plan = pl.acad_plan
                AND plt.ACAD_PLAN_type = 'MIN'                       -- minors
                AND plt.EFFDT = (SELECT MAX (plt2.effdt)
                                   FROM PS_RPT.PS_ACAD_PLAN_TBL PLT2
                                  WHERE plt.acad_plan = plt2.acad_plan)
    WHERE     pr.effdt =
                 (SELECT MAX (pr_ed.effdt)
                    FROM ps_rpt.ps_acad_prog pr_ed
                   WHERE     pr_ed.emplid = pr.emplid
                         AND pr_ed.acad_career = pr.acad_career
                         AND pr_ed.stdnt_car_nbr = pr.stdnt_car_nbr)
          AND pr.effseq =
                 (SELECT MAX (pr_es.effseq)
                    FROM ps_rpt.ps_acad_prog pr_es
                   WHERE     pr_es.emplid = pr.emplid
                         AND pr_es.acad_career = pr.acad_career
                         AND pr_es.stdnt_car_nbr = pr.stdnt_car_nbr
                         AND pr_es.effdt = pr.effdt)
          AND pr.prog_status = 'AC'