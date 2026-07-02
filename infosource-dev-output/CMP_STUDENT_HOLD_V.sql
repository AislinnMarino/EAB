WITH MultipleBillingCareers
        AS (  SELECT CARTERM.EMPLID,
                     CARTERM.STRM,
                     COUNT (DISTINCT CARTERM.BILLING_CAREER)
                        AS BILLING_CAREER_COUNT
                FROM PS_STDNT_CAR_TERM_V CARTERM
                     JOIN CMP_POPULATION_CURRENT_V CURR
                        ON CARTERM.EMPLID = CURR.EMPLID
            GROUP BY CARTERM.EMPLID, CARTERM.STRM
              HAVING COUNT (DISTINCT BILLING_CAREER) > 1),
        MaxDatedSrvcIndRsn
        AS (SELECT SRVC_RSN_TBL.INSTITUTION,
                   SRVC_RSN_TBL.SRVC_IND_CD,
                   SRVC_RSN_TBL.EFFDT,
                   SRVC_RSN_TBL.SRVC_IND_REASON,
                   SRVC_RSN_TBL.DESCR,
                   SRVC_RSN_TBL.DESCRSHORT,
                   SRVC_RSN_TBL.SRVC_IN_REF_TYPE,
                   SRVC_RSN_TBL.DEPTID,
                   SRVC_RSN_TBL.POSITION_NBR,
                   SRVC_RSN_TBL.CHECKLIST_CONTROL,
                   SRVC_RSN_TBL.MULTPLE_OCCUR,
                   SRVC_RSN_TBL.DESCRLONG
              FROM PS_SRVC_IN_RSN_TBL_V SRVC_RSN_TBL
             WHERE     INSTITUTION = 'UBFLO'
                   AND EFFDT =
                          (SELECT MAX (EFFDT)
                             FROM PS_SRVC_IN_RSN_TBL_V
                            WHERE     SRVC_RSN_TBL.SRVC_IND_CD = SRVC_IND_CD
                                  AND SRVC_RSN_TBL.SRVC_IND_REASON =
                                         SRVC_IND_REASON
                                  AND INSTITUTION = 'UBFLO'))
   SELECT DISTINCT
          SDATA.EMPLID AS STUDENT_ID,
          SDATA.SRVC_IND_CD || '-' || SDATA.SRVC_IND_REASON AS HOLD_CODE,
          HOLDV.DESCRIPTION AS HOLD_DESCRIPTION,
          CASE
             WHEN SDATA.SRVC_IND_ACTIVE_DT IS NOT NULL
             THEN
                SRVC_IND_ACTIVE_DT
             ELSE
                /* If a student has a car term record for the start term specified, then get the start date of the term with the billing career from that car term record. Otherwise, default to UGRD. */
                CASE
                   WHEN     SDATA.SRVC_IND_ACT_TERM <> ' '
                        AND (SELECT DISTINCT 'X'
                               FROM PS_STDNT_CAR_TERM
                              WHERE     EMPLID = SDATA.EMPLID
                                    AND STRM = SDATA.SRVC_IND_ACT_TERM) = 'X'
                   THEN
                      /* If a student does not have multiple distinct billing careers for the term specified, then use that billing career to get the term start date. Otherwise, default to UGRD */
                      CASE
                         WHEN (SELECT BILLING_CAREER_COUNT
                                 FROM MultipleBillingCareers
                                WHERE     SDATA.EMPLID = EMPLID
                                      AND STRM = SDATA.SRVC_IND_ACT_TERM) = 1
                         THEN
                            (SELECT TERM_BEGIN_DT
                               FROM PS_TERM_TBL
                              WHERE     INSTITUTION = SDATA.INSTITUTION
                                    AND STRM = SDATA.SRVC_IND_ACT_TERM
                                    AND ACAD_CAREER =
                                           (SELECT DISTINCT BILLING_CAREER
                                              FROM PS_STDNT_CAR_TERM
                                             WHERE     EMPLID = SDATA.EMPLID
                                                   AND STRM =
                                                          SDATA.SRVC_IND_ACT_TERM
                                                   AND INSTITUTION =
                                                          SDATA.INSTITUTION))
                         ELSE
                            (SELECT TERM_BEGIN_DT
                               FROM PS_TERM_TBL
                              WHERE     INSTITUTION = SDATA.INSTITUTION
                                    AND STRM = SDATA.SRVC_IND_ACT_TERM
                                    AND ACAD_CAREER = 'UGRD')
                      END
                   ELSE
                      /* Student does not have a car term record for the start term specified. Default to UGRD */
                      CASE
                         WHEN     SDATA.SRVC_IND_ACT_TERM <> ' '
                              AND (SELECT DISTINCT 'X'
                                     FROM PS_STDNT_CAR_TERM
                                    WHERE     EMPLID = SDATA.EMPLID
                                          AND STRM = SDATA.SRVC_IND_ACT_TERM) <>
                                     'X'
                         THEN
                            (SELECT TERM_BEGIN_DT
                               FROM PS_TERM_TBL
                              WHERE     INSTITUTION = SDATA.INSTITUTION
                                    AND STRM = SDATA.SRVC_IND_ACT_TERM
                                    AND ACAD_CAREER = 'UGRD')
                         ELSE
                            NULL
                      END
                END
          END
             AS START_DATE,
          CASE
             WHEN SDATA.SCC_SI_END_DT IS NOT NULL
             THEN
                SDATA.SCC_SI_END_DT
             ELSE
                /*If the student has a car term record for the end term, then get the start date of the end term using the billing career for that car term record */
                CASE
                   WHEN     SDATA.SCC_SI_END_TERM <> ' '
                        AND (SELECT DISTINCT 'X'
                               FROM PS_STDNT_CAR_TERM
                              WHERE     EMPLID = SDATA.EMPLID
                                    AND STRM = SDATA.SCC_SI_END_TERM) = 'X'
                   THEN
                      /* If the student does not have multiple distinct billing careers in the car term record, then use that billing career. Otherwise, default to UGRD */
                      CASE
                         WHEN (SELECT BILLING_CAREER_COUNT
                                 FROM MultipleBillingCareers
                                WHERE     SDATA.EMPLID = EMPLID
                                      AND STRM = SDATA.SCC_SI_END_TERM) = 1
                         THEN
                            (SELECT TERM_BEGIN_DT
                               FROM PS_TERM_TBL
                              WHERE     INSTITUTION = SDATA.INSTITUTION
                                    AND STRM = SDATA.SCC_SI_END_TERM
                                    AND ACAD_CAREER =
                                           (SELECT DISTINCT BILLING_CAREER
                                              FROM PS_STDNT_CAR_TERM
                                             WHERE     EMPLID = SDATA.EMPLID
                                                   AND STRM =
                                                          SDATA.SCC_SI_END_TERM
                                                   AND INSTITUTION =
                                                          SDATA.INSTITUTION))
                         ELSE
                            (SELECT TERM_BEGIN_DT
                               FROM PS_TERM_TBL
                              WHERE     INSTITUTION = SDATA.INSTITUTION
                                    AND STRM = SDATA.SCC_SI_END_TERM
                                    AND ACAD_CAREER = 'UGRD')
                      END
                   ELSE
                      /*If a student does not have a car term record for the end term specified, then default to UGRD*/
                      CASE
                         WHEN     SDATA.SCC_SI_END_TERM <> ' '
                              AND (SELECT DISTINCT 'X'
                                     FROM PS_STDNT_CAR_TERM
                                    WHERE     EMPLID = SDATA.EMPLID
                                          AND STRM = SDATA.SCC_SI_END_TERM) <>
                                     'X'
                         THEN
                            (SELECT TERM_BEGIN_DT
                               FROM PS_TERM_TBL
                              WHERE     INSTITUTION = SDATA.INSTITUTION
                                    AND STRM = SDATA.SCC_SI_END_TERM
                                    AND ACAD_CAREER = 'UGRD')
                         ELSE
                            /* If the students' hold has a start term, but no start date, no end term, and no end date, then use the end date of the start term */
                            CASE
                               WHEN     SDATA.SRVC_IND_ACT_TERM <> ' '
                                    AND SDATA.SRVC_IND_ACTIVE_DT IS NULL
                                    AND SDATA.SCC_SI_END_TERM = ' '
                                    AND SDATA.SCC_SI_END_DT IS NULL
                               THEN
                                  /* If a student has a car term record for the start term specified, then if the student does not have multiple distinct billing careers in the car term record, then use that billing career. Otherwise, default to UGRD */
                                  CASE
                                     WHEN (SELECT DISTINCT 'X'
                                             FROM PS_STDNT_CAR_TERM
                                            WHERE     EMPLID = SDATA.EMPLID
                                                  AND STRM =
                                                         SDATA.SRVC_IND_ACT_TERM) =
                                             'X'
                                     THEN
                                        CASE
                                           WHEN (SELECT BILLING_CAREER_COUNT
                                                   FROM MultipleBillingCareers
                                                  WHERE     SDATA.EMPLID =
                                                               EMPLID
                                                        AND STRM =
                                                               SDATA.SRVC_IND_ACT_TERM) =
                                                   1
                                           THEN
                                              (SELECT TERM_END_DT
                                                 FROM PS_TERM_TBL
                                                WHERE     INSTITUTION =
                                                             SDATA.INSTITUTION
                                                      AND STRM =
                                                             SDATA.SRVC_IND_ACT_TERM
                                                      AND ACAD_CAREER =
                                                             (SELECT DISTINCT
                                                                     BILLING_CAREER
                                                                FROM PS_STDNT_CAR_TERM
                                                               WHERE     EMPLID =
                                                                            SDATA.EMPLID
                                                                     AND STRM =
                                                                            SDATA.SRVC_IND_ACT_TERM
                                                                     AND INSTITUTION =
                                                                            SDATA.INSTITUTION))
                                           ELSE
                                              (SELECT TERM_END_DT
                                                 FROM PS_TERM_TBL
                                                WHERE     INSTITUTION =
                                                             SDATA.INSTITUTION
                                                      AND STRM =
                                                             SDATA.SRVC_IND_ACT_TERM
                                                      AND ACAD_CAREER =
                                                             'UGRD')
                                        END
                                     ELSE
                                        (SELECT TERM_END_DT
                                           FROM PS_TERM_TBL
                                          WHERE     INSTITUTION =
                                                       SDATA.INSTITUTION
                                                AND STRM =
                                                       SDATA.SRVC_IND_ACT_TERM
                                                AND ACAD_CAREER = 'UGRD')
                                  END
                               ELSE
                                  NULL
                            END
                      END
                END
          END
             AS STOP_DATE,
