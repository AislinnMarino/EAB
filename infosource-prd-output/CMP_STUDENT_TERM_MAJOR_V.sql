WITH
        ranked_in_career
        AS
            (  SELECT /*+ OPTIMIZER_FEATURES_ENABLE('11.2.0.4') */
                      mg.student_id,
                      mg.effective_date,
                      mg.seq,
                      mg.college_cd,
                      mg.major_cd,
                      mg.concentration_cd,
                      mg.degree_cd,
                      mg.STDNT_CAR_NBR,
                      mg.BACCALAUREATE,
                      mg.prog_status,
                      mg.acad_career,
                      mg.PLAN_SEQUENCE,
                      MAX (new_rank)     AS new_rank,
                      mg.strm
                 FROM (  SELECT DISTINCT
                                majors.EMPLID
                                    AS STUDENT_ID,
                                TO_CHAR (MAJORS.EFFDT, 'yyyymmdd')
                                    AS EFFECTIVE_DATE,
                                majors.seq
                                    AS SEQ,
                                majors.acad_group
                                    AS COLLEGE_CD,
                                MAJORS.ACAD_PLAN
                                    AS MAJOR_CD,
                                NVL (majors.acad_sub_plan, '')
                                    AS CONCENTRATION_CD,
                                degree.degree
                                    AS DEGREE_CD,
                                majors.STDNT_CAR_NBR,
                                ' '
                                    AS BACCALAUREATE,
                                majors.prog_status,
                                MAJORS.ACAD_CAREER,
                                majors.plan_sequence,
                                majors.new_rank,
                                MAJORS.STRM
                           FROM (                                      --MAJOR
                                 SELECT *
                                   FROM ps_rpt.CMP_STU_TERM_MAJOR_MV m) MAJORS
                                --get degree
                                LEFT JOIN
                                (SELECT DISTINCT
                                        pt1.acad_plan,
                                        base_plan.base,
                                        base_plan.degree
                                   FROM ps_rpt.ps_acad_plan_tbl pt1
                                        JOIN
                                        (SELECT DISTINCT
                                                SUBSTR (pt2.acad_plan, 1, 8)
                                                    AS base,
                                                pt2.degree
                                           FROM ps_rpt.ps_acad_plan_tbl pt2
                                          WHERE NVL (
                                                    SUBSTR (pt2.acad_plan, 9, 1),
                                                    ' ') IN
                                                    ('A', ' ')) base_plan
                                            ON base_plan.base =
                                               SUBSTR (pt1.acad_plan, 1, 8)
                                  WHERE     pt1.effdt =
                                            (SELECT MAX (pt3.effdt)
                                              FROM ps_rpt.ps_acad_plan_tbl pt3
                                             WHERE     pt1.acad_plan =
                                                       pt3.acad_plan
                                                   AND PT3.DEGREE NOT IN
                                                           ('CERT', 'CAS'))
                                        AND PT1.DEGREE NOT IN ('CERT', 'CAS'))
                                degree
                                    ON majors.acad_plan = degree.acad_plan
                          WHERE majors.emplid IN
                                    (SELECT cp.emplid
                                       FROM ps_rpt.cmp_population_current_v cp)
                       ORDER BY majors.emplid,
                                majors.new_rank,
                                EFFECTIVE_DATE,
                                majors.stdnt_car_nbr DESC,
                                majors.plan_sequence DESC) mg
             GROUP BY mg.student_id,
                      mg.effective_date,
                      mg.seq,
                      mg.college_cd,
                      mg.major_cd,
                      mg.concentration_cd,
                      mg.degree_cd,
                      mg.STDNT_CAR_NBR,
                      mg.BACCALAUREATE,
                      mg.prog_status,
                      mg.acad_career,
                      mg.PLAN_SEQUENCE,
                      mg.strm),
        plan_with_term
        AS
            ( -- get associated term matched up with the ranking for each effdt and major
             SELECT eff.student_id,
                    eff.effective_date,
                    eff.seq,
                    eff.college_cd,
                    eff.major_cd,
                    eff.concentration_cd,
                    eff.degree_cd,
                    eff.stdnt_car_nbr,
                    eff.baccalaureate,
                    eff.prog_status,
                    eff.acad_career,
                    eff.plan_sequence,
                    eff.new_rank,
                    NVL (eff.strm, '0000')     strm
               FROM ranked_in_career eff
              WHERE eff.new_rank =
                    (SELECT MAX (eff2.new_rank)
                      FROM ranked_in_career eff2
                     WHERE     eff2.student_id = eff.student_id
                           AND eff2.effective_date = eff.effective_date
                           AND eff2.major_cd = eff.major_cd
                           AND eff2.acad_career = eff.acad_career
                           AND eff2.stdnt_car_nbr = eff.stdnt_car_nbr)),
        plan_without_term
        AS
            (SELECT DISTINCT pwt.student_id,
                             pwt.effective_date,
                             pwt.seq,
                             pwt.college_cd,
                             pwt.major_cd,
                             pwt.concentration_cd,
                             pwt.degree_cd,
                             pwt.stdnt_car_nbr,
                             pwt.baccalaureate,
                             pwt.prog_status,
                             pwt.acad_career,
                             pwt.plan_sequence,
                             pwt.new_rank
               FROM plan_with_term pwt),
        all_plans_with_term
        AS
            (    -- get each plan and last effective date to report in the end
             SELECT ap.*
               FROM plan_with_term ap
              WHERE ap.effective_date =
                    (SELECT MAX (ap2.effective_date)
                      FROM plan_with_term ap2
                     WHERE     1 = 1
                           AND ap2.student_id = ap.student_id
                           AND ap2.acad_career = ap.acad_career
                           AND ap2.stdnt_car_nbr = ap.stdnt_car_nbr
                           AND ap2.major_cd = ap.major_cd
                           AND ap2.strm = ap.strm)),
        plan_history
        AS
            (    -- get each plan and last effective date to report in the end
             SELECT *
               FROM all_plans_with_term apt
              WHERE apt.strm =
                    (SELECT MAX (ap3.strm)
                      FROM all_plans_with_term ap3
                     WHERE     1 = 1
                           AND ap3.student_id = apt.student_id
                           AND ap3.acad_career = apt.acad_career
                           AND ap3.stdnt_car_nbr = apt.stdnt_car_nbr
                           AND ap3.major_cd = apt.major_cd)),
        top_careers
        AS
            ( -- get latest effective date for each career and associated term
               SELECT rc.*
                 FROM plan_history rc
                WHERE rc.effective_date =
                      (SELECT MAX (rc2.effective_date) -- this is the last date for this plan to see if it was DC and to look at another acad_career row
                        FROM plan_with_term rc2
                       WHERE     1 = 1
                             AND rc2.student_id = rc.student_id
                             AND rc2.acad_career = rc.acad_career
                             AND rc2.stdnt_car_nbr = rc.stdnt_car_nbr)
             ORDER BY rc.acad_career, rc.effective_date DESC),
        plans_with_latest_eff_date
        AS
            ( -- get latest effective date for each career and associated term
             SELECT *
               FROM top_careers tc
              WHERE tc.strm =
                    (SELECT MAX (tc2.strm)
                      FROM top_careers tc2
                     WHERE     tc2.student_id = tc.student_id
                           AND tc2.major_cd = tc.major_cd)),
        top_ranked_record
        AS
            ( -- get the records with the latest term (could be multiple - this is why you need the rank)
               SELECT rpc.*
                 FROM plans_with_latest_eff_date rpc
             ORDER BY rpc.strm DESC),
        top_selected_record
        AS
            (                                -- now grab the top ranked record
             SELECT trr.*
               FROM top_ranked_record trr
              WHERE trr.new_rank = (SELECT MAX (trr2.new_rank)
                                      FROM top_ranked_record trr2
                                     WHERE trr2.student_id = trr.student_id)),
        final_top_record
        AS
            ( -- if multiple for one career then get top car_nbr for this career
             SELECT tsr.*,
                    (tsr.new_rank || tsr.effective_date)    AS prog_status_rank
               FROM top_selected_record tsr
              WHERE tsr.stdnt_car_nbr =
                    (SELECT MAX (tsr2.stdnt_car_nbr)
                      FROM top_selected_record tsr2
                     WHERE     tsr2.student_id = tsr.student_id
                           AND tsr.strm = tsr2.strm)),
        majors_with_rank
        AS                 -- now update the eventual maxrno for sorting later
            (  SELECT DISTINCT
                      rc.*,
                      NVL (rr.prog_status_rank, '00000000000')    prog_status_rank
                 FROM plan_without_term rc
                      LEFT OUTER JOIN final_top_record rr
                          ON     rc.student_id = rr.student_id
                             AND rc.effective_date = rr.effective_date
                             AND rc.acad_career = rr.acad_career
             ORDER BY rc.student_id,
                      NVL (rr.prog_status_rank, '00000000000') DESC)
      SELECT student_id,
             EFFECTIVE_DATE,
             DECODE (REGEXP_SUBSTR (COLLEGE_CD,
                                    '[^|]+',
                                    1,
                                    1),
                     ' ', NULL,
                     REGEXP_SUBSTR (COLLEGE_CD,
                                    '[^|]+',
                                    1,
                                    1))    COLLEGE_1,
             DECODE (REGEXP_SUBSTR (MAJOR_cd,
                                    '[^|]+',
                                    1,
                                    1),
                     ' ', NULL,
                     REGEXP_SUBSTR (MAJOR_cd,
                                    '[^|]+',
                                    1,
                                    1))    MAJOR_1,
             DECODE (REGEXP_SUBSTR (DEGREE_CD,
                                    '[^|]+',
                                    1,
                                    1),
                     ' ', NULL,
                     REGEXP_SUBSTR (DEGREE_CD,
                                    '[^|]+',
                                    1,
                                    1))    DEGREE_1,
             DECODE (REGEXP_SUBSTR (CONCENTRATION_cd,
                                    '[^|]+',
                                    1,
                                    1),
                     ' ', NULL,
                     REGEXP_SUBSTR (CONCENTRATION_cd,
                                    '[^|]+',
                                    1,
                                    1))    CONCENTRATION_1,
             DECODE (REGEXP_SUBSTR (COLLEGE_CD,
                                    '[^|]+',
                                    1,
                                    2),
                     ' ', NULL,
                     REGEXP_SUBSTR (COLLEGE_CD,
                                    '[^|]+',
                                    1,
                                    2))    COLLEGE_2,
             DECODE (REGEXP_SUBSTR (MAJOR_cd,
                                    '[^|]+',
                                    1,
                                    2),
                     ' ', NULL,
                     REGEXP_SUBSTR (MAJOR_cd,
                                    '[^|]+',
                                    1,
                                    2))    MAJOR_2,
             DECODE (REGEXP_SUBSTR (DEGREE_CD,
                                    '[^|]+',
                                    1,
                                    2),
                     ' ', NULL,
                     REGEXP_SUBSTR (DEGREE_CD,
                                    '[^|]+',
                                    1,
                                    2))    DEGREE_2,
             DECODE (REGEXP_SUBSTR (CONCENTRATION_cd,
                                    '[^|]+',
                                    1,
                                    2),
                     ' ', NULL,
                     REGEXP_SUBSTR (CONCENTRATION_cd,
                                    '[^|]+',
                                    1,
                                    2))    CONCENTRATION_2,
             DECODE (REGEXP_SUBSTR (COLLEGE_CD,
                                    '[^|]+',
                                    1,
                                    3),
                     ' ', NULL,
                     REGEXP_SUBSTR (COLLEGE_CD,
                                    '[^|]+',
                                    1,
                                    3))    COLLEGE_3,
             DECODE (REGEXP_SUBSTR (MAJOR_cd,
                                    '[^|]+',
                                    1,
                                    3),
                     ' ', NULL,
                     REGEXP_SUBSTR (MAJOR_cd,
                                    '[^|]+',
                                    1,
                                    3))    MAJOR_3,
             DECODE (REGEXP_SUBSTR (DEGREE_CD,
                                    '[^|]+',
                                    1,
                                    3),
                     ' ', NULL,
                     REGEXP_SUBSTR (DEGREE_CD,
                                    '[^|]+',
                                    1,
                                    3))    DEGREE_3,
             DECODE (REGEXP_SUBSTR (CONCENTRATION_cd,
                                    '[^|]+',
                                    1,
                                    3),
                     ' ', NULL,
                     REGEXP_SUBSTR (CONCENTRATION_cd,
                                    '[^|]+',
                                    1,
                                    3))    CONCENTRATION_3,
             DECODE (REGEXP_SUBSTR (COLLEGE_CD,
                                    '[^|]+',
                                    1,
                                    4),
                     ' ', NULL,
                     REGEXP_SUBSTR (COLLEGE_CD,
                                    '[^|]+',
                                    1,
                                    4))    COLLEGE_4,
             DECODE (REGEXP_SUBSTR (MAJOR_cd,
                                    '[^|]+',
                                    1,
                                    4),
                     ' ', NULL,
                     REGEXP_SUBSTR (MAJOR_cd,
                                    '[^|]+',
                                    1,
                                    4))    MAJOR_4,
             DECODE (REGEXP_SUBSTR (DEGREE_CD,
                                    '[^|]+',
                                    1,
                                    4),
                     ' ', NULL,
                     REGEXP_SUBSTR (DEGREE_CD,
                                    '[^|]+',
                                    1,
                                    4))    DEGREE_4,
             DECODE (REGEXP_SUBSTR (CONCENTRATION_cd,
                                    '[^|]+',
                                    1,
                                    4),
                     ' ', NULL,
                     REGEXP_SUBSTR (CONCENTRATION_cd,
                                    '[^|]+',
                                    1,
                                    4))    CONCENTRATION_4,
             maxrno
        FROM (  SELECT student_id,
                       effective_date,
                       LISTAGG (NVL (COLLEGE_CD, ' '), '|')
                           WITHIN GROUP (ORDER BY seq)    COLLEGE_CD,
                       LISTAGG (NVL (MAJOR_CD, ' '), '|')
                           WITHIN GROUP (ORDER BY seq)    major_cd,
                       LISTAGG (NVL (DEGREE_CD, ' '), '|')
                           WITHIN GROUP (ORDER BY seq)    DEGREE_CD,
                       LISTAGG (NVL (CONCENTRATION_CD, ' '), '|')
                           WITHIN GROUP (ORDER BY seq)    CONCENTRATION_CD,
                       MAX (prog_status_rank)             maxrno
                  FROM majors_with_rank
              GROUP BY student_id, effective_date
              ORDER BY student_id, effective_date)
    ORDER BY student_id, maxrno