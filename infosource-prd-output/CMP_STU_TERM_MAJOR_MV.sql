SELECT DISTINCT
       eff.emplid,
       eff.acad_career,
       eff.effdt,
       eff.effseq,
       pr.acad_prog,
       pl.acad_plan,
       pr.stdnt_car_nbr,
       pr.prog_action,
       pl.plan_sequence,
       prt.acad_group,
       sp.acad_sub_plan,
       DENSE_RANK ()
       OVER (PARTITION BY eff.emplid, eff.acad_career, eff.effdt
             ORDER BY pr.stdnt_car_nbr, pl.plan_sequence)
          seq,
       pr.prog_status,
       (   CASE
              WHEN pr.prog_status = 'AC' THEN '9'
              WHEN pr.prog_status = 'LA' THEN '3'
              WHEN pr.prog_status = 'CM' THEN '2'
              WHEN pr.prog_status = 'DC' THEN '1'
              ELSE '0'
           END                                              --prog_status_rank
        || CASE
              WHEN carterm.billing_career = carterm.acad_career THEN '1'
              ELSE '0'
           END                                        --as billing_career_rank
        || CASE
              WHEN carterm.acad_prog_primary = pr.acad_prog THEN '1'
              ELSE '0'
           END                                                  --as prog_rank
              )
          AS new_rank,
       carterm.strm
  FROM (SELECT DISTINCT emplid,
                        acad_career,
                        effdt,
                        effseq
          FROM ps_rpt.ps_acad_prog) eff
       JOIN ps_rpt.ps_acad_prog pr
          ON     eff.emplid = pr.emplid
             AND eff.acad_career = pr.acad_career
             AND eff.effdt = pr.effdt --  gfs added to fix EEH not being own line
       JOIN ps_rpt.ps_acad_prog_tbl prt -- need to join to acad_prog_tbl to get group
          ON     pr.acad_prog = prt.acad_prog
             AND PRT.EFFDT = (SELECT MAX (prt2.effdt)
                                FROM PS_RPT.PS_ACAD_PROG_TBL PRT2
                               WHERE prt.acad_prog = prt2.acad_prog)
       JOIN ps_rpt.ps_acad_plan pl
          ON     pr.emplid = pl.emplid
             AND pr.acad_career = pl.acad_career
             AND pr.stdnt_car_nbr = pl.stdnt_car_nbr
             AND pr.effdt = pl.effdt
             AND pr.effseq = pl.effseq
       JOIN ps_rpt.ps_acad_plan_tbl plt -- need to join to acad_plan_tbl to remove minors
          ON     plt.acad_plan = pl.acad_plan
             AND plt.ACAD_PLAN_type <> 'MIN'                         -- minors
             AND plt.EFFDT = (SELECT MAX (plt2.effdt)
                                FROM PS_RPT.PS_ACAD_PLAN_TBL PLT2
                               WHERE plt.acad_plan = plt2.acad_plan)
       LEFT JOIN ps_rpt.ps_acad_subplan sp
          ON     pl.emplid = sp.emplid
             AND pl.acad_career = sp.acad_career
             AND pl.stdnt_car_nbr = sp.stdnt_car_nbr
             AND pl.acad_plan = sp.acad_plan
             AND pl.effdt = sp.effdt
             AND pl.effseq = sp.effseq
       JOIN PS_RPT.PS_UB_TERM_VAL_TBL_V termval
          ON termval.ub_term_descr = 'Next Fall Term - UGRD'  
       LEFT JOIN ps_rpt.ps_stdnt_car_term carterm
          ON     pl.emplid = carterm.emplid
             AND pl.acad_career = carterm.acad_career
             AND pl.stdnt_car_nbr = carterm.stdnt_car_nbr
 WHERE     1 = 1
       AND (carterm.strm <= termval.strm OR carterm.strm IS NULL)
       AND pr.effdt =
              (SELECT MAX (pr_ed.effdt)
                 FROM ps_rpt.ps_acad_prog pr_ed
                WHERE     pr_ed.emplid = pr.emplid
                      AND pr_ed.acad_career = pr.acad_career
                      AND pr_ed.stdnt_car_nbr = pr.stdnt_car_nbr
                      AND pr_ed.effdt <= eff.effdt)
       AND pr.effseq =
              (SELECT MAX (pr_es.effseq)
                 FROM ps_rpt.ps_acad_prog pr_es
                WHERE     pr_es.emplid = pr.emplid
                      AND pr_es.acad_career = pr.acad_career
                      AND pr_es.stdnt_car_nbr = pr.stdnt_car_nbr
                      AND pr_es.effdt = pr.effdt)
       AND pr.prog_status IN ('AC',
                              'LA',
                              'CM',
                              'DC')