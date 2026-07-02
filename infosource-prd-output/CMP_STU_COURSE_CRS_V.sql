WITH crse_id_999tr
        AS (SELECT DISTINCT crse_id
              FROM ps_rpt.ps_crse_offer d
             WHERE d.catalog_nbr LIKE '%999%'),
        trans_and_class
        AS (SELECT a.EMPLID AS STUDENT_ID,
                   a.ARTICULATION_TERM AS TERM_ID,
                   'TRANSFER' AS CAMPUS_CD,
                   'TRANSFER' AS COLLEGE_CD,
                   NVL (transConvert.ACAD_ORG, '') AS DEPARTMENT_CD,
                   a.INCLUDE_IN_GPA AS GPA_INCLUDE_IND,
                   a.UNT_TAKEN AS COURSE_CREDITS,
                      TRIM (BOTH ' ' FROM transConvert.subject)
                   || ' '
                   || CASE
                         WHEN transConvert.catalog_nbr LIKE '%999%'
                         THEN
                            TRIM (BOTH ' ' FROM transConvert.catalog_nbr)
                         ELSE
                            REGEXP_SUBSTR (transConvert.catalog_nbr, '\d+')
                      END
                      AS course_cd,
                   COALESCE (
                         a.ARTICULATION_TERM
                      || a.TRNSFR_EQVLNCY_GRP
                      || a.TRNSFR_EQVLNCY_SEQ,
                      TRIM (' ' FROM transConvert.CRSE_ID))
                      AS COURSE_REF_NO,
                   'Y' AS REGISTERED_IND,
                   'E' AS REGISTRATION_STATUS_CD,
                   '' AS REGISTRATION_STATUS_DT,
                   a.UNT_TAKEN AS ATTEMPTED_CREDITS,
                   CASE
                      WHEN (    a.EARN_CREDIT = 'Y'
                            AND (a.REPEAT_CODE = '' OR a.REPEAT_CODE = ' '))
                      THEN
                         a.UNT_TRNSFR
                      ELSE
                         0
                   END
                      AS EARNED_CREDITS,
                   '' AS FIELD16,
                   school.DESCR50 AS TRANSFERRING_INST,
                   CASE WHEN a.GRADE_CATEGORY = 'NONE' THEN 'N' ELSE 'Y' END
                      AS GRADABLE_IND,
                   '' AS MIDTERM_GRADE,
                   NVL (a.CRSE_GRADE_OFF, ' ') AS FINAL_GRADE,
                   '' AS FINAL_GRADE_DT,
                   'Y' AS FINAL_GRADE_OFFICIAL_IND,
                   0 AS GRADE_POINTS,
                   'N' AS INST_COURSE_IND,
                   'Y' AS TRANSFER_COURSE_IND,
                   'N' AS IN_PROGRESS_IND,
                   transConvert.ssr_component AS course_type_cd,
                   a.ACAD_CAREER AS STUDENT_LEVEL_CD,
                   '' AS FIELD29,
                   '' AS INSTRUCTION_METHOD,
                   '' AS FIELD31,
                   '' AS SECTION_START_DT,
                   '' AS SECTION_END_DT,
                   0 AS ENROLLMENT_MAX,
                   0 AS ENROLLMENT_CURRENT,
                   '' AS ENROLLMENT_CENSUS_DT,
                   '' AS INSTRUCTOR_ID,
                   '' AS INSTRUCTOR_FIRST_NAME,
                   '' AS INSTRUCTOR_LAST_NAME,
                   '' AS CORE_IND,
                   '' AS HONORS_IND,
                   '' AS ONLINE_IND,
                   '' AS SECTION_ATTRIBUTE,
                   ' ' AS GRADE_MODE_CD,
                   '' AS GRADE_CHANGE_CD,
                   '' AS DIVISION_CD,
                   a.crse_id AS course_id,
                   CASE
                      WHEN repeat_code IN ('RGPA',
                                           'RPRG',
                                           'TCCN',
                                           'RTRC')
                      THEN
                         repeat_code
                      ELSE
                         ' '
                   END
                      AS repeat_code,
                   DENSE_RANK ()
                   OVER (
                      PARTITION BY a.emplid, a.crse_id
                      ORDER BY
                         a.trnsfr_eqvlncy_grp DESC, a.trnsfr_eqvlncy_seq DESC)
                      AS repeat_rank,
                   CASE
                      WHEN LAG (
                              repeat_code,
                              1,
                              ' ')
                           OVER (
                              PARTITION BY a.emplid, a.crse_id
                              ORDER BY
                                 a.trnsfr_eqvlncy_grp,
                                 a.trnsfr_eqvlncy_seq DESC) = 'TCCN'
                      THEN
                         'Y'
                      ELSE
                         repeat_code
                   END
                      prior_repeat,
                   transConvert.CRSE_REPEATABLE
              FROM                                       --TRANSFER COURSEWORK
                   (SELECT *
                      FROM ps_rpt.PS_TRNS_CRSE_DTL d
                     WHERE     (REJECT_REASON = ' ' OR REJECT_REASON IS NULL)
                           AND CRSE_ID != ' '
                           AND d.crse_id NOT IN (SELECT crse_id
                                                   FROM crse_id_999tr) --  TR 999TR courses
                                                                      ) a
                   --TRANSFER INSTITUTION
                   LEFT JOIN (SELECT a.EMPLID,
                                     INSTITUTION,
                                     MODEL_NBR,
                                     b.DESCR50,
                                     a.SRC_ORG_NAME,
                                     a.model_status,
                                     a.acad_career
                                FROM ps_rpt.PS_TRNS_CRSE_SCH a
                                     JOIN
                                     (SELECT z.EXT_ORG_ID, z.DESCR50
                                        FROM ps_rpt.PS_EXT_ORG_TBL z
                                             JOIN
                                             (  SELECT EXT_ORG_ID,
                                                       MAX (EFFDT)
                                                          AS EFFDT
                                                  FROM ps_rpt.PS_EXT_ORG_TBL
                                              GROUP BY EXT_ORG_ID) y
                                                ON     y.EXT_ORG_ID =
                                                          z.EXT_ORG_ID
                                                   AND y.EFFDT = z.EFFDT) b
                                        ON b.EXT_ORG_ID = a.EXT_ORG_ID
                               WHERE 1 = 1     --AND a.ACAD_CAREER IN ('UGRD')
                                          AND a.model_status = 'P') school
                      ON     school.EMPLID = a.EMPLID
                         AND school.INSTITUTION = a.INSTITUTION
                         AND school.MODEL_NBR = a.MODEL_NBR
                         AND A.CRSE_ID != ' '
                         AND school.acad_career = a.acad_career
                   --DEEPER COURSE INFORMATION - INST SPECIFIC
                   LEFT JOIN
                   (SELECT ACAD_GROUP,
                           ACAD_CAREER,
                           a.SUBJECT,
                           CATALOG_NBR,
                           CRSE_ID,
                           a.INSTITUTION,
                           CRSE_OFFER_NBR,
                           b.ACAD_ORG,
                           a.ssr_component,
                           a.CRSE_REPEATABLE
                      FROM (SELECT cat.crse_id,
                                   off.institution,
                                   cat.effdt,
                                   cat.eff_status,
                                   cat.descr,
                                   cat.ssr_component,
                                   CAT.CRSE_REPEATABLE,
                                   OFF.ACAD_CAREER,
                                   off.acad_group,
                                   off.subject,
                                   off.catalog_nbr,
                                   OFF.CRSE_OFFER_NBR
                              FROM ps_rpt.ps_crse_catalog cat
                                   JOIN ps_rpt.ps_crse_offer off
                                      ON     cat.crse_id = off.crse_id
                                         AND cat.effdt = off.effdt) a
                           LEFT JOIN ps_rpt.PS_SUBJECT_TBL b
                              ON a.SUBJECT = b.SUBJECT
                     WHERE     a.EFFDT =
                                  (SELECT MAX (EFFDT)
                                     FROM ps_rpt.PS_CRSE_OFFER
                                    WHERE     CRSE_ID = a.CRSE_ID
                                          AND EFFDT <= SYSDATE)
                           AND b.EFFDT = (SELECT MAX (EFFDT)
                                            FROM ps_rpt.PS_SUBJECT_TBL
                                           WHERE b.SUBJECT = SUBJECT))
                   transConvert
                      ON     transConvert.INSTITUTION = a.INSTITUTION
                         AND transConvert.CRSE_ID = a.CRSE_ID
                         AND transConvert.CRSE_OFFER_NBR = a.CRSE_OFFER_NBR
             WHERE 1 = 1),
        tr999
        AS (SELECT a.EMPLID AS STUDENT_ID,
                   a.ARTICULATION_TERM AS TERM_ID,
                   'TRANSFER' AS CAMPUS_CD,
                   'TRANSFER' AS COLLEGE_CD,
                   NVL (transConvert.ACAD_ORG, '') AS DEPARTMENT_CD,
                   a.INCLUDE_IN_GPA AS GPA_INCLUDE_IND,
                   a.UNT_TAKEN AS COURSE_CREDITS,
                      --            SUBSTR (a.crse_id, 1, 3) || '-' || SUBSTR (a.crse_id, 4, 6)
                      --               AS course_cd,
                      TRIM (BOTH ' ' FROM transConvert.subject)
                   || ' '
                   || CASE
                         WHEN transConvert.catalog_nbr LIKE '%999%'
                         THEN
                            TRIM (BOTH ' ' FROM transConvert.catalog_nbr)
                         ELSE
                            REGEXP_SUBSTR (transConvert.catalog_nbr, '\d+')
                      END
                      AS course_cd,
                   COALESCE (
                         a.ARTICULATION_TERM
                      || a.TRNSFR_EQVLNCY_GRP
                      || a.TRNSFR_EQVLNCY_SEQ,
                      TRIM (' ' FROM transConvert.CRSE_ID))
                      AS COURSE_REF_NO,
                   'Y' AS REGISTERED_IND,
                   'E' AS REGISTRATION_STATUS_CD,
                   '' AS REGISTRATION_STATUS_DT,
                   CASE
                      WHEN a.REPEAT_CODE IN ('RGPA',
                                             'RPRG',
                                             'TCCN',
                                             'RTRC')
                      THEN
                         'Y'
                      ELSE
                         'N'
                   END
                      AS REPEAT_IND,
                   a.UNT_TAKEN AS ATTEMPTED_CREDITS,
                   CASE
                      WHEN (    a.EARN_CREDIT = 'Y'
                            AND (a.REPEAT_CODE = '' OR a.REPEAT_CODE = ' '))
                      THEN
                         a.UNT_TRNSFR
                      ELSE
                         0
                   END
                      AS EARNED_CREDITS,
                   '' AS FIELD16,
                   school.DESCR50 AS TRANSFERRING_INST,
                   CASE WHEN a.GRADE_CATEGORY = 'NONE' THEN 'N' ELSE 'Y' END
                      AS GRADABLE_IND,
                   '' AS MIDTERM_GRADE,
                   NVL (a.CRSE_GRADE_OFF, ' ') AS FINAL_GRADE,
                   '' AS FINAL_GRADE_DT,
                   'Y' AS FINAL_GRADE_OFFICIAL_IND,
                   0 AS GRADE_POINTS,
                   'N' AS INST_COURSE_IND,
                   'Y' AS TRANSFER_COURSE_IND,
                   'N' AS IN_PROGRESS_IND,
                   transConvert.ssr_component AS course_type_cd,
                   a.ACAD_CAREER AS STUDENT_LEVEL_CD,
                   '' AS FIELD29,
                   '' AS INSTRUCTION_METHOD,
                   '' AS FIELD31,
                   '' AS SECTION_START_DT,
                   '' AS SECTION_END_DT,
                   0 AS ENROLLMENT_MAX,
                   0 AS ENROLLMENT_CURRENT,
                   '' AS ENROLLMENT_CENSUS_DT,
                   '' AS INSTRUCTOR_ID,
                   '' AS INSTRUCTOR_FIRST_NAME,
                   '' AS INSTRUCTOR_LAST_NAME,
                   '' AS CORE_IND,
                   '' AS HONORS_IND,
                   '' AS ONLINE_IND,
                   '' AS SECTION_ATTRIBUTE,
                   ' ' AS GRADE_MODE_CD,
                   '' AS GRADE_CHANGE_CD,
                   '' AS DIVISION_CD,
                   a.crse_id AS course_id,
                   repeat_code,
                   0 AS repeat_rank,
                   ' ' AS prior_repeat
              FROM                                       --TRANSFER COURSEWORK
                   (SELECT *
                      FROM ps_rpt.PS_TRNS_CRSE_DTL d
                     WHERE     (REJECT_REASON = ' ' OR REJECT_REASON IS NULL)
                           AND CRSE_ID != ' '
                           AND d.crse_id IN (SELECT crse_id
                                               FROM crse_id_999tr) --  TR 999TR courses
                                                                  ) a
                   --TRANSFER INSTITUTION
                   LEFT JOIN (SELECT a.EMPLID,
                                     INSTITUTION,
                                     MODEL_NBR,
                                     b.DESCR50,
                                     a.SRC_ORG_NAME,
                                     a.model_status,
                                     a.acad_career
                                FROM ps_rpt.PS_TRNS_CRSE_SCH a
                                     JOIN
                                     (SELECT z.EXT_ORG_ID, z.DESCR50
                                        FROM ps_rpt.PS_EXT_ORG_TBL z
                                             JOIN
                                             (  SELECT EXT_ORG_ID,
                                                       MAX (EFFDT)
                                                          AS EFFDT
                                                  FROM ps_rpt.PS_EXT_ORG_TBL
                                              GROUP BY EXT_ORG_ID) y
                                                ON     y.EXT_ORG_ID =
                                                          z.EXT_ORG_ID
                                                   AND y.EFFDT = z.EFFDT) b
                                        ON b.EXT_ORG_ID = a.EXT_ORG_ID
                               WHERE 1 = 1     --AND a.ACAD_CAREER IN ('UGRD')
                                          AND a.model_status = 'P') school
                      ON     school.EMPLID = a.EMPLID
                         AND school.INSTITUTION = a.INSTITUTION
                         AND school.MODEL_NBR = a.MODEL_NBR
                         AND A.CRSE_ID != ' '
                         AND school.acad_career = a.acad_career
                   --DEEPER COURSE INFORMATION - INST SPECIFIC
                   LEFT JOIN
                   (SELECT ACAD_GROUP,
                           ACAD_CAREER,
                           a.SUBJECT,
                           CATALOG_NBR,
                           CRSE_ID,
                           a.INSTITUTION,
                           CRSE_OFFER_NBR,
                           b.ACAD_ORG,
                           a.ssr_component,
                           a.CRSE_REPEATABLE
                      FROM (SELECT cat.crse_id,
                                   off.institution,
                                   cat.effdt,
                                   cat.eff_status,
                                   cat.descr,
                                   cat.ssr_component,
                                   CAT.CRSE_REPEATABLE,
                                   OFF.ACAD_CAREER,
                                   off.acad_group,
                                   off.subject,
                                   off.catalog_nbr,
                                   OFF.CRSE_OFFER_NBR
                              FROM ps_rpt.ps_crse_catalog cat
                                   JOIN ps_rpt.ps_crse_offer off
                                      ON     cat.crse_id = off.crse_id
                                         AND cat.effdt = off.effdt) a
                           LEFT JOIN ps_rpt.PS_SUBJECT_TBL b
                              ON a.SUBJECT = b.SUBJECT
                     WHERE     a.EFFDT =
                                  (SELECT MAX (EFFDT)
                                     FROM ps_rpt.PS_CRSE_OFFER
                                    WHERE     CRSE_ID = a.CRSE_ID
                                          AND EFFDT <= SYSDATE)
                           AND b.EFFDT = (SELECT MAX (EFFDT)
                                            FROM ps_rpt.PS_SUBJECT_TBL
                                           WHERE b.SUBJECT = SUBJECT))
                   transConvert
                      ON     transConvert.INSTITUTION = a.INSTITUTION
                         AND transConvert.CRSE_ID = a.CRSE_ID
                         AND transConvert.CRSE_OFFER_NBR = a.CRSE_OFFER_NBR),
        enroll_w
        AS (SELECT a.emplid,
                   a.strm,
                   'W' AS stdnt_enrl_status,
                   a.crse_grade_off,
                   b.class_nbr,
                      TRIM (BOTH ' ' FROM b.subject)
                   || ' '
                   || CASE
                         WHEN b.catalog_nbr LIKE '%999%'
                         THEN
                            TRIM (BOTH ' ' FROM b.catalog_nbr)
                         ELSE
                            REGEXP_SUBSTR (b.catalog_nbr, '\d+')
                      END
                      AS course_cd
              FROM ps_rpt.ps_stdnt_enrl a
                   JOIN ps_rpt.ps_class_tbl b
                      ON a.strm = b.strm AND a.class_nbr = b.class_nbr
             WHERE a.stdnt_enrl_status = 'E' AND a.crse_grade_off = 'R'
            UNION ALL
            SELECT a.emplid,
                   a.strm,
                   'W' AS stdnt_enrl_status,
                   a.crse_grade_off,
                   b.class_nbr,
                      TRIM (BOTH ' ' FROM b.subject)
                   || ' '
                   || CASE
                         WHEN b.catalog_nbr LIKE '%999%'
                         THEN
                            TRIM (BOTH ' ' FROM b.catalog_nbr)
                         ELSE
                            REGEXP_SUBSTR (b.catalog_nbr, '\d+')
                      END
                      AS course_cd
              FROM ps_rpt.ps_stdnt_enrl a
                   JOIN ps_rpt.ps_class_tbl b
                      ON a.strm = b.strm AND a.class_nbr = b.class_nbr
             WHERE (    a.stdnt_enrl_status = 'E'
                    AND a.crse_grade_off = ' '
                    AND    TRIM (BOTH ' ' FROM b.subject)
                        || ' '
                        || CASE
                              WHEN b.catalog_nbr LIKE '%999%'
                              THEN
                                 TRIM (BOTH ' ' FROM b.catalog_nbr)
                              ELSE
                                 REGEXP_SUBSTR (b.catalog_nbr, '\d+')
                           END IN
                           (SELECT    TRIM (BOTH ' ' FROM b.subject)
                                   || ' '
                                   || CASE
                                         WHEN b.catalog_nbr LIKE '%999%'
                                         THEN
                                            TRIM (
                                               BOTH ' ' FROM b.catalog_nbr)
                                         ELSE
                                            REGEXP_SUBSTR (b.catalog_nbr,
                                                           '\d+')
                                      END
                              FROM ps_rpt.ps_stdnt_enrl a2
                                   JOIN ps_rpt.ps_class_tbl b
                                      ON     a2.strm = b.strm
                                         AND a2.class_nbr = b.class_nbr
                             WHERE     a.emplid = a2.emplid
                                   AND a.strm = a2.strm
                                   AND a2.stdnt_enrl_status = 'E'
                                   AND a2.crse_grade_off = 'R'))),
        enroll_class
        AS (SELECT e.emplid,
                   e.acad_career,
                   e.strm,
                   e.class_nbr,
                   e.repeat_code,
                   e.grading_basis_enrl,
                   NVL (w.stdnt_enrl_status, e.stdnt_enrl_status)
                      AS stdnt_enrl_status,
                   e.crse_grade_off,
                   e.grade_points,
                   e.grade_dt,
                   e.unt_earned,
                   e.earn_credit,
                   e.unt_taken,
                   e.enrl_add_dt,
                   e.enrl_status_reason,
                   e.include_in_gpa,
                   c.crse_id,
                   c.subject,
                   c.catalog_nbr,
                   c.ssr_component,
                   c.session_code,
                   c.class_section,
                   c.class_type,
                   c.instruction_mode,
                   c.enrl_tot,
                   c.enrl_cap,
                   c.end_dt,
                   c.start_dt,
                   c.acad_group
              FROM ps_rpt.ps_stdnt_enrl e
                   JOIN ps_rpt.ps_class_tbl c
                      ON e.STRM = c.strm AND e.class_nbr = c.class_nbr
                   FULL JOIN enroll_w w
                      ON     e.emplid = w.emplid
                         AND e.strm = w.strm
                         AND e.class_nbr = w.class_nbr
             WHERE 1 = 1),
        enrollments
        AS (SELECT a.EMPLID AS STUDENT_ID,
                   a.STRM AS TERM_ID,
                   'UB' AS CAMPUS_CD,
                   a.ACAD_GROUP AS COLLEGE_CD,
                   c.ACAD_ORG AS DEPARTMENT_CD,
                   a.INCLUDE_IN_GPA AS GPA_INCLUDE_IND,
                   c.UNITS_MAXIMUM AS COURSE_CREDITS,
                      TRIM (BOTH ' ' FROM a.subject)
                   || ' '
                   || CASE
                         WHEN a.catalog_nbr LIKE '%999%'
                         THEN
                            TRIM (BOTH ' ' FROM a.catalog_nbr)
                         ELSE
                            REGEXP_SUBSTR (a.catalog_nbr, '\d+')
                      END
                      AS course_cd,
                   TRIM (' ' FROM TO_CHAR (a.CLASS_NBR, '999999'))
                      AS COURSE_REF_NO,
                   CASE
                      WHEN     a.ENRL_STATUS_REASON IN ('ENRL', 'EWAT')
                           AND a.stdnt_enrl_status IN ('E', 'W')
                      THEN
                         'Y'
                      ELSE
                         'N'
                   END
                      AS REGISTERED_IND,
                   a.STDNT_ENRL_STATUS AS REGISTRATION_STATUS_CD,
                   TO_CHAR (a.ENRL_ADD_DT, 'YYYYMMDD')
                      AS REGISTRATION_STATUS_DT,
                   a.UNT_TAKEN AS ATTEMPTED_CREDITS,
                   CASE
                      WHEN (a.EARN_CREDIT = 'Y' AND a.GRADE_DT IS NOT NULL)
                      THEN
                         a.UNT_EARNED
                      ELSE
                         0
                   END
                      AS EARNED_CREDITS,
                   '' AS FIELD16,
                   '' AS TRANSFERRING_INST,
                   CASE
                      WHEN a.GRADING_BASIS_ENRL = 'NON' THEN 'N'
                      ELSE 'Y'
                   END
                      AS GRADABLE_IND,
                   mid.crse_grade_input AS MIDTERM_GRADE -- There is logic to pull this
                                                        ,
                   a.CRSE_GRADE_OFF AS FINAL_GRADE,
                   NVL (TO_CHAR (a.GRADE_DT, 'YYYYMMDD'), '')
                      AS FINAL_GRADE_DT,
                   CASE WHEN a.GRADE_DT IS NOT NULL THEN 'Y' END
                      AS FINAL_GRADE_OFFICIAL_IND,
                   a.GRADE_POINTS AS GRADE_POINTS,
                   'Y' AS INST_COURSE_IND,
                   'N' AS TRANSFER_COURSE_IND,
                   CASE
                      WHEN (    a.CRSE_GRADE_OFF = ' '
                            AND a.GRADING_BASIS_ENRL != 'NON'
                            AND a.stdnt_enrl_status = 'E'
                            AND A.grading_basis_enrl = 'GRD')
                      THEN
                         'Y'
                      ELSE
                         'N'
                   END
                      AS IN_PROGRESS_IND,
                   a.SSR_COMPONENT AS COURSE_TYPE_CD,
                   a.ACAD_CAREER AS STUDENT_LEVEL_CD,
                   '' AS FIELD29,
                   a.INSTRUCTION_MODE AS INSTRUCTION_METHOD,
                   '' AS FIELD31,
                   TO_CHAR (a.START_DT, 'YYYYMMDD') AS SECTION_START_DT,
                   TO_CHAR (a.END_DT, 'YYYYMMDD') AS SECTION_END_DT,
                   a.ENRL_CAP AS ENROLLMENT_MAX,
                   a.ENRL_TOT AS ENROLLMENT_CURRENT,
                   '' AS ENROLLMENT_CENSUS_DT,
                   '' AS INSTRUCTOR_ID                 --NVL(instr.EMPLID, '')
                                      ,
                   '' AS INSTRUCTOR_FIRST_NAME     --NVL(instr.FIRST_NAME, '')
                                              ,
                   '' AS INSTRUCTOR_LAST_NAME       --NVL(instr.LAST_NAME, '')
                                             ,
                   '' AS CORE_IND,
                   '' AS HONORS_IND,
                   CASE
                      WHEN a.INSTRUCTION_MODE IN ('OL', 'OR', 'OC') THEN 'Y'
                      ELSE 'N'
                   END
                      AS ONLINE_IND,
                   '' AS SECTION_ATTRIBUTE,
                   a.GRADING_BASIS_ENRL AS GRADE_MODE_CD,
                   '' AS GRADE_CHANGE_CD,
                   '' AS DIVISION_CD,
                   a.crse_id AS course_id,
                   a.repeat_code,
                   0 AS repeat_rank,
                   ' ' AS prior_repeat,
                   c.CRSE_REPEATABLE
              FROM enroll_class a
                   LEFT JOIN
                   (SELECT *
                      FROM ps_rpt.PS_SUBJECT_TBL c
                     WHERE c.EFFDT = (SELECT MAX (EFFDT) AS EFFDT
                                        FROM ps_rpt.PS_SUBJECT_TBL
                                       WHERE SUBJECT = c.SUBJECT)) c
                      ON a.SUBJECT = c.SUBJECT
                   --COURSE CREDITS
                   LEFT JOIN
                   (SELECT a.CRSE_ID, a.UNITS_MAXIMUM, a.CRSE_REPEATABLE
                      FROM ps_rpt.PS_CRSE_CATALOG a
                           JOIN (  SELECT CRSE_ID, MAX (EFFDT) AS EFFDT
                                     FROM ps_rpt.PS_CRSE_CATALOG
                                 GROUP BY CRSE_ID) b
                              ON b.CRSE_ID = a.CRSE_ID AND b.EFFDT = a.EFFDT)
                   c
                      ON c.CRSE_ID = a.CRSE_ID
                   --MIDTERM GRADE
                   LEFT JOIN
                   (SELECT gr.emplid,
                           gr.strm,
                           gr.class_nbr,
                           gr.crse_grade_input,
                           gr.grd_rstr_type_seq
                      FROM PS_RPT.PS_GRADE_ROSTER gr
                           JOIN PS_RPT.PS_GRADE_RSTR_TYPE grt
                              ON     gr.strm = grt.strm
                                 AND GR.CLASS_NBR = grt.class_nbr
                                 AND GR.GRD_RSTR_TYPE_SEQ =
                                        GRT.GRD_RSTR_TYPE_SEQ
                     WHERE     grt.grade_roster_type = 'MID'
                           AND GR.GRADE_ROSTER_STAT = 'G') MID
                      ON     MID.EMPLID = A.EMPLID
                         AND MID.STRM = A.STRM
                         AND MID.CLASS_NBR = A.CLASS_NBR
             WHERE 1 = 1),
        test_and_class
        AS (SELECT a.EMPLID AS STUDENT_ID,
                   a.ARTICULATION_TERM AS TERM_ID,
                   'EXAM' AS CAMPUS_CD,
                   'EXAM' AS COLLEGE_CD,
                   transConvert.ACAD_ORG AS DEPARTMENT_CD,
                   a.INCLUDE_IN_GPA AS GPA_INCLUDE_IND,
                   a.UNT_TRNSFR AS COURSE_CREDITS,
                      TRIM (BOTH ' ' FROM transConvert.subject)
                   || ' '
                   || CASE
                         WHEN transConvert.catalog_nbr LIKE '%999%'
                         THEN
                            TRIM (BOTH ' ' FROM transConvert.catalog_nbr)
                         ELSE
                            REGEXP_SUBSTR (transConvert.catalog_nbr, '\d+')
                      END
                      AS course_cd,
                   COALESCE (
                         a.ARTICULATION_TERM
                      || a.TRNSFR_EQVLNCY_GRP
                      || a.TRNSFR_EQVLNCY_SEQ,
                      TRIM (' ' FROM transConvert.CRSE_ID))
                      AS COURSE_REF_NO,
                   'Y' AS REGISTERED_IND,
                   'E' AS REGISTRATION_STATUS_CD,
                   '' AS REGISTRATION_STATUS_DT,
                   a.UNT_TRNSFR AS ATTEMPTED_CREDITS,
                   CASE
                      WHEN (    a.EARN_CREDIT = 'Y'
                            AND (a.REPEAT_CODE = ' ' OR a.REPEAT_CODE = ''))
                      THEN
                         a.UNT_TRNSFR
                      ELSE
                         0
                   END
                      AS EARNED_CREDITS,
                   '' AS FIELD16,
                   '' AS TRANSFERRING_INST,
                   CASE WHEN a.GRADE_CATEGORY = 'NONE' THEN 'N' ELSE 'Y' END
                      AS GRADABLE_IND,
                   '' AS MIDTERM_GRADE,
                   'TP' AS FINAL_GRADE,
                   '' AS FINAL_GRADE_DT,
                   'Y' AS FINAL_GRADE_OFFICIAL_IND,
                   0 AS GRADE_POINTS,
                   'N' AS INST_COURSE_IND,
                   'Y' AS TRANSFER_COURSE_IND,
                   'N' AS IN_PROGRESS_IND,
                   transConvert.SSR_COMPONENT AS COURSE_TYPE_CD,
                   a.ACAD_CAREER AS STUDENT_LEVEL_CD,
                   'TST' AS FIELD29,
                   '' AS INSTRUCTION_METHOD,
                   '' AS FIELD31,
                   '' AS SECTION_START_DT,
                   '' AS SECTION_END_DT,
                   0 AS ENROLLMENT_MAX,
                   0 AS ENROLLMENT_CURRENT,
                   '' AS ENROLLMENT_CENSUS_DT,
                   '' AS INSTRUCTOR_ID,
                   '' AS INSTRUCTOR_FIRST_NAME,
                   '' AS INSTRUCTOR_LAST_NAME,
                   '' AS CORE_IND,
                   '' AS HONORS_IND,
                   '' AS ONLINE_IND,
                   '' AS SECTION_ATTRIBUTE,
                   ' ' AS GRADE_MODE_CD,
                   '' AS GRADE_CHANGE_CD,
                   '' AS DIVISION_CD,
                   a.crse_id AS course_id,
                   repeat_code,
                   0 AS repeat_rank,
                   ' ' AS prior_repeat,
                   transConvert.CRSE_REPEATABLE
              FROM                                  --TRANSFER TEST COURSEWORK
                  ps_rpt.PS_TRNS_TEST_DTL a
                   --DEEPER COURSE INFORMATION - INST SPECIFIC
                   LEFT JOIN
                   (SELECT ACAD_GROUP,
                           ACAD_CAREER,
                           a.SUBJECT,
                           CATALOG_NBR,
                           CRSE_ID,
                           a.INSTITUTION,
                           CRSE_OFFER_NBR,
                           b.ACAD_ORG,
                           a.ssr_component,
                           a.CRSE_REPEATABLE
                      FROM (SELECT cat.crse_id,
                                   off.institution,
                                   cat.effdt,
                                   cat.eff_status,
                                   cat.descr,
                                   cat.ssr_component,
                                   cat.CRSE_REPEATABLE,
                                   OFF.ACAD_CAREER,
                                   off.acad_group,
                                   off.subject,
                                   off.catalog_nbr,
                                   OFF.CRSE_OFFER_NBR
                              FROM ps_rpt.ps_crse_catalog cat
                                   JOIN ps_rpt.ps_crse_offer off
                                      ON     cat.crse_id = off.crse_id
                                         AND cat.effdt = off.effdt) a
                           LEFT JOIN ps_rpt.PS_SUBJECT_TBL b
                              ON a.SUBJECT = b.SUBJECT
                     WHERE     a.EFFDT =
                                  (SELECT MAX (EFFDT)
                                     FROM ps_rpt.PS_CRSE_OFFER
                                    WHERE     CRSE_ID = a.CRSE_ID
                                          AND EFFDT <= SYSDATE)
                           AND b.EFFDT = (SELECT MAX (EFFDT)
                                            FROM ps_rpt.PS_SUBJECT_TBL
                                           WHERE b.SUBJECT = SUBJECT))
                   transConvert
                      ON     transConvert.INSTITUTION = a.INSTITUTION
                         AND transConvert.CRSE_ID = a.CRSE_ID
                         AND transConvert.CRSE_OFFER_NBR = a.CRSE_OFFER_NBR
             WHERE 1 = 1 AND A.TRNSFR_STAT IN ('P', 'Y') AND A.CRSE_ID != ' '),
        combined
        AS (SELECT '3' AS enroll_source,                             -- enroll
                                        enrl.*
              FROM enrollments enrl
            UNION ALL
            SELECT '2' AS enroll_source,                          --  transfer
                                        trans.*
              FROM trans_and_class trans
             WHERE 1 = 1 AND repeat_rank = 1
            UNION ALL
            SELECT '1' AS enroll_source,                        -- test_credit
                                        tests.*
              FROM test_and_class tests),
        enroll_repeats
        AS (  SELECT student_id,
                     course_id,
                     COURSE_TYPE_CD,
                     MAX (term_id || enroll_source) AS last_repeat,
                     COUNT (*) AS repeat_count
                FROM combined
               WHERE     1 = 1
                     AND repeat_code != ' '
                     AND SUBSTR (FINAL_GRADE, 1, 1) != 'W'
                     AND SUBSTR (FINAL_GRADE, 1, 1) != '#'
                     AND SUBSTR (FINAL_GRADE, 1, 1) != 'I'
                     AND CRSE_REPEATABLE != 'Y'
                     AND STUDENT_LEVEL_CD = 'UGRD'
                     AND (grade_mode_cd != 'NON')
                     AND REGISTRATION_STATUS_CD = 'E'
            GROUP BY student_id, course_id, COURSE_TYPE_CD)
   SELECT c.STUDENT_ID,
          c.TERM_ID,
          c.CAMPUS_CD,
          c.COLLEGE_CD,
          c.DEPARTMENT_CD,
          c.GPA_INCLUDE_IND,
          c.COURSE_CREDITS,
          c.COURSE_CD,
          c.COURSE_REF_NO,
          c.REGISTERED_IND,
          c.REGISTRATION_STATUS_CD,
          c.REGISTRATION_STATUS_DT,
          CASE
             WHEN     SUBSTR (r.last_repeat, 1, 4) = c.term_id
                  AND r.repeat_count > 1
                  AND c.enroll_source = '3'                          --  enrls
                  AND c.repeat_code != ' '
             THEN
                'Y'                                                         --
             WHEN     SUBSTR (r.last_repeat, 1, 4) = c.term_id
                  AND r.repeat_count > 1
                  AND c.repeat_code != ' '
                  AND c.enroll_source = '2' -- catch transfer repeats with a code
             THEN
                'Y'
             WHEN c.prior_repeat = 'Y'
             THEN
                'Y'                                 -- TCCN on previous repeat
             WHEN     SUBSTR (r.last_repeat, 1, 4) = c.term_id
                  AND r.repeat_count = 1 -- If the 1 course found has a repeat code
                  AND c.repeat_code != ' '
             THEN
                'Y'
             ELSE
                'N'
          END
             AS REPEAT_IND,
          c.ATTEMPTED_CREDITS,
          c.EARNED_CREDITS,
          c.FIELD16,
          c.TRANSFERRING_INST,
          c.GRADABLE_IND,
          c.MIDTERM_GRADE,
          c.FINAL_GRADE,
          c.FINAL_GRADE_DT,
          c.FINAL_GRADE_OFFICIAL_IND,
          c.GRADE_POINTS,
          c.INST_COURSE_IND,
          c.TRANSFER_COURSE_IND,
          c.IN_PROGRESS_IND,
          c.COURSE_TYPE_CD,
          c.STUDENT_LEVEL_CD,
          c.FIELD29,
          c.INSTRUCTION_METHOD,
          c.FIELD31,
          c.SECTION_START_DT,
          c.SECTION_END_DT,
          c.ENROLLMENT_MAX,
          c.ENROLLMENT_CURRENT,
          c.ENROLLMENT_CENSUS_DT,
          c.INSTRUCTOR_ID,
          c.INSTRUCTOR_FIRST_NAME,
          c.INSTRUCTOR_LAST_NAME,
          c.CORE_IND,
          c.HONORS_IND,
          c.ONLINE_IND,
          c.SECTION_ATTRIBUTE,
          c.GRADE_MODE_CD,
          DECODE (c.GRADE_MODE_CD, ' ', NULL, c.GRADE_MODE_CD)
             AS GRADE_MODE_CD,
          c.DIVISION_CD,
          c.COURSE_ID,
          CASE
             WHEN     REGISTRATION_STATUS_CD = 'E'
                  AND FINAL_GRADE NOT LIKE 'I%'
                  AND TERM_ID <
                         (SELECT STRM
                            FROM PS_RPT.PS_UB_TERM_VAL_TBL
                           WHERE     ACAD_CAREER = 'UGRD'
                                 AND UB_TERM_DESCR = 'Current Term - UGRD')
             THEN
                'COMPLETED'
             WHEN     REGISTRATION_STATUS_CD = 'W'
                  AND (FINAL_GRADE = 'R' OR FINAL_GRADE = ' ')
                  AND TERM_ID <
                         (SELECT STRM
                            FROM PS_RPT.PS_UB_TERM_VAL_TBL
                           WHERE     ACAD_CAREER = 'UGRD'
                                 AND UB_TERM_DESCR = 'Current Term - UGRD')
             THEN
                'COMPLETED'
             WHEN     REGISTRATION_STATUS_CD = 'E'
                  AND FINAL_GRADE = ' '
                  AND TERM_ID =
                         (SELECT STRM
                            FROM PS_RPT.PS_UB_TERM_VAL_TBL
                           WHERE     ACAD_CAREER = 'UGRD'
                                 AND UB_TERM_DESCR = 'Current Term - UGRD')
             THEN
                'IN-PROGRESS'
             WHEN     REGISTRATION_STATUS_CD = 'E'
                  AND FINAL_GRADE <> ' '
                  AND TERM_ID =
                         (SELECT STRM
                            FROM PS_RPT.PS_UB_TERM_VAL_TBL
                           WHERE     ACAD_CAREER = 'UGRD'
                                 AND UB_TERM_DESCR = 'Current Term - UGRD')
             THEN
                'COMPLETED'
             WHEN     REGISTRATION_STATUS_CD = 'E'
                  AND TERM_ID >
                         (SELECT STRM
                            FROM PS_RPT.PS_UB_TERM_VAL_TBL
                           WHERE     ACAD_CAREER = 'UGRD'
                                 AND UB_TERM_DESCR = 'Current Term - UGRD')
             THEN
                'REGISTERED'
             WHEN REGISTRATION_STATUS_CD = 'I'
             THEN
                'IN-PROGRESS'
             WHEN     FINAL_GRADE LIKE 'I%'
                  AND TERM_ID <=
                         (SELECT STRM
                            FROM PS_RPT.PS_UB_TERM_VAL_TBL
                           WHERE     ACAD_CAREER = 'UGRD'
                                 AND UB_TERM_DESCR = 'Current Term - UGRD')
             THEN
                'IN-PROGRESS'
             WHEN REGISTRATION_STATUS_CD = 'D'
             THEN
                'UNKNOWN'
          END
             AS STATUS
     FROM combined c
          LEFT JOIN enroll_repeats r
             ON     c.student_id = r.student_id
                AND c.course_id = r.course_id
                AND c.COURSE_TYPE_CD = r.COURSE_TYPE_CD
                AND c.enroll_source = SUBSTR (r.last_repeat, 5, 1)
                AND (c.grade_mode_cd != 'NON')
   UNION ALL
   SELECT tr.STUDENT_ID,
          tr.TERM_ID,
          tr.CAMPUS_CD,
          tr.COLLEGE_CD,
          tr.DEPARTMENT_CD,
          tr.GPA_INCLUDE_IND,
          tr.COURSE_CREDITS,
          tr.COURSE_CD,
          tr.COURSE_REF_NO,
          tr.REGISTERED_IND,
          tr.REGISTRATION_STATUS_CD,
          tr.REGISTRATION_STATUS_DT,
          tr.REPEAT_IND,
          tr.ATTEMPTED_CREDITS,
          tr.EARNED_CREDITS,
          tr.FIELD16,
          tr.TRANSFERRING_INST,
          tr.GRADABLE_IND,
          tr.MIDTERM_GRADE,
          tr.FINAL_GRADE,
          tr.FINAL_GRADE_DT,
          tr.FINAL_GRADE_OFFICIAL_IND,
          tr.GRADE_POINTS,
          tr.INST_COURSE_IND,
          tr.TRANSFER_COURSE_IND,
          tr.IN_PROGRESS_IND,
          tr.COURSE_TYPE_CD,
          tr.STUDENT_LEVEL_CD,
          tr.FIELD29,
          tr.INSTRUCTION_METHOD,
          tr.FIELD31,
          tr.SECTION_START_DT,
          tr.SECTION_END_DT,
          tr.ENROLLMENT_MAX,
          tr.ENROLLMENT_CURRENT,
          tr.ENROLLMENT_CENSUS_DT,
          tr.INSTRUCTOR_ID,
          tr.INSTRUCTOR_FIRST_NAME,
          tr.INSTRUCTOR_LAST_NAME,
          tr.CORE_IND,
          tr.HONORS_IND,
          tr.ONLINE_IND,
          tr.SECTION_ATTRIBUTE,
          tr.GRADE_MODE_CD,
          tr.GRADE_CHANGE_CD,
          tr.DIVISION_CD,
          tr.COURSE_ID,
          CASE
             WHEN     REGISTRATION_STATUS_CD = 'E'
                  AND FINAL_GRADE NOT LIKE 'I%'
                  AND TERM_ID <
                         (SELECT STRM
                            FROM PS_RPT.PS_UB_TERM_VAL_TBL
                           WHERE     ACAD_CAREER = 'UGRD'
                                 AND UB_TERM_DESCR = 'Current Term - UGRD')
             THEN
                'COMPLETED'
             WHEN     REGISTRATION_STATUS_CD = 'W'
                  AND (FINAL_GRADE = 'R' OR FINAL_GRADE = ' ')
                  AND TERM_ID <
                         (SELECT STRM
                            FROM PS_RPT.PS_UB_TERM_VAL_TBL
                           WHERE     ACAD_CAREER = 'UGRD'
                                 AND UB_TERM_DESCR = 'Current Term - UGRD')
             THEN
                'COMPLETED'
             WHEN     REGISTRATION_STATUS_CD = 'E'
                  AND FINAL_GRADE = ' '
                  AND TERM_ID =
                         (SELECT STRM
                            FROM PS_RPT.PS_UB_TERM_VAL_TBL
                           WHERE     ACAD_CAREER = 'UGRD'
                                 AND UB_TERM_DESCR = 'Current Term - UGRD')
             THEN
                'IN-PROGRESS'
             WHEN     REGISTRATION_STATUS_CD = 'E'
                  AND FINAL_GRADE <> ' '
                  AND TERM_ID =
                         (SELECT STRM
                            FROM PS_RPT.PS_UB_TERM_VAL_TBL
                           WHERE     ACAD_CAREER = 'UGRD'
                                 AND UB_TERM_DESCR = 'Current Term - UGRD')
             THEN
                'COMPLETED'
             WHEN     REGISTRATION_STATUS_CD = 'E'
                  AND TERM_ID >
                         (SELECT STRM
                            FROM PS_RPT.PS_UB_TERM_VAL_TBL
                           WHERE     ACAD_CAREER = 'UGRD'
                                 AND UB_TERM_DESCR = 'Current Term - UGRD')
             THEN
                'REGISTERED'
             WHEN REGISTRATION_STATUS_CD = 'I'
             THEN
                'IN-PROGRESS'
             WHEN     FINAL_GRADE LIKE 'I%'
                  AND TERM_ID <=
                         (SELECT STRM
                            FROM PS_RPT.PS_UB_TERM_VAL_TBL
                           WHERE     ACAD_CAREER = 'UGRD'
                                 AND UB_TERM_DESCR = 'Current Term - UGRD')
             THEN
                'IN-PROGRESS'
             WHEN REGISTRATION_STATUS_CD = 'D'
             THEN
                'UNKNOWN'
          END
             AS STATUS
     FROM tr999 tr
    WHERE 1 = 1
   UNION ALL
   SELECT mr.STUDENT_ID,
          mr.TERM_ID,
          mr.CAMPUS_CD,
          mr.COLLEGE_CD,
          mr.DEPARTMENT_CD,
          mr.GPA_INCLUDE_IND,
          mr.COURSE_CREDITS,
          mr.COURSE_CD,
          mr.COURSE_REF_NO,
          mr.REGISTERED_IND,
          mr.REGISTRATION_STATUS_CD,
          mr.REGISTRATION_STATUS_DT,
          'N' AS REPEAT_IND,
          mr.ATTEMPTED_CREDITS,
          mr.EARNED_CREDITS,
          mr.FIELD16,
          mr.TRANSFERRING_INST,
          mr.GRADABLE_IND,
          mr.MIDTERM_GRADE,
          mr.FINAL_GRADE,
          mr.FINAL_GRADE_DT,
          mr.FINAL_GRADE_OFFICIAL_IND,
          mr.GRADE_POINTS,
          mr.INST_COURSE_IND,
          mr.TRANSFER_COURSE_IND,
          mr.IN_PROGRESS_IND,
          mr.COURSE_TYPE_CD,
          mr.STUDENT_LEVEL_CD,
          mr.FIELD29,
          mr.INSTRUCTION_METHOD,
          mr.FIELD31,
          mr.SECTION_START_DT,
          mr.SECTION_END_DT,
          mr.ENROLLMENT_MAX,
          mr.ENROLLMENT_CURRENT,
          mr.ENROLLMENT_CENSUS_DT,
          mr.INSTRUCTOR_ID,
          mr.INSTRUCTOR_FIRST_NAME,
          mr.INSTRUCTOR_LAST_NAME,
          mr.CORE_IND,
          mr.HONORS_IND,
          mr.ONLINE_IND,
          mr.SECTION_ATTRIBUTE,
          mr.GRADE_MODE_CD,
          mr.GRADE_CHANGE_CD,
          mr.DIVISION_CD,
          mr.COURSE_ID,
          CASE
             WHEN     REGISTRATION_STATUS_CD = 'E'
                  AND FINAL_GRADE NOT LIKE 'I%'
                  AND TERM_ID <
                         (SELECT STRM
                            FROM PS_RPT.PS_UB_TERM_VAL_TBL
                           WHERE     ACAD_CAREER = 'UGRD'
                                 AND UB_TERM_DESCR = 'Current Term - UGRD')
             THEN
                'COMPLETED'
             WHEN     REGISTRATION_STATUS_CD = 'W'
                  AND (FINAL_GRADE = 'R' OR FINAL_GRADE = ' ')
                  AND TERM_ID <
                         (SELECT STRM
                            FROM PS_RPT.PS_UB_TERM_VAL_TBL
                           WHERE     ACAD_CAREER = 'UGRD'
                                 AND UB_TERM_DESCR = 'Current Term - UGRD')
             THEN
                'COMPLETED'
             WHEN     REGISTRATION_STATUS_CD = 'E'
                  AND FINAL_GRADE = ' '
                  AND TERM_ID =
                         (SELECT STRM
                            FROM PS_RPT.PS_UB_TERM_VAL_TBL
                           WHERE     ACAD_CAREER = 'UGRD'
                                 AND UB_TERM_DESCR = 'Current Term - UGRD')
             THEN
                'IN-PROGRESS'
             WHEN     REGISTRATION_STATUS_CD = 'E'
                  AND FINAL_GRADE <> ' '
                  AND TERM_ID =
                         (SELECT STRM
                            FROM PS_RPT.PS_UB_TERM_VAL_TBL
                           WHERE     ACAD_CAREER = 'UGRD'
                                 AND UB_TERM_DESCR = 'Current Term - UGRD')
             THEN
                'COMPLETED'
             WHEN     REGISTRATION_STATUS_CD = 'E'
                  AND TERM_ID >
                         (SELECT STRM
                            FROM PS_RPT.PS_UB_TERM_VAL_TBL
                           WHERE     ACAD_CAREER = 'UGRD'
                                 AND UB_TERM_DESCR = 'Current Term - UGRD')
             THEN
                'REGISTERED'
             WHEN REGISTRATION_STATUS_CD = 'I'
             THEN
                'IN-PROGRESS'
             WHEN     FINAL_GRADE LIKE 'I%'
                  AND TERM_ID <=
                         (SELECT STRM
                            FROM PS_RPT.PS_UB_TERM_VAL_TBL
                           WHERE     ACAD_CAREER = 'UGRD'
                                 AND UB_TERM_DESCR = 'Current Term - UGRD')
             THEN
                'IN-PROGRESS'
             WHEN REGISTRATION_STATUS_CD = 'D'
             THEN
                'UNKNOWN'
          END
             AS STATUS
     FROM trans_and_class mr
    WHERE 1 = 1 AND repeat_rank != 1