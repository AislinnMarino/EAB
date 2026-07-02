WITH
        ranked_terms
        AS
            (SELECT DENSE_RANK ()
                        OVER (
                            PARTITION BY A.INSTITUTION, A.EMPLID, A.STRM
                            ORDER BY
                                ---take a career equal to the billing career first
                                (CASE
                                     WHEN A.ACAD_CAREER = A.BILLING_CAREER
                                     THEN
                                         '1'
                                     ELSE
                                         '0'
                                 END) DESC,
                                ---next, take the career with the highest number of units taken for progress
                                A.UNT_TAKEN_PRGRSS DESC,
                                ---next, take a degree granting primary academic program over a non degree granting one
                                (CASE
                                     WHEN SUBSTR (A.ACAD_PROG_PRIMARY, 3, 1) <>
                                          'N'
                                     THEN
                                         '1'
                                     ELSE
                                         '0'
                                 END) DESC,
                                ---next, take UGRD
                                (CASE
                                     WHEN A.ACAD_CAREER = 'UGRD' THEN '1'
                                     ELSE '0'
                                 END) DESC,
                                ---next, assign lower rank to advanced certificates
                                (CASE
                                     WHEN SUBSTR (A.ACAD_PROG_PRIMARY, 4, 1) <>
                                          '7'
                                     THEN
                                         '1'
                                     ELSE
                                         '0'
                                 END) DESC,
                                ---order by program level
                                SUBSTR (A.ACAD_PROG_PRIMARY, 4, 1) DESC)
                        AS career_rank,
                    a.EMPLID,
                    a.STRM,
                    a.CUM_GPA,
                    a.SSR_COMB_CUR_GPA,
                    a.SSR_CUM_EN_GPA,
                    a.CUR_GPA,
                    a.SSR_TRF_CUR_GPA,
                    a.SSR_CUM_TR_GPA
               FROM ps_rpt.ps_stdnt_car_term a),
        stu_car_term_career_ranked
        AS
            (SELECT *
               FROM (SELECT emplid,
                            strm,
                            DENSE_RANK ()
                                OVER (PARTITION BY emplid, strm
                                      ORDER BY career_rank)    AS RANK,
                            CUM_GPA,
                            SSR_COMB_CUR_GPA,
                            SSR_CUM_EN_GPA,
                            CUR_GPA,
                            SSR_TRF_CUR_GPA,
                            SSR_CUM_TR_GPA
                       FROM ranked_terms)
              WHERE RANK = 1),
        max_term
        AS
            (  SELECT emplid, MAX (strm) AS strm
                 FROM stu_car_term_career_ranked
                WHERE strm <= (SELECT ub_term_value
                                 FROM ps_rpt.ps_ub_term_val_tbl_v
                                WHERE ub_term_descr = 'Current Term - UGRD')
             GROUP BY emplid
             UNION ALL
               SELECT emplid, MAX (strm)
                 FROM stu_car_term_career_ranked
                WHERE emplid NOT IN
                          (SELECT emplid
                            FROM stu_car_term_career_ranked
                           WHERE strm <=
                                 (SELECT ub_term_value
                                    FROM ps_rpt.ps_ub_term_val_tbl_v
                                   WHERE ub_term_descr = 'Current Term - UGRD'))
             GROUP BY emplid),
        primary_gpa
        AS
            (SELECT a.emplid,
                    b.strm,
                    'MAJOR_CML_GPA'     AS KEY,
                    a.GPA_ACTUAL        AS VALUE
               FROM PS_RPT.PS_UB_MJRGPA_PRI_U_V  a
                    JOIN stu_car_term_career_ranked b
                        ON     a.emplid = b.emplid
                           AND b.strm = (SELECT MAX (x.strm)
                                           FROM max_term x
                                          WHERE b.emplid = x.emplid)),
        last_completed_term_gpa
        AS
            (SELECT a.emplid,
                    b.strm,
                    'MAJOR_CML_GPA'     AS KEY,
                    a.GPA_ACTUAL        AS VALUE
               FROM PS_RPT.PS_UB_MJRGPA_PRI_U_V  a
                    JOIN stu_car_term_career_ranked b
                        ON     a.emplid = b.emplid
                           AND b.strm = (SELECT ub_term_value
                                    FROM ps_rpt.ps_ub_term_val_tbl_v
                                   WHERE ub_term_descr = 'Previous Regular - UGRD'))
        SELECT a.EMPLID       AS STUDENT_ID,
               a.STRM         AS TERM_ID,
               a.GPA_TYPE     AS KEY,
               a.MY_GPA       AS VALUE
          FROM stu_car_term_career_ranked
                   UNPIVOT (my_gpa
                       FOR gpa_type
                       IN (CUM_GPA AS 'OVERALL_CML_GPA',
                           SSR_COMB_CUR_GPA AS 'OVERALL_TERM_GPA',
                           SSR_CUM_EN_GPA AS 'INST_CML_GPA',
                           CUR_GPA AS 'INST_TERM_GPA',
                           SSR_TRF_CUR_GPA AS 'TRANS_TERM_GPA',
                           SSR_CUM_TR_GPA AS 'TRANS_CUM_GPA')) a
        UNION ALL
        SELECT "EMPLID",
               "STRM",
               "KEY",
               "VALUE"
          FROM primary_gpa
         UNION ALL
                 SELECT "EMPLID",
               "STRM",
               "KEY",
               "VALUE"
          FROM last_completed_term_gpa
         WHERE 1 = 1