--          CASE WHEN SDATA.AMOUNT = 0 THEN NULL ELSE SDATA.AMOUNT END
--             AS AMOUNT_OWED, /* removing as per Jessia Julicher on 4/6/21 */
          NULL AS AMOUNT_OWED,
          /* strip HTML Tags/Entities */
          (SELECT REGEXP_REPLACE (
                     REGEXP_REPLACE (
                        REGEXP_REPLACE (
                           REGEXP_REPLACE (
                              REGEXP_REPLACE (
                                 REGEXP_REPLACE (
                                    REGEXP_REPLACE (TO_CHAR (DESCRLONG),
                                                    '<(.|\n)*?>',
                                                    ''),
                                    '&' || 'nbsp;|' || '&' || '#160;',
                                    ' '),
                                 '&' || 'lt|' || '&' || '#60;',
                                 '<'),
                              '&' || 'gt;|' || '&' || '#62;',
                              '>'),
                           '&' || 'amp;|' || '&' || '#38;',
                           '&'),
                        '&' || 'quot;|' || '&' || '#34;',
                        '"'),
                     '&' || 'apos;|' || '&' || '#39;',
                     '''')
             FROM MaxDatedSrvcIndRsn RSN
            WHERE     RSN.SRVC_IND_CD = SDATA.SRVC_IND_CD
                  AND RSN.SRVC_IND_REASON = SDATA.SRVC_IND_REASON)
             AS REASON
     FROM PS_SRVC_IND_DATA_V SDATA
          JOIN CMP_POPULATION_CURRENT_V CPOP ON SDATA.EMPLID = CPOP.EMPLID
          JOIN CMP_OSF_HCL_HOLD_CD_LKP_V HOLDV
             ON HOLDV.HOLD_CD =
                   (SDATA.SRVC_IND_CD || '-' || SDATA.SRVC_IND_REASON)
    WHERE POS_SRVC_INDICATOR = 'N'