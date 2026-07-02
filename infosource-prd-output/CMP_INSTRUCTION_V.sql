SELECT "SUBJECT_CD","COURSE_NO","COURSE_REF_NO","TERM_ID","INSTRUCTOR_ID","PRIMARY_INSTRUCTOR_FLAG","SECTION_NAME"
        FROM (SELECT DISTINCT
                     a.subject
                         AS subject_cd,
                     REGEXP_SUBSTR (a.catalog_nbr, '\d+')
                         AS course_no,
                     NVL (TRIM (a.CLASS_NBR), '')
                         AS COURSE_REF_NO,
                     NVL (a.STRM, '')
                         AS TERM_ID,
                     NVL (b.EMPLID, '')
                         AS INSTRUCTOR_ID,
                     RANK ()
                         OVER (PARTITION BY B.CRSE_ID,
                                            B.CRSE_OFFER_NBR,
                                            B.STRM,
                                            B.SESSION_CODE,
                                            B.CLASS_SECTION
                               ORDER BY B.INSTR_ROLE, B.INSTR_ASSIGN_SEQ)
                         AS PRIMARY_INSTRUCTOR_FLAG,
                     NVL (a.CLASS_SECTION, '')
                         AS SECTION_NAME
                FROM PS_CLASS_TBL a
                     JOIN PS_CLASS_INSTR b
                         ON     a.CRSE_ID = b.CRSE_ID
                            AND a.CLASS_SECTION = b.CLASS_SECTION
                            AND a.CRSE_OFFER_NBR = b.CRSE_OFFER_NBR
                            AND a.STRM = b.STRM
                            AND a.session_code = b.session_code
               WHERE     1 = 1
                     AND a.enrl_tot > 0
                     AND B.INSTR_ROLE IN ('PI', 'SI', 'TA')
                     AND B.EMPLID != ' '
                     AND a.STRM >= (SELECT cf.lookback_term --Rolling filter to grab only terms up to a year ago
                                      FROM ps_rpt.cmp_filter_current_v cf))
       WHERE 1 = 1 AND PRIMARY_INSTRUCTOR_FLAG = 1
    ORDER BY SUBJECT_CD,
             COURSE_NO,
             TERM_ID,
             SECTION_NAME,
             PRIMARY_INSTRUCTOR_FLAG DESC