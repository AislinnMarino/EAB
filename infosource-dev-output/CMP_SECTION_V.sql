WITH Section
        AS (  SELECT NVL (TRIM (a.CLASS_SECTION), '') AS SECTION_NAME,
                     NVL (TRIM (REGEXP_SUBSTR (a.catalog_nbr, '\d+')), '')
                        AS COURSE_NUMBER,
                     NVL (TRIM (a.SUBJECT), '') AS SUBJECT_CD,
                     NVL (a.CLASS_NBR, '') AS COURSE_REF_NO,
                     NVL (a.STRM, '') AS TERM_CODE,
                     NVL (a.SSR_COMPONENT, '') AS COURSE_TYPE_CODE,
                     ' ' AS SECTION_TAG,
                        a.subject
                     || ' '
                     || a.catalog_nbr
                     || ' '
                     || NVL (a.DESCR, '')
                        AS SECTION_TITLE,
                     N.Name AS Instructor_Name,
                     B.start_dt AS Class_Start_Dt,
                     B.end_dt AS Class_End_Dt,
                     'N' AS is_unlimited_seating,
                     ' ' AS section_type,
                     CASE WHEN B.end_dt >= SYSDATE THEN 'Y' ELSE 'N' END
                        AS is_active
                FROM ps_rpt.PS_CLASS_TBL a
                     LEFT JOIN ps_rpt.PS_CLASS_MTG_PAT B
                        ON     B.CRSE_ID = A.CRSE_ID
                           AND B.CRSE_OFFER_NBR = A.CRSE_OFFER_NBR
                           AND B.STRM = A.STRM
                           AND B.SESSION_CODE = A.SESSION_CODE
                           AND B.CLASS_SECTION = A.CLASS_SECTION
                     LEFT JOIN (SELECT *
                                  FROM PS_RPT.PS_CLASS_INSTR
                                 WHERE INSTR_ROLE IN ('PI',
                                                      'SI',
                                                      'TA',
                                                      'CA')) I
                        ON (    a.CRSE_ID = I.CRSE_ID
                            AND a.STRM = I.STRM
                            AND a.CRSE_OFFER_NBR = I.CRSE_OFFER_NBR
                            AND a.SESSION_CODE = I.SESSION_CODE
                            AND a.CLASS_SECTION = I.CLASS_SECTION)
                     LEFT JOIN
                     (SELECT NA.EMPLID, NA.Name, NA.NAME_TYPE
                        FROM PS_RPT.PS_NAMES NA
                       WHERE     NA.NAME_TYPE =
                                    CASE
                                       WHEN EXISTS
                                               (SELECT *
                                                  FROM PS_RPT.PS_NAMES NMPRF
                                                 WHERE     NAME_TYPE = 'PRF'
                                                       AND EFF_STATUS = 'A'
                                                       AND NA.EMPLID =
                                                              NMPRF.EMPLID
                                                       AND NMPRF.EFFDT =
                                                              (SELECT MAX (
                                                                         NMPRF_1.EFFDT)
                                                                 FROM PS_RPT.PS_NAMES
                                                                      NMPRF_1
                                                                WHERE     NMPRF.EMPLID =
                                                                             NMPRF_1.EMPLID
                                                                      AND NMPRF.NAME_TYPE =
                                                                             NMPRF_1.NAME_TYPE
                                                                      AND NMPRF_1.EFFDT <=
                                                                             SYSDATE))
                                       THEN
                                          'PRF'
                                       ELSE
                                          'PRI'
                                    END
                             AND NA.EFFDT =
                                    (SELECT MAX (B_ED.EFFDT)
                                       FROM PS_RPT.PS_NAMES B_ED
                                      WHERE     NA.EMPLID = B_ED.EMPLID
                                            AND NA.NAME_TYPE = B_ED.NAME_TYPE
                                            AND B_ED.EFFDT <= SYSDATE)
                             AND NA.EFF_STATUS = 'A') N
                        ON (I.EMPLID = N.EMPLID)
               WHERE     1 = 1
                     AND a.enrl_tot > 0
                     AND a.STRM >= (SELECT cf.lookback_term --Rolling filter to grab only terms up to a year ago
                                      FROM ps_rpt.cmp_filter_current_v cf)
            ORDER BY a.subject, a.catalog_nbr)
     SELECT SECTION_NAME,
            COURSE_NUMBER,
            SUBJECT_CD,
            COURSE_REF_NO,
            TERM_CODE,
            COURSE_TYPE_CODE,
            SECTION_TAG,
            SECTION_TITLE,
            SUBSTR(LISTAGG (INSTRUCTOR_NAME, '; ')
               WITHIN GROUP (ORDER BY INSTRUCTOR_NAME), 1, 64) --Adding this to concatenate instructor names on one row
               AS INSTRUCTOR_NAME,
            CLASS_START_DT,
            CLASS_END_DT,
            IS_UNLIMITED_SEATING,
            SECTION_TYPE,
            IS_ACTIVE
       FROM (SELECT DISTINCT INSTRUCTOR_NAME,
                             SECTION_NAME,
                             COURSE_NUMBER,
                             SUBJECT_CD,
                             COURSE_REF_NO,
                             TERM_CODE,
                             COURSE_TYPE_CODE,
                             SECTION_TAG,
                             SECTION_TITLE,
                             CLASS_START_DT,
                             CLASS_END_DT,
                             IS_UNLIMITED_SEATING,
                             SECTION_TYPE,
                             IS_ACTIVE
               FROM Section)
   GROUP BY SECTION_NAME,
            COURSE_NUMBER,
            SUBJECT_CD,
            COURSE_REF_NO,
            TERM_CODE,
            COURSE_TYPE_CODE,
            SECTION_TAG,
            SECTION_TITLE,
            CLASS_START_DT,
            CLASS_END_DT,
            IS_UNLIMITED_SEATING,
            SECTION_TYPE,
            IS_ACTIVE