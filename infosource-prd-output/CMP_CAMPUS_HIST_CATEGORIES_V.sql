WITH NA
        AS (SELECT a.emplid, a.stdnt_group, t.strm
              FROM (SELECT a.*,
                           LEAD (
                              effdt,
                              1,
                              TO_DATE ('99991231', 'YYYYMMDD'))
                           OVER (
                              PARTITION BY emplid, institution, stdnt_group
                              ORDER BY
                                 emplid,
                                 institution,
                                 stdnt_group,
                                 effdt)
                              AS end_dt
                      FROM ps_rpt.ps_stdnt_grps_hist_v a) a
                   INNER JOIN ps_rpt.ps_stdnt_group_tbl g
                      ON     a.stdnt_group = g.stdnt_group
                         AND a.institution = g.institution
                   INNER JOIN ps_rpt.cmp_population_HISTORIC_v population
                      ON a.EMPLID = population.EMPLID
                   INNER JOIN ps_rpt.ps_term_tbl_v t
                      ON t.strm BETWEEN (population.strm - 110)
                                    AND population.strm
             WHERE     a.institution = 'UBFLO'
                   AND a.eff_status = 'A'
                   AND t.acad_career = 'UGRD'
                   AND a.end_dt > t.term_begin_dt
                   AND a.effdt <= t.term_end_dt
                   AND a.stdnt_group = 'ATNO')
   SELECT DISTINCT AL."Student Id",
                   AL."Term Id Effective",
                   AL."Term Effective Start Date",
                   AL."Term Id",
                   AL."Term Start Date",
                   AL."Term End Date",
                   AL."Category ID",
                   AL."Category Name"
     FROM (SELECT a.emplid "Student Id",
                  FIRST_VALUE (
                     t.strm)
                  OVER (PARTITION BY a.emplid, a.stdnt_group
                        ORDER BY t.strm
                        ROWS UNBOUNDED PRECEDING)
                     "Term Id Effective",
                  FIRST_VALUE (
                     a.effdt)
                  OVER (PARTITION BY a.emplid, a.stdnt_group
                        ORDER BY a.effdt
                        ROWS UNBOUNDED PRECEDING)
                     "Term Effective Start Date",
                  a.stdnt_group "Category ID",
                  a.effdt,
                  a.end_dt,
                  t.strm "Term Id",
                  t.term_begin_dt "Term Start Date",
                  t.term_end_dt "Term End Date",
                  CASE
                     WHEN a.stdnt_group = 'EOP' THEN 'EOP Student'
                     ELSE g.descr
                  END
                     "Category Name"
             FROM (SELECT a.emplid,
                          a.institution,
                          CASE
                             WHEN a.stdnt_group = 'EOPS' THEN 'EOP'
                             ELSE a.stdnt_group
                          END
                             stdnt_group,
                          a.effdt,
                          a.eff_status,
                          LEAD (
                             a.effdt,
                             1,
                             TO_DATE ('99991231', 'YYYYMMDD'))
                          OVER (
                             PARTITION BY a.emplid,
                                          a.institution,
                                          CASE
                                             WHEN a.stdnt_group = 'EOPS'
                                             THEN
                                                'EOP'
                                             ELSE
                                                a.stdnt_group
                                          END
                             ORDER BY a.effdt)
                             end_dt
                     FROM ps_rpt.ps_stdnt_grps_hist_v a) a
                  INNER JOIN ps_rpt.ps_stdnt_group_tbl g
                     ON     a.stdnt_group = g.stdnt_group
                        AND a.institution = g.institution
                  INNER JOIN ps_rpt.cmp_population_HISTORIC_v population
                     ON a.EMPLID = population.EMPLID
                  INNER JOIN ps_rpt.ps_term_tbl_v t
                     ON t.strm BETWEEN (population.strm - 110)
                                   AND population.strm
            WHERE     a.institution = 'UBFLO'
                  AND a.eff_status = 'A'
                  AND t.acad_career = 'UGRD'
                  AND a.end_dt > t.term_begin_dt
                  AND a.effdt <= t.term_end_dt
                  AND a.stdnt_group IN ('ACE',
                                        'ACKR',
                                        'ALLC',
                                        'ATBM',
                                        'ATBW',
                                        'ATC',
                                        'ATE',
                                        'ATF',
                                        'ATHL',
                                        'ATKM',
                                        'ATKW',
                                        'ATMM',
                                        'ATMW',
                                        'ATNO',
                                        'ATRM',
                                        'ATRW',
                                        'ATS',
                                        'ATV',
                                        'ATW',
                                        'ATXM',
                                        'ATXW',
                                        'ATYM',
                                        'ATYW',
                                        'CSTP',
                                        'EOP',
                                        'EOPS',
                                        'FIF',
                                        'GSP',
                                        'HON',
                                        'HONA',
                                        'HONP',
                                        'HONR',
                                        'LSAM',
                                        'MCNA',
                                        'NUR2',
                                        'PHG',
                                        'PPHM',
                                        'SSP',
                                        'SSS',
                                        'SYB',
                                        'SYS',
                                        '1EAS',
                                        '1FSH')) AL
          LEFT JOIN NA
             ON     NA.emplid = AL."Student Id"
                AND NA.strm = AL."Term Id"
                AND AL."Category ID" = 'ATHL'
    WHERE NA.EMPLID IS NULL