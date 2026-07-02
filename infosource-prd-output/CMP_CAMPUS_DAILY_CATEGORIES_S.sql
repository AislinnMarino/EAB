SELECT /*+ PARALLEL(4) */
            -- The scrub view logic is supported by the Student Solutions Team
 -- Data Access and Reporting suppots the Dataload and will report any issues to the Student Solutions Team
          population.emplid AS student_id, a.stdnt_group AS category_id
     FROM ps_rpt.ps_stdnt_grps_hist_v a                  -- STUDENT POPULATION
          JOIN ps_rpt.cmp_population_current_v population
              ON a.emplid = population.emplid
    WHERE     1 = 1
          AND a.EFFDT =
              (SELECT MAX (EFFDT)
                 FROM ps_rpt.PS_STDNT_GRPS_HIST_V
                WHERE     EMPLID = a.EMPLID
                      AND EFFDT <= SYSDATE
                      AND STDNT_GROUP = a.STDNT_GROUP)
          AND a.EFF_STATUS = 'A'
          AND a.STDNT_GROUP IN ('AAS',
                                'ACE',
                                'ACEB',
                                'ACKR',
                                'ADD',
                                'AEP',
                                'ALLC',
                                'ATBM',
                                'ATBW',
                                'ATC',
                                'ATE',
                                'ATF',
                                'ATI',
                                'ATKM',
                                'ATKW',
                                'ATMM',
                                'ATMW',
                                'ATRM',
                                'ATRW',
                                'ATS',
                                'ATV',
                                'ATW',
                                'ATXM',
                                'ATXW',
                                'ATYM',
                                'ATYW',
                                'BITS',
                                'CLTR',
                                'CSBR',
                                'CSPM',
                                'CSTP',
                                'E100',
                                'E105',
                                'E411',
                                'EASC',
                                'EXCS',
                                'ESI',
                                'FGN',
                                'FGPM',
                                'FIF',
                                'FYAW',
                                'GOP',
                                'GSP',
                                'GSF',
                                'HON',
                                'HONA',
                                'HONP',
                                'HONR',
                                'LSAM',
                                'MCNA',
				'MSU',
                                'NSPK',
                                'NUR2',
				'PLG',
                                'PHG',
                                'PHI',
                                'PHO',
                                'PPHM',
                                'PRFL',
                                'PRZ',
                                'PTE',
                                'RBH',
                                'S105',
                                'SSP',
                                'SBFG',
                                'SBFG',
                                'SRGR',
                                'SUBR',
                                'SUPM',
                                'SSS',
                                'SYB',
                                'SYS',
                                'TRCE',
                                'UBSR',
                                'UBTH',
                                'W100',
                                'W105',
                                'W411',
                                'WSE',
                                '1EAS')
    UNION
    SELECT population.EMPLID AS STUDENT_ID, a.STDNT_GROUP AS CATEGORY_ID
      FROM ps_rpt.PS_STDNT_GRPS_HIST_V  a
           -- STUDENT POPULATION
           JOIN PS_RPT.CMP_POPULATION_CURRENT_V population
               ON a.EMPLID = population.EMPLID
     WHERE     1 = 1
           AND a.EFFDT =
               (SELECT MAX (EFFDT)
                  FROM ps_rpt.PS_STDNT_GRPS_HIST_V
                 WHERE     EMPLID = a.EMPLID
                       AND EFFDT <= SYSDATE
                       AND STDNT_GROUP = a.STDNT_GROUP)
           AND a.EFF_STATUS = 'A'
           AND a.STDNT_GROUP LIKE 'Z%'
    UNION
    (SELECT population.EMPLID AS STUDENT_ID, 'INTL' AS CATEGORY_ID
       FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
            JOIN ps_rpt.PS_CITIZENSHIP_v ctzn
                ON population.EMPLID = ctzn.EMPLID
      WHERE 1 = 1 AND ctzn.country = 'USA' AND ctzn.citizenship_status = '4')
    UNION
    (                                            -- 'Underrepresented Minority
     SELECT population.EMPLID AS STUDENT_ID, 'URM' AS CATEGORY_ID
       FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
            JOIN ps_rpt.ps_divers_ethnic_v a ON population.EMPLID = a.EMPLID
      WHERE     1 = 1
            AND a.primary_indicator = 'Y'
            AND a.ethnic_grp_cd NOT IN ('05',
                                        '07',
                                        '08',
                                        '09',
                                        '10',
                                        '11'))
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'DORM' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (/*find any INRM row with current date between check in/ check out dates*/
            SELECT DISTINCT a.TERM_SESSION_DESCR,
                            a.PERSON_NUMBER,
                            a.ENTRY_STATUS_ABBR,
                            a.CHECK_IN_DATE,
                            a.CHECK_OUT_DATE,
                            a.CHECK_IN_DATE_ACTUAL,
                            a.CHECK_OUT_DATE_ACTUAL
              FROM CLL.RESID_TERM_BOOKING_V a
             WHERE     a.ENTRY_STATUS_ABBR = 'INRM'
                   AND SYSDATE BETWEEN a.CHECK_IN_DATE AND a.CHECK_OUT_DATE
                   AND a.PERSON_NUMBER IS NOT NULL
                   AND a.CANCELLED_DATE IS NULL
            /*WHEN the current date falls between a Fall end of term date and the beginning of term date of the subsequent spring, find RESV rows in that subsequent spring*/
            UNION
            SELECT a.TERM_SESSION_DESCR,
                   a.PERSON_NUMBER,
                   a.ENTRY_STATUS_ABBR,
                   a.CHECK_IN_DATE,
                   a.CHECK_OUT_DATE,
                   a.CHECK_IN_DATE_ACTUAL,
                   a.CHECK_OUT_DATE_ACTUAL
              FROM CLL.RESID_TERM_BOOKING_V  a
                   INNER JOIN
                   (SELECT f.*
                      FROM /*find the next spring term for any fall term*/
                            (SELECT t.INSTITUTION,
                                    t.ACAD_CAREER,
                                    t.STRM,
                                    LEAD (t.STRM)
                                        OVER (
                                            PARTITION BY t.INSTITUTION,
                                                         t.ACAD_CAREER
                                            ORDER BY t.STRM)    NXT_TRM,
                                    LEAD (t.TERM_BEGIN_DT)
                                        OVER (
                                            PARTITION BY t.INSTITUTION,
                                                         t.ACAD_CAREER
                                            ORDER BY t.STRM)    NXT_TRM_BOT,
                                    t.DESCR,
                                    t.DESCRSHORT,
                                    t.TERM_BEGIN_DT,
                                    t.TERM_END_DT,
                                    t.SESSION_CODE,
                                    t.TERM_CATEGORY
                               FROM PS_RPT.PS_TERM_TBL_V t
                              WHERE     t.INSTITUTION = 'UBFLO'
                                    AND t.TERM_CATEGORY <> 'I'
                                    AND t.ACAD_CAREER IN
                                            ('UGRD', 'GRAD', 'PHRM')) f
                     WHERE f.STRM LIKE '___9') INTR
                       /*find the RESV rows of the subsequent spring*/
                       ON     (SYSDATE) BETWEEN INTR.TERM_END_DT
                                            AND INTR.NXT_TRM_BOT
                          AND a.TERM_SESSION_DESCR LIKE '%Spring%'
             WHERE     (   SUBSTR (a.TERM_SESSION_DESCR, 1, 1)
                        || SUBSTR (a.TERM_SESSION_DESCR, 3, 2)
                        || '1') =
                       INTR.NXT_TRM
                   AND a.ENTRY_STATUS_ABBR = 'RESV'
                   AND a.PERSON_NUMBER IS NOT NULL
                   AND a.CANCELLED_DATE IS NULL) d
               ON population.EMPLID = d.PERSON_NUMBER
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'COMM' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V population
     WHERE population.EMPLID NOT IN
               (SELECT DISTINCT a.PERSON_NUMBER
                  FROM CLL.RESID_TERM_BOOKING_V a
                 WHERE     a.ENTRY_STATUS_ABBR = 'INRM'
                       AND SYSDATE BETWEEN a.CHECK_IN_DATE
                                       AND a.CHECK_OUT_DATE
                       AND a.PERSON_NUMBER IS NOT NULL
                       AND a.CANCELLED_DATE IS NULL
                /*WHEN the current date falls between a Fall end of term date and the beginning of term date of the subsequent spring, find RESV rows in that subsequent spring*/
                UNION
                SELECT a.PERSON_NUMBER
                  FROM CLL.RESID_TERM_BOOKING_V  a
                       INNER JOIN
                       (SELECT f.*
                          FROM /*find the next spring term for any fall term*/
                                (SELECT t.INSTITUTION,
                                        t.ACAD_CAREER,
                                        t.STRM,
                                        LEAD (t.STRM)
                                            OVER (
                                                PARTITION BY t.INSTITUTION,
                                                             t.ACAD_CAREER
                                                ORDER BY t.STRM)
                                            NXT_TRM,
                                        LEAD (t.TERM_BEGIN_DT)
                                            OVER (
                                                PARTITION BY t.INSTITUTION,
                                                             t.ACAD_CAREER
                                                ORDER BY t.STRM)
                                            NXT_TRM_BOT,
                                        t.DESCR,
                                        t.DESCRSHORT,
                                        t.TERM_BEGIN_DT,
                                        t.TERM_END_DT,
                                        t.SESSION_CODE,
                                        t.TERM_CATEGORY
                                   FROM PS_RPT.PS_TERM_TBL_V t
                                  WHERE     t.INSTITUTION = 'UBFLO'
                                        AND t.TERM_CATEGORY <> 'I'
                                        AND t.ACAD_CAREER IN
                                                ('UGRD', 'GRAD', 'PHRM')) f
                         WHERE f.STRM LIKE '___9') INTR
                           /*find the RESV rows of the subsequent spring*/
                           ON     (SYSDATE) BETWEEN INTR.TERM_END_DT
                                                AND INTR.NXT_TRM_BOT
                              AND a.TERM_SESSION_DESCR LIKE '%Spring%'
                 WHERE     (   SUBSTR (a.TERM_SESSION_DESCR, 1, 1)
                            || SUBSTR (a.TERM_SESSION_DESCR, 3, 2)
                            || '1') =
                           INTR.NXT_TRM
                       AND a.ENTRY_STATUS_ABBR = 'RESV'
                       AND a.PERSON_NUMBER IS NOT NULL
                       AND a.CANCELLED_DATE IS NULL)
    UNION
    (                                                      --Transfer Students
     SELECT population.EMPLID AS STUDENT_ID, 'TRNS' AS CATEGORY_ID
       FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
            JOIN ps_rpt.PS_ADM_APPL_DATA_V a ON population.EMPLID = a.EMPLID
      WHERE     1 = 1
            AND a.ADMIT_TYPE = '010'
            AND a.ADM_APPL_DT = (SELECT MAX (ADM_APPL_DT)
                                   FROM ps_rpt.PS_ADM_APPL_DATA_V
                                  WHERE EMPLID = a.EMPLID))
    UNION                                              --vet or active service
    SELECT population.EMPLID AS STUDENT_ID, 'VET' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN (  SELECT m.EMPLID, MAX (m.STRM) max_mil
                           FROM ps_rpt.UB_MILITARY_AFFILIATIONS_v m
                          WHERE (m.VETERAN = '1' OR m.ACTIVE_SERVICE = '1')
                       GROUP BY m.EMPLID) m
               ON     m.EMPLID = population.EMPLID
                  AND m.max_mil <= population.STRM
    UNION                                                 -- TAP Certification
    SELECT DISTINCT population.EMPLID AS STUDENT_ID, 'TAP' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN PS_RPT.PS_STDNT_DISB_VW1_V tap
               ON (population.emplid = tap.emplid)
           INNER JOIN PS_RPT.PS_UB_TERM_VAL_TBL_V T
               ON ((tap.STRM = T.STRM) AND (tap.ACAD_CAREER = T.ACAD_CAREER))
     WHERE     T.UB_TERM_DESCR LIKE 'Current/Upcoming%'
           AND tap.ITEM_TYPE IN ('000090200006',
                                 '000090200007',
                                 '000090200010',
                                 '000090200015',
                                 '000090200020')
           AND tap.OFFER_BALANCE > '0'
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'SPOK' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (SELECT t.SOURCEKEY,
                   LAG (t.SOURCEKEY) OVER (ORDER BY t.SOURCEKEY)    prev_term
              FROM ps_rpt.LOK_TERM_V t
             WHERE t.TERMCATEGORY = 'Regular Term') t
               ON population.STRM = t.SOURCEKEY
           JOIN
           (SELECT a.EMPLID, a.STRM
              FROM ps_rpt.PS_SFA_SAP_STDNT_V A
             WHERE     a.ACAD_CAREER = 'UGRD'
                   AND (   (    a.SFA_SAP_STAT_CALC IN ('BRDL',
                                                        'DUAL',
                                                        'MEET',
                                                        'PLAN',
                                                        'SBSQ',
                                                        'TRAN')
                            AND a.SFA_SAP_STATUS = ' ')
                        OR (a.SFA_SAP_STATUS IN ('BRDL',
                                                 'DUAL',
                                                 'MEET',
                                                 'PLAN',
                                                 'SBSQ',
                                                 'TRAN')))
                   AND a.PROCESS_DTTM =
                       (SELECT MAX (b.PROCESS_DTTM)
                          FROM ps_rpt.PS_SFA_SAP_STDNT_V B
                         WHERE     a.INSTITUTION = b.INSTITUTION
                               AND a.EMPLID = b.EMPLID
                               AND a.ACAD_CAREER = b.ACAD_CAREER)) met
               ON     met.EMPLID = population.EMPLID
                  AND (met.STRM = population.STRM OR met.STRM = t.prev_term)
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'SPWN' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (SELECT t.SOURCEKEY,
                   LAG (t.SOURCEKEY) OVER (ORDER BY t.SOURCEKEY)    prev_term
              FROM ps_rpt.LOK_TERM_V t
             WHERE t.TERMCATEGORY = 'Regular Term') t
               ON population.STRM = t.SOURCEKEY
           JOIN
           (SELECT a.EMPLID, a.STRM
              FROM ps_rpt.PS_SFA_SAP_STDNT_V A
             WHERE     a.ACAD_CAREER = 'UGRD'
                   AND (   (    a.SFA_SAP_STAT_CALC = 'WARN'
                            AND a.SFA_SAP_STATUS = ' ')
                        OR (a.SFA_SAP_STATUS = 'WARN'))
                   AND a.PROCESS_DTTM =
                       (SELECT MAX (b.PROCESS_DTTM)
                          FROM ps_rpt.PS_SFA_SAP_STDNT_V B
                         WHERE     a.INSTITUTION = b.INSTITUTION
                               AND a.EMPLID = b.EMPLID
                               AND a.ACAD_CAREER = b.ACAD_CAREER)) wrn
               ON     wrn.EMPLID = population.EMPLID
                  AND (wrn.STRM = population.STRM OR wrn.STRM = t.prev_term)
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'SPPB' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (SELECT t.SOURCEKEY,
                   LAG (t.SOURCEKEY) OVER (ORDER BY t.SOURCEKEY)    prev_term
              FROM ps_rpt.LOK_TERM_V t
             WHERE t.TERMCATEGORY = 'Regular Term') t
               ON population.STRM = t.SOURCEKEY
           JOIN
           (SELECT a.EMPLID, a.STRM
              FROM ps_rpt.PS_SFA_SAP_STDNT_V A
             WHERE     a.ACAD_CAREER = 'UGRD'
                   AND (   (    a.SFA_SAP_STAT_CALC = 'PROB'
                            AND a.SFA_SAP_STATUS = ' ')
                        OR (a.SFA_SAP_STATUS = 'PROB'))
                   AND a.PROCESS_DTTM =
                       (SELECT MAX (b.PROCESS_DTTM)
                          FROM ps_rpt.PS_SFA_SAP_STDNT_V B
                         WHERE     a.INSTITUTION = b.INSTITUTION
                               AND a.EMPLID = b.EMPLID
                               AND a.ACAD_CAREER = b.ACAD_CAREER)) prb
               ON     prb.EMPLID = population.EMPLID
                  AND (prb.STRM = population.STRM OR prb.STRM = t.prev_term)
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'SPNO' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (SELECT t.SOURCEKEY,
                   LAG (t.SOURCEKEY) OVER (ORDER BY t.SOURCEKEY)    prev_term
              FROM ps_rpt.LOK_TERM_V t
             WHERE t.TERMCATEGORY = 'Regular Term') t
               ON population.STRM = t.SOURCEKEY
           JOIN
           (SELECT a.EMPLID, a.STRM
              FROM ps_rpt.PS_SFA_SAP_STDNT_V A
             WHERE     a.ACAD_CAREER = 'UGRD'
                   AND (   (    a.SFA_SAP_STAT_CALC IN ('FAIL', 'DEND')
                            AND a.SFA_SAP_STATUS = ' ')
                        OR (a.SFA_SAP_STATUS IN ('FAIL', 'DEND')))
                   AND a.PROCESS_DTTM =
                       (SELECT MAX (b.PROCESS_DTTM)
                          FROM ps_rpt.PS_SFA_SAP_STDNT_V B
                         WHERE     a.INSTITUTION = b.INSTITUTION
                               AND a.EMPLID = b.EMPLID
                               AND a.ACAD_CAREER = b.ACAD_CAREER)) nmt
               ON     nmt.EMPLID = population.EMPLID
                  AND (nmt.STRM = population.STRM OR nmt.STRM = t.prev_term)
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'EPAC' AS CATEGORY_ID
      FROM PS_RPT.PS_STDNT_ADVR_HIST_V  a
           JOIN PS_RPT.CMP_POPULATION_CURRENT_V population
               ON a.EMPLID = population.EMPLID
     WHERE     a.COMMITTEE_ID IN ('SASEXP', 'EPAC')
           AND a.EFFDT =
               (SELECT MAX (b.effdt)
                  FROM PS_RPT.PS_STDNT_ADVR_HIST_V b
                 WHERE a.emplid = b.emplid AND a.institution = b.institution)
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'CAS' AS CATEGORY_ID
      FROM PS_RPT.PS_STDNT_ADVR_HIST_V  a
           JOIN PS_RPT.CMP_POPULATION_CURRENT_V population
               ON a.EMPLID = population.EMPLID
     WHERE     a.COMMITTEE_ID IN ('CAS')
           AND a.EFFDT =
               (SELECT MAX (b.effdt)
                  FROM PS_RPT.PS_STDNT_ADVR_HIST_V b
                 WHERE a.emplid = b.emplid AND a.institution = b.institution)
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'ATNO' AS CATEGORY_ID
      FROM PS_RPT.PS_STDNT_GRPS_HIST_V  A
           INNER JOIN PS_RPT.CMP_POPULATION_CURRENT_V population
               ON A.EMPLID = population.EMPLID
     WHERE     1 = 1
           AND (A.EFFDT =
                (SELECT MAX (A_ED.EFFDT)
                   FROM PS_RPT.PS_STDNT_GRPS_HIST_V A_ED
                  WHERE     A.EMPLID = A_ED.EMPLID
                        AND A.INSTITUTION = A_ED.INSTITUTION
                        AND A.STDNT_GROUP = A_ED.STDNT_GROUP
                        AND A_ED.EFFDT <= SYSDATE))
           AND A.INSTITUTION = 'UBFLO'
           AND A.STDNT_GROUP = 'ATNO'
           AND A.EFF_STATUS = 'A'
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'ATHL' AS CATEGORY_ID
      FROM PS_RPT.PS_STDNT_GRPS_HIST_V  A
           INNER JOIN PS_RPT.CMP_POPULATION_CURRENT_V population
               ON A.EMPLID = population.EMPLID
     WHERE     1 = 1
           AND (    A.EFFDT =
                    (SELECT MAX (A_ED.EFFDT)
                       FROM PS_RPT.PS_STDNT_GRPS_HIST_V A_ED
                      WHERE     A.EMPLID = A_ED.EMPLID
                            AND A.INSTITUTION = A_ED.INSTITUTION
                            AND A.STDNT_GROUP = A_ED.STDNT_GROUP
                            AND A_ED.EFFDT <= SYSDATE)
                AND A.INSTITUTION = 'UBFLO'
                AND A.STDNT_GROUP = 'ATHL'
                AND A.EFF_STATUS = 'A'
                AND NOT EXISTS
                        (SELECT 'X'
                           FROM PS_RPT.PS_STDNT_GRPS_HIST_V B
                          WHERE     B.EFFDT =
                                    (SELECT MAX (B_ED.EFFDT)
                                       FROM PS_RPT.PS_STDNT_GRPS_HIST_V B_ED
                                      WHERE     B.EMPLID = B_ED.EMPLID
                                            AND B.INSTITUTION =
                                                B_ED.INSTITUTION
                                            AND B.STDNT_GROUP =
                                                B_ED.STDNT_GROUP
                                            AND B_ED.EFFDT <= SYSDATE)
                                AND A.EMPLID = B.EMPLID
                                AND B.STDNT_GROUP = 'ATNO'
                                AND B.EFF_STATUS = 'A'))
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'BUE' AS CATEGORY_ID
      FROM PS_RPT.PS_STDNT_ADVR_HIST_V  a
           JOIN PS_RPT.CMP_POPULATION_CURRENT_V population
               ON a.EMPLID = population.EMPLID
     WHERE     a.COMMITTEE_ID = 'BUE'
           AND a.EFFDT =
               (SELECT MAX (b.effdt)
                  FROM PS_RPT.PS_STDNT_ADVR_HIST_V b
                 WHERE     a.emplid = b.emplid
                       AND a.institution = b.institution
                       AND a.advisor_role = b.advisor_role)
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'OEPG' AS CATEGORY_ID
      FROM PS_RPT.PS_STDNT_ADVR_HIST_V  a
           JOIN PS_RPT.CMP_POPULATION_CURRENT_V population
               ON a.EMPLID = population.EMPLID
     WHERE     a.COMMITTEE_ID = 'OEPG'
           AND a.EFFDT =
               (SELECT MAX (b.effdt)
                  FROM PS_RPT.PS_STDNT_ADVR_HIST_V b
                 WHERE     a.emplid = b.emplid
                       AND a.institution = b.institution
                       AND a.advisor_role = b.advisor_role)
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'MGPO' AS CATEGORY_ID
      FROM PS_RPT.PS_STDNT_ADVR_HIST_V  a
           JOIN PS_RPT.CMP_POPULATION_CURRENT_V population
               ON a.EMPLID = population.EMPLID
     WHERE     a.COMMITTEE_ID = 'MGPO'
           AND a.EFFDT =
               (SELECT MAX (b.effdt)
                  FROM PS_RPT.PS_STDNT_ADVR_HIST_V b
                 WHERE     a.emplid = b.emplid
                       AND a.institution = b.institution
                       AND a.advisor_role = b.advisor_role)
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'EOP' AS CATEGORY_ID
      FROM PS_RPT.PS_STDNT_GRPS_HIST_V  A
           INNER JOIN PS_RPT.CMP_POPULATION_CURRENT_V population
               ON A.EMPLID = population.EMPLID
     WHERE     1 = 1
           AND (A.EFFDT =
                (SELECT MAX (A_ED.EFFDT)
                   FROM PS_RPT.PS_STDNT_GRPS_HIST_V A_ED
                  WHERE     A.EMPLID = A_ED.EMPLID
                        AND A.INSTITUTION = A_ED.INSTITUTION
                        AND A.STDNT_GROUP = A_ED.STDNT_GROUP
                        AND A_ED.EFFDT <= SYSDATE))
           AND A.INSTITUTION = 'UBFLO'
           AND A.STDNT_GROUP = 'EOPS'
           AND A.EFF_STATUS = 'A'
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'EPACTR' AS CATEGORY_ID
      FROM PS_RPT.PS_STDNT_ADVR_HIST_V  a
           JOIN PS_RPT.CMP_POPULATION_CURRENT_V population
               ON a.EMPLID = population.EMPLID
     WHERE     a.COMMITTEE_ID = 'EPACTR'
           AND a.EFFDT =
               (SELECT MAX (b.effdt)
                  FROM PS_RPT.PS_STDNT_ADVR_HIST_V b
                 WHERE     a.emplid = b.emplid
                       AND a.institution = b.institution
                       AND a.advisor_role = b.advisor_role)
    UNION
    SELECT population.EMPLID AS STUDENT_ID, A.Current_Status AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           ( --look back at current and previous enrolled terms and find the most recent admit terms by career level (UG or GR)
            SELECT A.EMPLOYEEID,
                   FIRST_VALUE (A.Admit_Status)
                       OVER (
                           PARTITION BY A.INSTITUTIONSOURCEKEY,
                                        A.EMPLOYEEID,
                                        A.CAR_LEV
                           ORDER BY A.TERMSOURCEKEY DESC, A.ADMITTERM DESC
                           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)    Current_Status
              FROM (SELECT A.INSTITUTIONSOURCEKEY,
                           A.EMPLOYEEID,
                           A.CAREERSOURCEKEY,
                           (CASE
                                WHEN A.CAREERSOURCEKEY = 'UGRD' THEN 'UG'
                                ELSE 'GR'
                            END)    CAR_LEV,
                           A.TERMSOURCEKEY,
                           A.PROGRAMSOURCEKEY,
                           A.ADMITTERM,
                           A.ADMITTYPESOURCEKEY,
                           A.ADMITTYPE,
                           T.TERMBEGINDATE,
                           (CASE
                                WHEN     A.CAREERSOURCEKEY = 'UGRD'
                                     AND A.ADMITTYPESOURCEKEY IN ('001',
                                                                  '003',
                                                                  '005',
                                                                  '006')
                                THEN
                                    'FR' || A.ADMITTERM
                                WHEN     A.CAREERSOURCEKEY = 'UGRD'
                                     AND A.ADMITTYPESOURCEKEY IN ('010')
                                THEN
                                    'TF' || A.ADMITTERM
                                WHEN     A.CAREERSOURCEKEY = 'UGRD'
                                     AND A.ADMITTYPESOURCEKEY IN ('021')
                                THEN
                                    'RE' || A.ADMITTERM
                                WHEN     A.CAREERSOURCEKEY = 'UGRD'
                                     AND A.ADMITTYPESOURCEKEY IN ('075')
                                THEN
                                    'SB' || A.ADMITTERM
                                WHEN     A.CAREERSOURCEKEY <> 'UGRD'
                                     AND A.ADMITTYPESOURCEKEY IN
                                             ('001', '002', '016')
                                THEN
                                    'GR' || A.ADMITTERM
                                ELSE
                                    'CHECK'
                            END)    Admit_Status
                      FROM PS_RPT.STUDENTTERM_V  A
                           INNER JOIN PS_RPT.LOK_TERM_V T
                               ON A.TERMSOURCEKEY = T.SOURCEKEY
                     --exclude non-degree and discontinued stacks

                     WHERE     1 = 1
                           AND A.INSTITUTIONSOURCEKEY = 'UBFLO'
                           AND A.ADMITTYPESOURCEKEY IN ('001',
                                                        '002',
                                                        '003',
                                                        '005',
                                                        '006',
                                                        '010',
                                                        '016',
                                                        '021',
                                                        '075')
                           AND A.PROGRAMSOURCEKEY NOT LIKE '__N_'
                           AND A.ENROLLEDINDICATOR = 'Enrolled'
                           AND T.TERMBEGINDATE <= SYSDATE
                           AND A.CURRENTPROGRAMSTATUSSOURCEKEY NOT IN
                                   ('DC', 'DE')) A
            --look ahead to future terms, enrolled or not, and find the next admit terms by career level (UG or GR)

            UNION
            SELECT A.EMPLOYEEID,
                   FIRST_VALUE (A.Admit_Status)
                       OVER (
                           PARTITION BY A.INSTITUTIONSOURCEKEY,
                                        A.EMPLOYEEID,
                                        A.CAR_LEV
                           ORDER BY A.TERMSOURCEKEY, A.ADMITTERM
                           ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)    Current_Status
              FROM (SELECT A.INSTITUTIONSOURCEKEY,
                           A.EMPLOYEEID,
                           A.CAREERSOURCEKEY,
                           (CASE
                                WHEN A.CAREERSOURCEKEY = 'UGRD' THEN 'UG'
                                ELSE 'GR'
                            END)    CAR_LEV,
                           A.TERMSOURCEKEY,
                           A.PROGRAMSOURCEKEY,
                           A.ADMITTERM,
                           A.ADMITTYPESOURCEKEY,
                           A.ADMITTYPE,
                           T.TERMBEGINDATE,
                           CASE
                               WHEN     A.CAREERSOURCEKEY = 'UGRD'
                                    AND A.ADMITTYPESOURCEKEY IN ('001',
                                                                 '003',
                                                                 '005',
                                                                 '006')
                               THEN
                                   'FR' || A.ADMITTERM
                               WHEN     A.CAREERSOURCEKEY = 'UGRD'
                                    AND A.ADMITTYPESOURCEKEY IN ('010')
                               THEN
                                   'TF' || A.ADMITTERM
                               WHEN     A.CAREERSOURCEKEY = 'UGRD'
                                    AND A.ADMITTYPESOURCEKEY IN ('021')
                               THEN
                                   'RE' || A.ADMITTERM
                               WHEN     A.CAREERSOURCEKEY = 'UGRD'
                                    AND A.ADMITTYPESOURCEKEY IN ('075')
                               THEN
                                   'SB' || A.ADMITTERM
                               WHEN     A.CAREERSOURCEKEY <> 'UGRD'
                                    AND A.ADMITTYPESOURCEKEY IN
                                            ('001', '002', '016')
                               THEN
                                   'GR' || A.ADMITTERM
                               ELSE
                                   'CHECK'
                           END      Admit_Status
                      FROM PS_RPT.STUDENTTERM_V  A
                           INNER JOIN PS_RPT.LOK_TERM_V T
                               ON A.TERMSOURCEKEY = T.SOURCEKEY
                     WHERE     1 = 1
                           --active future stacks only

                           AND A.INSTITUTIONSOURCEKEY = 'UBFLO'
                           AND A.ADMITTYPESOURCEKEY IN ('001',
                                                        '002',
                                                        '003',
                                                        '005',
                                                        '006',
                                                        '010',
                                                        '016',
                                                        '021',
                                                        '075')
                           ---AND A.CAREERSOURCEKEY='UGRD'
                           AND PROGRAMSTATUSSOURCEKEY = 'AC'
                           AND A.PROGRAMSOURCEKEY NOT LIKE '__N_'
                           AND T.TERMBEGINDATE > SYSDATE) A) A
               ON population.EMPLID = A.EMPLOYEEID
    UNION
    SELECT population.EMPLID AS STUDENT_ID, A.ACAD_STDG AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (SELECT A.EMPLID, A.STRM, A.ACAD_STNDNG_STAT || A.STRM ACAD_STDG
              FROM ps_rpt.PS_ACAD_STDNG_ACTN_v A
             WHERE     (A.STRM =
                        (SELECT MAX (A_TM.STRM)
                           FROM ps_rpt.PS_ACAD_STDNG_ACTN_v A_TM
                          WHERE     A.EMPLID = A_TM.EMPLID
                                AND A.ACAD_CAREER = A_TM.ACAD_CAREER
                                AND A.INSTITUTION = A_TM.INSTITUTION))
                   AND (    A.EFFDT =
                            (SELECT MAX (A_ED.EFFDT)
                               FROM ps_rpt.PS_ACAD_STDNG_ACTN_v A_ED
                              WHERE     A.EMPLID = A_ED.EMPLID
                                    AND A.ACAD_CAREER = A_ED.ACAD_CAREER
                                    AND A.INSTITUTION = A_ED.INSTITUTION
                                    AND A.STRM = A_ED.STRM
                                    AND A_ED.EFFDT <= SYSDATE)
                        AND A.EFFSEQ =
                            (SELECT MAX (A_ES.EFFSEQ)
                               FROM ps_rpt.PS_ACAD_STDNG_ACTN_v A_ES
                              WHERE     A.EMPLID = A_ES.EMPLID
                                    AND A.ACAD_CAREER = A_ES.ACAD_CAREER
                                    AND A.INSTITUTION = A_ES.INSTITUTION
                                    AND A.STRM = A_ES.STRM
                                    AND A.EFFDT = A_ES.EFFDT))
                   AND A.ACAD_STNDNG_ACTN <> ' '
                   AND A.STRM >= '2119'
                   AND A.ACAD_CAREER = 'UGRD') A
               ON population.EMPLID = A.EMPLID
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'CASC' AS CATEGORY_ID
      FROM PS_RPT.PS_STDNT_ADVR_HIST_V  a
           JOIN PS_RPT.CMP_POPULATION_CURRENT_V population
               ON a.EMPLID = population.EMPLID
     WHERE     a.COMMITTEE_ID IN ('CAS')
           AND a.EFFDT =
               (SELECT MAX (b.effdt)
                  FROM PS_RPT.PS_STDNT_ADVR_HIST_V b
                 WHERE a.emplid = b.emplid AND a.institution = b.institution)
           AND a.EMPLID IN
                   (SELECT A.EMPLOYEEID
                      FROM PS_RPT.STUDENTTERM_V  A
                           INNER JOIN PS_RPT.LOK_TERM_V T1
                               ON A.TERMSOURCEKEY = T1.SOURCEKEY
                           INNER JOIN PS_RPT.CMP_POPULATION_CURRENT_V POP
                               ON A.EMPLOYEEID = POP.EMPLID
                           INNER JOIN PS_RPT.LOK_TERM_V T2
                               ON POP.STRM = T2.SOURCEKEY
                           INNER JOIN PS_RPT.PS_STDNT_CAR_TERM_V C
                               ON     POP.EMPLID = C.EMPLID
                                  AND POP.STRM = C.STRM
                                  AND C.ACAD_CAREER = 'UGRD'
                     WHERE     1 = 1
                           AND A.INSTITUTIONSOURCEKEY = 'UBFLO'
                           AND A.TERMSOURCEKEY = A.ADMITTERM
                           AND T1.TERMBEGINDATE <= SYSDATE
                           AND T2.TERMENDDATE >= SYSDATE
                           AND A.CAREERSOURCEKEY = 'UGRD'
                           AND A.ADMITTERM = A.TERMSOURCEKEY
                           AND A.BILLINGCAREER = A.CAREERSOURCEKEY
                           AND A.ENROLLEDINDICATOR = 'Enrolled'
                           AND A.CURRENTPROGRAMSTATUSSOURCEKEY IN
                                   ('AC', 'LA')
                           AND A.PROGRAMSOURCEKEY NOT LIKE '__N_')
    UNION
    SELECT DISTINCT population.EMPLID AS STUDENT_ID, 'COMP' AS CATEGORY_ID ---Undergrad Degree Completed
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           JOIN ps_rpt.DEGREE_APPLICANTS_AWARDEES_V d
               ON population.EMPLID = d.EMPLOYEEID
     WHERE 1 = 1 AND d.DEGR_STAT = 'AW' AND d.CAREER = 'UGRD'
    UNION
    SELECT DISTINCT
           population.EMPLID AS STUDENT_ID, 'DEGA' || d.TERM AS CATEGORY_ID ---Undergrad applying for degree
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           JOIN
           (SELECT a.*, t.DESCRIPTION, t.TERMENDDATE
              FROM ps_rpt.DEGREE_APPLICANTS_AWARDEES_V  a
                   INNER JOIN ps_rpt.LOK_TERM_V t ON a.TERM = t.SOURCEKEY
             WHERE     1 = 1
                   AND a.DEGR_STAT NOT IN ('DN', 'AW')
                   AND a.CAREER = 'UGRD'
                   AND MONTHS_BETWEEN ((t.TERMENDDATE + 60), SYSDATE) BETWEEN 0
                                                                          AND 9)
           d
               ON population.EMPLID = d.EMPLOYEEID
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'LOA_U' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (SELECT DISTINCT A.EMPLID,
                            A.ACAD_CAREER,
                            A.PRV_ACT,
                            A.EFFDT,
                            A.PRV_ACT_DT
              FROM (SELECT A.EMPLID,
                           A.ACAD_CAREER,
                           A.STDNT_CAR_NBR,
                           A.EFFDT,
                           A.EFFSEQ,
                           A.INSTITUTION,
                           A.ACAD_PROG,
                           A.PROG_STATUS,
                           A.PROG_ACTION,
                           LAG (A.PROG_ACTION)
                               OVER (
                                   PARTITION BY A.EMPLID,
                                                A.ACAD_CAREER,
                                                A.STDNT_CAR_NBR
                                   ORDER BY A.EFFDT, A.EFFSEQ)    PRV_ACT,
                           LAG (A.EFFDT)
                               OVER (
                                   PARTITION BY A.EMPLID,
                                                A.ACAD_CAREER,
                                                A.STDNT_CAR_NBR
                                   ORDER BY A.EFFDT, A.EFFSEQ)    PRV_ACT_DT,
                           LAG (A.EFFSEQ)
                               OVER (
                                   PARTITION BY A.EMPLID,
                                                A.ACAD_CAREER,
                                                A.STDNT_CAR_NBR
                                   ORDER BY A.EFFDT, A.EFFSEQ)    PRV_ACT_SQ,
                           A.ACTION_DT,
                           A.PROG_REASON
                      FROM ps_rpt.PS_ACAD_PROG_v A
                     WHERE     A.PROG_ACTION IN ('LEAV', 'RLOA')
                           AND A.ACTION_DT <>
                               TO_DATE ('1901-01-01', 'YYYY-MM-DD')) A
             WHERE     1 = 1
                   AND A.ACAD_CAREER = 'UGRD'
                   AND A.PRV_ACT IS NOT NULL
                   AND A.EFFDT > SYSDATE
                   AND A.PRV_ACT_DT <= SYSDATE) A
               ON population.EMPLID = A.EMPLID
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'LOA_G' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (SELECT DISTINCT A.EMPLID,
                            A.ACAD_CAREER,
                            A.PRV_ACT,
                            A.EFFDT,
                            A.PRV_ACT_DT
              FROM (SELECT A.EMPLID,
                           A.ACAD_CAREER,
                           A.STDNT_CAR_NBR,
                           A.EFFDT,
                           A.EFFSEQ,
                           A.INSTITUTION,
                           A.ACAD_PROG,
                           A.PROG_STATUS,
                           A.PROG_ACTION,
                           LAG (A.PROG_ACTION)
                               OVER (
                                   PARTITION BY A.EMPLID,
                                                A.ACAD_CAREER,
                                                A.STDNT_CAR_NBR
                                   ORDER BY A.EFFDT, A.EFFSEQ)    PRV_ACT,
                           LAG (A.EFFDT)
                               OVER (
                                   PARTITION BY A.EMPLID,
                                                A.ACAD_CAREER,
                                                A.STDNT_CAR_NBR
                                   ORDER BY A.EFFDT, A.EFFSEQ)    PRV_ACT_DT,
                           LAG (A.EFFSEQ)
                               OVER (
                                   PARTITION BY A.EMPLID,
                                                A.ACAD_CAREER,
                                                A.STDNT_CAR_NBR
                                   ORDER BY A.EFFDT, A.EFFSEQ)    PRV_ACT_SQ,
                           A.ACTION_DT,
                           A.PROG_REASON
                      FROM ps_rpt.PS_ACAD_PROG_v A
                     WHERE     A.PROG_ACTION IN ('LEAV', 'RLOA')
                           AND A.ACTION_DT <>
                               TO_DATE ('1901-01-01', 'YYYY-MM-DD')) A
             WHERE     1 = 1
                   AND A.ACAD_CAREER = 'GRAD'
                   AND A.PRV_ACT IS NOT NULL
                   AND A.EFFDT > SYSDATE
                   AND A.PRV_ACT_DT <= SYSDATE) A
               ON population.EMPLID = A.EMPLID
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'LOA_L' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (SELECT DISTINCT A.EMPLID,
                            A.ACAD_CAREER,
                            A.PRV_ACT,
                            A.EFFDT,
                            A.PRV_ACT_DT
              FROM (SELECT A.EMPLID,
                           A.ACAD_CAREER,
                           A.STDNT_CAR_NBR,
                           A.EFFDT,
                           A.EFFSEQ,
                           A.INSTITUTION,
                           A.ACAD_PROG,
                           A.PROG_STATUS,
                           A.PROG_ACTION,
                           LAG (A.PROG_ACTION)
                               OVER (
                                   PARTITION BY A.EMPLID,
                                                A.ACAD_CAREER,
                                                A.STDNT_CAR_NBR
                                   ORDER BY A.EFFDT, A.EFFSEQ)    PRV_ACT,
                           LAG (A.EFFDT)
                               OVER (
                                   PARTITION BY A.EMPLID,
                                                A.ACAD_CAREER,
                                                A.STDNT_CAR_NBR
                                   ORDER BY A.EFFDT, A.EFFSEQ)    PRV_ACT_DT,
                           LAG (A.EFFSEQ)
                               OVER (
                                   PARTITION BY A.EMPLID,
                                                A.ACAD_CAREER,
                                                A.STDNT_CAR_NBR
                                   ORDER BY A.EFFDT, A.EFFSEQ)    PRV_ACT_SQ,
                           A.ACTION_DT,
                           A.PROG_REASON
                      FROM ps_rpt.PS_ACAD_PROG_v A
                     WHERE     A.PROG_ACTION IN ('LEAV', 'RLOA')
                           AND A.ACTION_DT <>
                               TO_DATE ('1901-01-01', 'YYYY-MM-DD')) A
             WHERE     1 = 1
                   AND A.ACAD_CAREER = 'LAW'
                   AND A.PRV_ACT IS NOT NULL
                   AND A.EFFDT > SYSDATE
                   AND A.PRV_ACT_DT <= SYSDATE) A
               ON population.EMPLID = A.EMPLID
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'LOA_P' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (SELECT DISTINCT A.EMPLID,
                            A.ACAD_CAREER,
                            A.PRV_ACT,
                            A.EFFDT,
                            A.PRV_ACT_DT
              FROM (SELECT A.EMPLID,
                           A.ACAD_CAREER,
                           A.STDNT_CAR_NBR,
                           A.EFFDT,
                           A.EFFSEQ,
                           A.INSTITUTION,
                           A.ACAD_PROG,
                           A.PROG_STATUS,
                           A.PROG_ACTION,
                           LAG (A.PROG_ACTION)
                               OVER (
                                   PARTITION BY A.EMPLID,
                                                A.ACAD_CAREER,
                                                A.STDNT_CAR_NBR
                                   ORDER BY A.EFFDT, A.EFFSEQ)    PRV_ACT,
                           LAG (A.EFFDT)
                               OVER (
                                   PARTITION BY A.EMPLID,
                                                A.ACAD_CAREER,
                                                A.STDNT_CAR_NBR
                                   ORDER BY A.EFFDT, A.EFFSEQ)    PRV_ACT_DT,
                           LAG (A.EFFSEQ)
                               OVER (
                                   PARTITION BY A.EMPLID,
                                                A.ACAD_CAREER,
                                                A.STDNT_CAR_NBR
                                   ORDER BY A.EFFDT, A.EFFSEQ)    PRV_ACT_SQ,
                           A.ACTION_DT,
                           A.PROG_REASON
                      FROM ps_rpt.PS_ACAD_PROG_v A
                     WHERE     A.PROG_ACTION IN ('LEAV', 'RLOA')
                           AND A.ACTION_DT <>
                               TO_DATE ('1901-01-01', 'YYYY-MM-DD')) A
             WHERE     1 = 1
                   AND A.ACAD_CAREER = 'PHRM'
                   AND A.PRV_ACT IS NOT NULL
                   AND A.EFFDT > SYSDATE
                   AND A.PRV_ACT_DT <= SYSDATE) A
               ON population.EMPLID = A.EMPLID
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'LOA_D' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (SELECT DISTINCT A.EMPLID,
                            A.ACAD_CAREER,
                            A.PRV_ACT,
                            A.EFFDT,
                            A.PRV_ACT_DT
              FROM (SELECT A.EMPLID,
                           A.ACAD_CAREER,
                           A.STDNT_CAR_NBR,
                           A.EFFDT,
                           A.EFFSEQ,
                           A.INSTITUTION,
                           A.ACAD_PROG,
                           A.PROG_STATUS,
                           A.PROG_ACTION,
                           LAG (A.PROG_ACTION)
                               OVER (
                                   PARTITION BY A.EMPLID,
                                                A.ACAD_CAREER,
                                                A.STDNT_CAR_NBR
                                   ORDER BY A.EFFDT, A.EFFSEQ)    PRV_ACT,
                           LAG (A.EFFDT)
                               OVER (
                                   PARTITION BY A.EMPLID,
                                                A.ACAD_CAREER,
                                                A.STDNT_CAR_NBR
                                   ORDER BY A.EFFDT, A.EFFSEQ)    PRV_ACT_DT,
                           LAG (A.EFFSEQ)
                               OVER (
                                   PARTITION BY A.EMPLID,
                                                A.ACAD_CAREER,
                                                A.STDNT_CAR_NBR
                                   ORDER BY A.EFFDT, A.EFFSEQ)    PRV_ACT_SQ,
                           A.ACTION_DT,
                           A.PROG_REASON
                      FROM ps_rpt.PS_ACAD_PROG_v A
                     WHERE     A.PROG_ACTION IN ('LEAV', 'RLOA')
                           AND A.ACTION_DT <>
                               TO_DATE ('1901-01-01', 'YYYY-MM-DD')) A
             WHERE     1 = 1
                   AND A.ACAD_CAREER = 'SDM'
                   AND A.PRV_ACT IS NOT NULL
                   AND A.EFFDT > SYSDATE
                   AND A.PRV_ACT_DT <= SYSDATE) A
               ON population.EMPLID = A.EMPLID
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'LOA_M' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (SELECT DISTINCT A.EMPLID,
                            A.ACAD_CAREER,
                            A.PRV_ACT,
                            A.EFFDT,
                            A.PRV_ACT_DT
              FROM (SELECT A.EMPLID,
                           A.ACAD_CAREER,
                           A.STDNT_CAR_NBR,
                           A.EFFDT,
                           A.EFFSEQ,
                           A.INSTITUTION,
                           A.ACAD_PROG,
                           A.PROG_STATUS,
                           A.PROG_ACTION,
                           LAG (A.PROG_ACTION)
                               OVER (
                                   PARTITION BY A.EMPLID,
                                                A.ACAD_CAREER,
                                                A.STDNT_CAR_NBR
                                   ORDER BY A.EFFDT, A.EFFSEQ)    PRV_ACT,
                           LAG (A.EFFDT)
                               OVER (
                                   PARTITION BY A.EMPLID,
                                                A.ACAD_CAREER,
                                                A.STDNT_CAR_NBR
                                   ORDER BY A.EFFDT, A.EFFSEQ)    PRV_ACT_DT,
                           LAG (A.EFFSEQ)
                               OVER (
                                   PARTITION BY A.EMPLID,
                                                A.ACAD_CAREER,
                                                A.STDNT_CAR_NBR
                                   ORDER BY A.EFFDT, A.EFFSEQ)    PRV_ACT_SQ,
                           A.ACTION_DT,
                           A.PROG_REASON
                      FROM ps_rpt.PS_ACAD_PROG_v A
                     WHERE     A.PROG_ACTION IN ('LEAV', 'RLOA')
                           AND A.ACTION_DT <>
                               TO_DATE ('1901-01-01', 'YYYY-MM-DD')) A
             WHERE     1 = 1
                   AND A.ACAD_CAREER = 'MED'
                   AND A.PRV_ACT IS NOT NULL
                   AND A.EFFDT > SYSDATE
                   AND A.PRV_ACT_DT <= SYSDATE) A
               ON population.EMPLID = A.EMPLID
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'FLOA_U' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (SELECT DISTINCT A.EMPLID,
                            A.ACAD_CAREER,
                            A.PRV_ACT,
                            A.EFFDT,
                            A.PRV_ACT_DT
              FROM (SELECT A.EMPLID,
                           A.ACAD_CAREER,
                           A.STDNT_CAR_NBR,
                           A.EFFDT,
                           A.EFFSEQ,
                           A.INSTITUTION,
                           A.ACAD_PROG,
                           A.PROG_STATUS,
                           A.PROG_ACTION,
                           LAG (A.PROG_ACTION)
                               OVER (
                                   PARTITION BY A.EMPLID,
                                                A.ACAD_CAREER,
                                                A.STDNT_CAR_NBR
                                   ORDER BY A.EFFDT, A.EFFSEQ)    PRV_ACT,
                           LAG (A.EFFDT)
                               OVER (
                                   PARTITION BY A.EMPLID,
                                                A.ACAD_CAREER,
                                                A.STDNT_CAR_NBR
                                   ORDER BY A.EFFDT, A.EFFSEQ)    PRV_ACT_DT,
                           LAG (A.EFFSEQ)
                               OVER (
                                   PARTITION BY A.EMPLID,
                                                A.ACAD_CAREER,
                                                A.STDNT_CAR_NBR
                                   ORDER BY A.EFFDT, A.EFFSEQ)    PRV_ACT_SQ,
                           A.ACTION_DT,
                           A.PROG_REASON
                      FROM ps_rpt.PS_ACAD_PROG_v A
                     WHERE     A.PROG_ACTION IN ('LEAV', 'RLOA')
                           AND A.ACTION_DT <>
                               TO_DATE ('1901-01-01', 'YYYY-MM-DD')) A
             WHERE     1 = 1
                   AND A.ACAD_CAREER = 'UGRD'
                   AND A.PRV_ACT IS NOT NULL
                   AND A.EFFDT > SYSDATE
                   AND A.PRV_ACT_DT > SYSDATE) A
               ON population.EMPLID = A.EMPLID
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'FLOA_G' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (SELECT DISTINCT A.EMPLID,
                            A.ACAD_CAREER,
                            A.PRV_ACT,
                            A.EFFDT,
                            A.PRV_ACT_DT
              FROM (SELECT A.EMPLID,
                           A.ACAD_CAREER,
                           A.STDNT_CAR_NBR,
                           A.EFFDT,
                           A.EFFSEQ,
                           A.INSTITUTION,
                           A.ACAD_PROG,
                           A.PROG_STATUS,
                           A.PROG_ACTION,
                           LAG (A.PROG_ACTION)
                               OVER (
                                   PARTITION BY A.EMPLID,
                                                A.ACAD_CAREER,
                                                A.STDNT_CAR_NBR
                                   ORDER BY A.EFFDT, A.EFFSEQ)    PRV_ACT,
                           LAG (A.EFFDT)
                               OVER (
                                   PARTITION BY A.EMPLID,
                                                A.ACAD_CAREER,
                                                A.STDNT_CAR_NBR
                                   ORDER BY A.EFFDT, A.EFFSEQ)    PRV_ACT_DT,
                           LAG (A.EFFSEQ)
                               OVER (
                                   PARTITION BY A.EMPLID,
                                                A.ACAD_CAREER,
                                                A.STDNT_CAR_NBR
                                   ORDER BY A.EFFDT, A.EFFSEQ)    PRV_ACT_SQ,
                           A.ACTION_DT,
                           A.PROG_REASON
                      FROM ps_rpt.PS_ACAD_PROG_v A
                     WHERE     A.PROG_ACTION IN ('LEAV', 'RLOA')
                           AND A.ACTION_DT <>
                               TO_DATE ('1901-01-01', 'YYYY-MM-DD')) A
             WHERE     1 = 1
                   AND A.ACAD_CAREER = 'GRAD'
                   AND A.PRV_ACT IS NOT NULL
                   AND A.EFFDT > SYSDATE
                   AND A.PRV_ACT_DT > SYSDATE) A
               ON population.EMPLID = A.EMPLID
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'FLOA_L' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (SELECT DISTINCT A.EMPLID,
                            A.ACAD_CAREER,
                            A.PRV_ACT,
                            A.EFFDT,
                            A.PRV_ACT_DT
              FROM (SELECT A.EMPLID,
                           A.ACAD_CAREER,
                           A.STDNT_CAR_NBR,
                           A.EFFDT,
                           A.EFFSEQ,
                           A.INSTITUTION,
                           A.ACAD_PROG,
                           A.PROG_STATUS,
                           A.PROG_ACTION,
                           LAG (A.PROG_ACTION)
                               OVER (
                                   PARTITION BY A.EMPLID,
                                                A.ACAD_CAREER,
                                                A.STDNT_CAR_NBR
                                   ORDER BY A.EFFDT, A.EFFSEQ)    PRV_ACT,
                           LAG (A.EFFDT)
                               OVER (
                                   PARTITION BY A.EMPLID,
                                                A.ACAD_CAREER,
                                                A.STDNT_CAR_NBR
                                   ORDER BY A.EFFDT, A.EFFSEQ)    PRV_ACT_DT,
                           LAG (A.EFFSEQ)
                               OVER (
                                   PARTITION BY A.EMPLID,
                                                A.ACAD_CAREER,
                                                A.STDNT_CAR_NBR
                                   ORDER BY A.EFFDT, A.EFFSEQ)    PRV_ACT_SQ,
                           A.ACTION_DT,
                           A.PROG_REASON
                      FROM ps_rpt.PS_ACAD_PROG_v A
                     WHERE     A.PROG_ACTION IN ('LEAV', 'RLOA')
                           AND A.ACTION_DT <>
                               TO_DATE ('1901-01-01', 'YYYY-MM-DD')) A
             WHERE     1 = 1
                   AND A.ACAD_CAREER = 'LAW'
                   AND A.PRV_ACT IS NOT NULL
                   AND A.EFFDT > SYSDATE
                   AND A.PRV_ACT_DT > SYSDATE) A
               ON population.EMPLID = A.EMPLID
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'FLOA_P' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (SELECT DISTINCT A.EMPLID,
                            A.ACAD_CAREER,
                            A.PRV_ACT,
                            A.EFFDT,
                            A.PRV_ACT_DT
              FROM (SELECT A.EMPLID,
                           A.ACAD_CAREER,
                           A.STDNT_CAR_NBR,
                           A.EFFDT,
                           A.EFFSEQ,
                           A.INSTITUTION,
                           A.ACAD_PROG,
                           A.PROG_STATUS,
                           A.PROG_ACTION,
                           LAG (A.PROG_ACTION)
                               OVER (
                                   PARTITION BY A.EMPLID,
                                                A.ACAD_CAREER,
                                                A.STDNT_CAR_NBR
                                   ORDER BY A.EFFDT, A.EFFSEQ)    PRV_ACT,
                           LAG (A.EFFDT)
                               OVER (
                                   PARTITION BY A.EMPLID,
                                                A.ACAD_CAREER,
                                                A.STDNT_CAR_NBR
                                   ORDER BY A.EFFDT, A.EFFSEQ)    PRV_ACT_DT,
                           LAG (A.EFFSEQ)
                               OVER (
                                   PARTITION BY A.EMPLID,
                                                A.ACAD_CAREER,
                                                A.STDNT_CAR_NBR
                                   ORDER BY A.EFFDT, A.EFFSEQ)    PRV_ACT_SQ,
                           A.ACTION_DT,
                           A.PROG_REASON
                      FROM ps_rpt.PS_ACAD_PROG_v A
                     WHERE     A.PROG_ACTION IN ('LEAV', 'RLOA')
                           AND A.ACTION_DT <>
                               TO_DATE ('1901-01-01', 'YYYY-MM-DD')) A
             WHERE     1 = 1
                   AND A.ACAD_CAREER = 'PHRM'
                   AND A.PRV_ACT IS NOT NULL
                   AND A.EFFDT > SYSDATE
                   AND A.PRV_ACT_DT > SYSDATE) A
               ON population.EMPLID = A.EMPLID
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'FLOA_D' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (SELECT DISTINCT A.EMPLID,
                            A.ACAD_CAREER,
                            A.PRV_ACT,
                            A.EFFDT,
                            A.PRV_ACT_DT
              FROM (SELECT A.EMPLID,
                           A.ACAD_CAREER,
                           A.STDNT_CAR_NBR,
                           A.EFFDT,
                           A.EFFSEQ,
                           A.INSTITUTION,
                           A.ACAD_PROG,
                           A.PROG_STATUS,
                           A.PROG_ACTION,
                           LAG (A.PROG_ACTION)
                               OVER (
                                   PARTITION BY A.EMPLID,
                                                A.ACAD_CAREER,
                                                A.STDNT_CAR_NBR
                                   ORDER BY A.EFFDT, A.EFFSEQ)    PRV_ACT,
                           LAG (A.EFFDT)
                               OVER (
                                   PARTITION BY A.EMPLID,
                                                A.ACAD_CAREER,
                                                A.STDNT_CAR_NBR
                                   ORDER BY A.EFFDT, A.EFFSEQ)    PRV_ACT_DT,
                           LAG (A.EFFSEQ)
                               OVER (
                                   PARTITION BY A.EMPLID,
                                                A.ACAD_CAREER,
                                                A.STDNT_CAR_NBR
                                   ORDER BY A.EFFDT, A.EFFSEQ)    PRV_ACT_SQ,
                           A.ACTION_DT,
                           A.PROG_REASON
                      FROM ps_rpt.PS_ACAD_PROG_v A
                     WHERE     A.PROG_ACTION IN ('LEAV', 'RLOA')
                           AND A.ACTION_DT <>
                               TO_DATE ('1901-01-01', 'YYYY-MM-DD')) A
             WHERE     1 = 1
                   AND A.ACAD_CAREER = 'SDM'
                   AND A.PRV_ACT IS NOT NULL
                   AND A.EFFDT > SYSDATE
                   AND A.PRV_ACT_DT > SYSDATE) A
               ON population.EMPLID = A.EMPLID
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'FLOA_M' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (SELECT DISTINCT A.EMPLID,
                            A.ACAD_CAREER,
                            A.PRV_ACT,
                            A.EFFDT,
                            A.PRV_ACT_DT
              FROM (SELECT A.EMPLID,
                           A.ACAD_CAREER,
                           A.STDNT_CAR_NBR,
                           A.EFFDT,
                           A.EFFSEQ,
                           A.INSTITUTION,
                           A.ACAD_PROG,
                           A.PROG_STATUS,
                           A.PROG_ACTION,
                           LAG (A.PROG_ACTION)
                               OVER (
                                   PARTITION BY A.EMPLID,
                                                A.ACAD_CAREER,
                                                A.STDNT_CAR_NBR
                                   ORDER BY A.EFFDT, A.EFFSEQ)    PRV_ACT,
                           LAG (A.EFFDT)
                               OVER (
                                   PARTITION BY A.EMPLID,
                                                A.ACAD_CAREER,
                                                A.STDNT_CAR_NBR
                                   ORDER BY A.EFFDT, A.EFFSEQ)    PRV_ACT_DT,
                           LAG (A.EFFSEQ)
                               OVER (
                                   PARTITION BY A.EMPLID,
                                                A.ACAD_CAREER,
                                                A.STDNT_CAR_NBR
                                   ORDER BY A.EFFDT, A.EFFSEQ)    PRV_ACT_SQ,
                           A.ACTION_DT,
                           A.PROG_REASON
                      FROM ps_rpt.PS_ACAD_PROG_v A
                     WHERE     A.PROG_ACTION IN ('LEAV', 'RLOA')
                           AND A.ACTION_DT <>
                               TO_DATE ('1901-01-01', 'YYYY-MM-DD')) A
             WHERE     1 = 1
                   AND A.ACAD_CAREER = 'MED'
                   AND A.PRV_ACT IS NOT NULL
                   AND A.EFFDT > SYSDATE
                   AND A.PRV_ACT_DT > SYSDATE) A
               ON population.EMPLID = A.EMPLID
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'REG' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           JOIN
           (SELECT DISTINCT A.STRM,
                            B.FIRST_ENRL_DT,
                            C.END_DT,
                            D.EMPLID     "EMPLID",
                            D.ACAD_CAREER,
                            D.ACAD_PROG_PRIMARY,
                            E.PROG_STATUS,
                            E.ADMIT_TERM,
                            E.EXP_GRAD_TERM,
                            E.DEGR_CHKOUT_STAT,
                            "Prev Regular Term",
                            "Prev Enrolled Term"
              FROM PS_RPT.PS_TERM_TBL_V             A,
                   PS_RPT.PS_SESSION_TBL_V          B,
                   PS_RPT.PS_SESS_TIME_PEROD_V      C,
                   PS_RPT.PS_STDNT_CAR_TERM_V       D,
                   PS_RPT.PS_ACAD_PROG_V            E,
                   PS_RPT.PS_ACAD_PLAN_V            F,
                   PS_RPT.cmp_POPULATION_CURRENT_V  Z,
                   ---rank Fall and Spring terms starting with the most recent; a term becomes rankable only after the add/drop date
                    (SELECT A.STRM                             "Prev Regular Term",
                            A.ACAD_CAREER                      "Career",
                            RANK ()
                                OVER (PARTITION BY A.ACAD_CAREER
                                      ORDER BY A.STRM DESC)    "Prev Regular Term Rank"
                       FROM PS_RPT.PS_TERM_TBL_V         A,
                            PS_RPT.PS_SESSION_TBL_V      B,
                            PS_RPT.PS_SESS_TIME_PEROD_V  C
                      WHERE     B.SESSION_CODE = A.SESSION_CODE
                            AND B.STRM = A.STRM
                            AND B.ACAD_CAREER = A.ACAD_CAREER
                            AND B.INSTITUTION = A.INSTITUTION
                            AND C.INSTITUTION = B.INSTITUTION
                            AND C.ACAD_CAREER = B.ACAD_CAREER
                            AND C.STRM = B.STRM
                            AND C.SESSION_CODE = B.SESSION_CODE
                            AND A.TERM_CATEGORY = 'R'
                            AND B.SESSION_CODE = '1'
                            AND C.TIME_PERIOD = '135'
                            AND C.END_DT < SYSDATE
                            AND A.ACAD_CAREER = 'UGRD') prevreg,
                   ---rank previous enrolled Fall and Spring terms starting with the most recent
                    (SELECT I.EMPLID                           "Emplid",
                            I.ACAD_CAREER                      "Career",
                            I.STRM                             "Prev Enrolled Term",
                            RANK ()
                                OVER (PARTITION BY I.EMPLID, I.ACAD_CAREER
                                      ORDER BY I.STRM DESC)    "Prev Enrolled Term Rank"
                       FROM PS_RPT.PS_STDNT_ENRL_V I, PS_RPT.PS_TERM_TBL_V T
                      WHERE     I.STRM = T.STRM
                            AND I.ACAD_CAREER = T.ACAD_CAREER
                            AND I.ACAD_CAREER = 'UGRD'
                            AND I.STDNT_ENRL_STATUS = 'E'
                            AND T.TERM_CATEGORY = 'R') prevenr
             WHERE     Z.EMPLID = D.EMPLID
                   AND Z.STRM = D.STRM
                   AND D.EMPLID = prevenr."Emplid"
                   AND D.ACAD_CAREER = prevenr."Career"
                   AND prevenr."Prev Enrolled Term Rank" = 1
                   AND prevreg."Prev Regular Term Rank" = 1
                   AND prevreg."Prev Regular Term" =
                       prevenr."Prev Enrolled Term"
                   AND (   (E.EXP_GRAD_TERM = ' ')
                        OR (E.EXP_GRAD_TERM >= A.STRM)
                        OR (    E.EXP_GRAD_TERM < A.STRM
                            AND E.DEGR_CHKOUT_STAT = 'DN'))
                   AND B.SESSION_CODE = A.SESSION_CODE
                   AND B.STRM = A.STRM
                   AND B.ACAD_CAREER = A.ACAD_CAREER
                   AND B.INSTITUTION = A.INSTITUTION
                   AND C.INSTITUTION = B.INSTITUTION
                   AND C.ACAD_CAREER = B.ACAD_CAREER
                   AND C.STRM = B.STRM
                   AND C.SESSION_CODE = B.SESSION_CODE
                   AND A.TERM_CATEGORY = 'R'
                   AND B.SESSION_CODE = '1'
                   AND C.TIME_PERIOD = '135'
                   AND C.END_DT >= SYSDATE
                   AND A.ACAD_CAREER = 'UGRD'
                   AND C.INSTITUTION = D.INSTITUTION
                   AND C.ACAD_CAREER = D.ACAD_CAREER
                   AND C.STRM = D.STRM
                   AND D.ACAD_LEVEL_BOT NOT LIKE 'ND'
                   AND                         ---D.UNT_TAKEN_PRGRSS = '0' AND
                       D.EMPLID = E.EMPLID
                   AND D.ACAD_CAREER = E.ACAD_CAREER
                   AND D.INSTITUTION = E.INSTITUTION
                   AND F.EMPLID = E.EMPLID
                   AND F.ACAD_CAREER = E.ACAD_CAREER
                   AND F.STDNT_CAR_NBR = E.STDNT_CAR_NBR
                   AND F.EFFDT = E.EFFDT
                   AND F.EFFSEQ = E.EFFSEQ
                   AND E.EFFDT =
                       (SELECT MAX (E_ED.EFFDT)
                          FROM PS_RPT.PS_ACAD_PROG_V E_ED
                         WHERE     E.EMPLID = E_ED.EMPLID
                               AND E.ACAD_CAREER = E_ED.ACAD_CAREER
                               AND E.STDNT_CAR_NBR = E_ED.STDNT_CAR_NBR
                               AND E.EFFDT <= A.TERM_END_DT)
                   AND E.EFFSEQ =
                       (SELECT MAX (E_ES.EFFSEQ)
                          FROM PS_RPT.PS_ACAD_PROG_V E_ES
                         WHERE     E.EMPLID = E_ES.EMPLID
                               AND E.ACAD_CAREER = E_ES.ACAD_CAREER
                               AND E.STDNT_CAR_NBR = E_ES.STDNT_CAR_NBR
                               AND E.EFFDT = E_ES.EFFDT)
                   AND ---limit to students with active program status; filter select Plans
                       E.PROG_STATUS = 'AC'
                   AND F.ACAD_PLAN NOT LIKE '______X%'
                   AND F.ACAD_PLAN NOT IN ('MBC031R0',
                                           'ICE012R0A',
                                           'ICE012R0I',
                                           'ICE012R5A',
                                           'ICE012R5I',
                                           'IEE012R5I',
                                           'IEE012R0A',
                                           'IEE012R0I',
                                           'IEE012R5A')
                   AND (E.ACAD_PROG NOT LIKE '__N_')
                   AND                   ---exclude certain Academic Standings
                       NOT EXISTS
                           (SELECT 'X'
                              FROM PS_RPT.PS_ACAD_STDNG_ACTN_V G
                             WHERE     G.EFFDT =
                                       (SELECT MAX (G_ED.EFFDT)
                                          FROM PS_RPT.PS_ACAD_STDNG_ACTN_V
                                               G_ED
                                         WHERE     G.EMPLID = G_ED.EMPLID
                                               AND G.ACAD_CAREER =
                                                   G_ED.ACAD_CAREER
                                               AND G.INSTITUTION =
                                                   G_ED.INSTITUTION)
                                   AND G.EFFSEQ =
                                       (SELECT MAX (G_ES.EFFSEQ)
                                          FROM PS_RPT.PS_ACAD_STDNG_ACTN_V
                                               G_ES
                                         WHERE     G.EMPLID = G_ES.EMPLID
                                               AND G.ACAD_CAREER =
                                                   G_ES.ACAD_CAREER
                                               AND G.INSTITUTION =
                                                   G_ES.INSTITUTION
                                               AND G.EFFDT = G_ES.EFFDT)
                                   AND G.EMPLID = D.EMPLID
                                   AND G.ACAD_CAREER = D.ACAD_CAREER
                                   AND G.INSTITUTION = D.INSTITUTION
                                   AND G.ACAD_STNDNG_ACTN IN ('APPL',
                                                              'APSU',
                                                              'DISD',
                                                              'DISM',
                                                              'DISV'))
                   AND     ---exclude students term-activated in other Careers
                       NOT EXISTS
                           (SELECT 'X'
                              FROM PS_RPT.PS_STDNT_CAR_TERM_V H
                             WHERE     H.EMPLID = D.EMPLID
                                   AND H.STRM = D.STRM
                                   AND H.ACAD_CAREER <> D.ACAD_CAREER)
                   AND NOT EXISTS
                           (SELECT 'X'
                              FROM PS_RPT.PS_SRVC_IND_DATA_V i
                             WHERE     i.EMPLID = D.EMPLID
                                   AND i.SRVC_IND_CD IN ('CVD', 'CVB'))) rg
               ON rg.EMPLID = population.EMPLID
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'SEAS' AS CATEGORY_ID
      FROM PS_RPT.PS_STDNT_ADVR_HIST_V  a
           JOIN PS_RPT.CMP_POPULATION_CURRENT_V population
               ON a.EMPLID = population.EMPLID
     WHERE     a.COMMITTEE_ID = 'SEAS'
           AND a.EFFDT =
               (SELECT MAX (b.effdt)
                  FROM PS_RPT.PS_STDNT_ADVR_HIST_V b
                 WHERE     a.emplid = b.emplid
                       AND a.institution = b.institution
                       AND a.advisor_role = b.advisor_role)
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'WES' AS CATEGORY_ID
      FROM PS_RPT.PS_SRVC_IND_DATA_V  a
           JOIN PS_RPT.CMP_POPULATION_CURRENT_V population
               ON a.EMPLID = population.EMPLID
     WHERE a.SRVC_IND_CD = 'WES'
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'PHARMD' AS CATEGORY_ID
      FROM PS_RPT.PS_STDNT_ADVR_HIST_V  a
           JOIN PS_RPT.CMP_POPULATION_CURRENT_V population
               ON a.EMPLID = population.EMPLID
     WHERE     a.COMMITTEE_ID = 'PHARMD'
           AND a.EFFDT =
               (SELECT MAX (b.effdt)
                  FROM PS_RPT.PS_STDNT_ADVR_HIST_V b
                 WHERE     a.emplid = b.emplid
                       AND a.institution = b.institution
                       AND a.advisor_role = b.advisor_role)
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'JSMBS' AS CATEGORY_ID
      FROM PS_RPT.PS_STDNT_ADVR_HIST_V  a
           JOIN PS_RPT.CMP_POPULATION_CURRENT_V population
               ON a.EMPLID = population.EMPLID
     WHERE     a.COMMITTEE_ID = 'JSMBS'
           AND a.EFFDT =
               (SELECT MAX (b.effdt)
                  FROM PS_RPT.PS_STDNT_ADVR_HIST_V b
                 WHERE     a.emplid = b.emplid
                       AND a.institution = b.institution
                       AND a.advisor_role = b.advisor_role)
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'DISC' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V population
     WHERE population.EMPLID NOT IN
               (SELECT A.EMPLID
                  FROM ps_rpt.ps_acad_prog_v A
                 WHERE     A.EFFDT =
                           (SELECT MAX (A_ED.EFFDT)
                              FROM ps_rpt.ps_acad_prog_v A_ED
                             WHERE     A.EMPLID = A_ED.EMPLID
                                   AND A.ACAD_CAREER = A_ED.ACAD_CAREER
                                   AND A.STDNT_CAR_NBR = A_ED.STDNT_CAR_NBR)
                       AND A.EFFSEQ =
                           (SELECT MAX (A_ES.EFFSEQ)
                              FROM ps_rpt.ps_acad_prog_v A_ES
                             WHERE     A.EMPLID = A_ES.EMPLID
                                   AND A.ACAD_CAREER = A_ES.ACAD_CAREER
                                   AND A.STDNT_CAR_NBR = A_ES.STDNT_CAR_NBR
                                   AND A.EFFDT = A_ES.EFFDT)
                       AND A.PROG_STATUS NOT IN ('DC'))
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'MLTCAR' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (  SELECT A.EMPLID, COUNT (DISTINCT A.ACAD_CAREER)
                FROM ps_rpt.PS_ACAD_PROG_V A
               WHERE (    A.EFFDT =
                          (SELECT MAX (A_ED.EFFDT)
                             FROM ps_rpt.PS_ACAD_PROG_V A_ED
                            WHERE     A.EMPLID = A_ED.EMPLID
                                  AND A.ACAD_CAREER = A_ED.ACAD_CAREER
                                  AND A.STDNT_CAR_NBR = A_ED.STDNT_CAR_NBR
                                  AND A_ED.EFFDT <= SYSDATE)
                      AND A.EFFSEQ =
                          (SELECT MAX (A_ES.EFFSEQ)
                             FROM ps_rpt.PS_ACAD_PROG_V A_ES
                            WHERE     A.EMPLID = A_ES.EMPLID
                                  AND A.ACAD_CAREER = A_ES.ACAD_CAREER
                                  AND A.STDNT_CAR_NBR = A_ES.STDNT_CAR_NBR
                                  AND A.EFFDT = A_ES.EFFDT)
                      AND A.PROG_STATUS IN ('AC', 'LA')
                      AND A.ACAD_PROG NOT LIKE '__N_')
            GROUP BY A.EMPLID
              HAVING (COUNT (DISTINCT A.ACAD_CAREER) > '1')) a
               ON population.EMPLID = A.EMPLID
    UNION
    ---continuing undergraduate students in a regular term

    SELECT population.EMPLID AS STUDENT_ID, 'CONT' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (SELECT a.EMPLOYEEID,
                   a.BILLINGCAREER,
                   a.TERMSOURCEKEY,
                   a.TERM,
                   t.TERMCATEGORY,
                   t.TERMBEGINDATE,
                   t.NXT_BOT
              FROM PS_RPT.STUDENTTERM_CUR_V  a
                   INNER JOIN
                   (SELECT SOURCEKEY,
                           TERMBEGINDATE,
                           TERMCATEGORY,
                           LEAD (TERMBEGINDATE, 1)
                               OVER (PARTITION BY INSTITUTION
                                     ORDER BY SOURCEKEY)    NXT_BOT
                      FROM PS_RPT.LOK_TERM_V
                     WHERE TERMCATEGORY = 'Regular Term') t
                       ON a.TERMSOURCEKEY = t.SOURCEKEY
             WHERE     1 = 1
                   AND a.CAREERSOURCEKEY = 'UGRD'
                   ---AND a.CAREERSOURCEKEY=a.BILLINGCAREER

                   AND SYSDATE BETWEEN t.TERMBEGINDATE AND t.NXT_BOT
                   AND A.ENROLLEDINDICATOR = 'Enrolled'
                   AND A.PROGRAMSOURCEKEY NOT LIKE '__N_'
                   AND a.CURRENTPROGRAMSTATUSSOURCEKEY IN ('AC', 'LA')) CONT
               ON population.EMPLID = CONT.EMPLOYEEID
    ---continuiing undergraduate students in a summer or winter term

    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'CONT' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (SELECT a.EMPLOYEEID,
                   a.BILLINGCAREER,
                   a.TERMSOURCEKEY,
                   a.TERM,
                   t.TERMCATEGORY,
                   t.TERMBEGINDATE,
                   t.NXT_BOT
              FROM PS_RPT.STUDENTTERM_CUR_V  a
                   INNER JOIN
                   (SELECT SOURCEKEY,
                           TERMCATEGORY,
                           TERMBEGINDATE,
                           LEAD (TERMBEGINDATE, 1)
                               OVER (PARTITION BY INSTITUTION
                                     ORDER BY SOURCEKEY)    NXT_BOT
                      FROM PS_RPT.LOK_TERM_V) t
                       ON a.TERMSOURCEKEY = t.SOURCEKEY
             WHERE     1 = 1
                   AND a.CAREERSOURCEKEY = 'UGRD'
                   ---AND a.CAREERSOURCEKEY=a.BILLINGCAREER

                   AND SYSDATE BETWEEN t.TERMBEGINDATE AND t.NXT_BOT
                   AND A.ENROLLEDINDICATOR = 'Enrolled'
                   AND A.PROGRAMSOURCEKEY NOT LIKE '__N_'
                   AND a.CURRENTPROGRAMSTATUSSOURCEKEY IN ('AC', 'LA')
                   AND t.TERMCATEGORY IN ('Summer Term', 'Intersession Term'))
           CONT
               ON population.EMPLID = CONT.EMPLOYEEID
    ---Continuing graduate or professional students in a regular term


    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'GCOT' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (SELECT a.EMPLOYEEID,
                   a.BILLINGCAREER,
                   a.TERMSOURCEKEY,
                   a.TERM,
                   t.TERMCATEGORY,
                   t.TERMBEGINDATE,
                   t.NXT_BOT
              FROM PS_RPT.STUDENTTERM_CUR_V  a
                   INNER JOIN
                   (SELECT SOURCEKEY,
                           TERMBEGINDATE,
                           TERMCATEGORY,
                           LEAD (TERMBEGINDATE, 1)
                               OVER (PARTITION BY INSTITUTION
                                     ORDER BY SOURCEKEY)    NXT_BOT
                      FROM PS_RPT.LOK_TERM_V
                     WHERE TERMCATEGORY = 'Regular Term') t
                       ON a.TERMSOURCEKEY = t.SOURCEKEY
             WHERE     1 = 1
                   AND a.CAREERSOURCEKEY <> 'UGRD'
                   ---AND a.CAREERSOURCEKEY=a.BILLINGCAREER

                   AND SYSDATE BETWEEN t.TERMBEGINDATE AND t.NXT_BOT
                   AND A.ENROLLEDINDICATOR = 'Enrolled'
                   AND A.PROGRAMSOURCEKEY NOT LIKE '__N_'
                   AND a.CURRENTPROGRAMSTATUSSOURCEKEY IN ('AC', 'LA')) GCOT
               ON population.EMPLID = GCOT.EMPLOYEEID
    ---continuing graduate professional student in winter or summer term

    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'GCOT' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (SELECT a.EMPLOYEEID,
                   a.BILLINGCAREER,
                   a.TERMSOURCEKEY,
                   a.TERM,
                   t.TERMCATEGORY,
                   t.TERMBEGINDATE,
                   t.NXT_BOT
              FROM PS_RPT.STUDENTTERM_CUR_V  a
                   INNER JOIN
                   (SELECT SOURCEKEY,
                           TERMCATEGORY,
                           TERMBEGINDATE,
                           LEAD (TERMBEGINDATE, 1)
                               OVER (PARTITION BY INSTITUTION
                                     ORDER BY SOURCEKEY)    NXT_BOT
                      FROM PS_RPT.LOK_TERM_V) t
                       ON a.TERMSOURCEKEY = t.SOURCEKEY
             WHERE     1 = 1
                   AND a.CAREERSOURCEKEY <> 'UGRD'
                   AND a.CAREERSOURCEKEY = a.BILLINGCAREER
                   AND SYSDATE BETWEEN t.TERMBEGINDATE AND t.NXT_BOT
                   AND A.ENROLLEDINDICATOR = 'Enrolled'
                   AND A.PROGRAMSOURCEKEY NOT LIKE '__N_'
                   AND a.CURRENTPROGRAMSTATUSSOURCEKEY IN ('AC', 'LA')
                   AND t.TERMCATEGORY IN ('Summer Term', 'Intersession Term'))
           GCOT
               ---note fix to join from 9/6/22 version

               ON population.EMPLID = GCOT.EMPLOYEEID
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'NODEG' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V population
     WHERE     population.EMPLID IN
                   (SELECT A.EMPLID
                      FROM ps_rpt.ps_acad_prog_v A
                     WHERE     A.EFFDT =
                               (SELECT MAX (A_ED.EFFDT)
                                  FROM ps_rpt.ps_acad_prog_v A_ED
                                 WHERE     A.EMPLID = A_ED.EMPLID
                                       AND A.ACAD_CAREER = A_ED.ACAD_CAREER
                                       AND A.STDNT_CAR_NBR =
                                           A_ED.STDNT_CAR_NBR)
                           AND A.EFFSEQ =
                               (SELECT MAX (A_ES.EFFSEQ)
                                  FROM ps_rpt.ps_acad_prog_v A_ES
                                 WHERE     A.EMPLID = A_ES.EMPLID
                                       AND A.ACAD_CAREER = A_ES.ACAD_CAREER
                                       AND A.STDNT_CAR_NBR =
                                           A_ES.STDNT_CAR_NBR
                                       AND A.EFFDT = A_ES.EFFDT)
                           AND A.INSTITUTION = 'UBFLO'
                           AND A.ACAD_CAREER = 'UGRD'
                           AND A.PROG_STATUS = 'AC'
                           AND A.EXP_GRAD_TERM = ' '
                           AND A.ACAD_PROG LIKE '__R_')
           AND population.EMPLID IN
                   (SELECT aa.EMPLID
                      FROM PS_RPT.PS_SAA_ADB_RESULTS_V aa
                     WHERE     aa.SAA_CAREER_RPT = 'UGRD'
                           AND aa.TSCRPT_TYPE = 'ADV'
                           AND aa.ENTRY_R_TYPE = 'KEYCAR'
                           AND aa.ITEM_R_STATUS = 'COMP')
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'MGT' AS CATEGORY_ID
      FROM PS_RPT.PS_STDNT_ADVR_HIST_V  a
           JOIN PS_RPT.CMP_POPULATION_CURRENT_V population
               ON a.EMPLID = population.EMPLID
     WHERE     a.COMMITTEE_ID = 'MGT'
           AND a.EFFDT =
               (SELECT MAX (b.effdt)
                  FROM PS_RPT.PS_STDNT_ADVR_HIST_V b
                 WHERE     a.emplid = b.emplid
                       AND a.institution = b.institution
                       AND a.advisor_role = b.advisor_role)
    UNION
    SELECT STUDENT_ID, CATEGORY_ID
      FROM (WITH
                UBC_FAILS
                AS
                    (SELECT population.EMPLID,
                            r.RQRMNT_GROUP,
                            r.REQUIREMENT,
                            r.RQ_LINE_NBR
                       FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
                            INNER JOIN ps_rpt.STUDENTTERM_CUR_V s
                                ON     population.EMPLID = s.EMPLOYEEID
                                   AND population.STRM = s.TERMSOURCEKEY
                                   AND s.INSTITUTIONSOURCEKEY = 'UBFLO'
                                   AND s.CAREERSOURCEKEY = 'UGRD'
                                   AND s.PLANSOURCEKEY NOT LIKE '______X%'
                                   AND s.DEGREESEEKINGINDSOURCEKEY = 'DEGRE'
                            INNER JOIN ps_rpt.LOK_TERM_v t
                                ON     s.TERMSOURCEKEY = t.SOURCEKEY
                                   AND t.TERMENDDATE >= SYSDATE
                            INNER JOIN
                            (SELECT a.EMPLID,
                                    a.ANALYSIS_DB_SEQ,
                                    a.SAA_CAREER_RPT,
                                    a.SAA_ENTRY_SEQ,
                                    a.RQRMNT_GROUP,
                                    a.REQUIREMENT,
                                    a.RQ_LINE_NBR
                               FROM ps_rpt.PS_SAA_ADB_RESULTS_V a
                              WHERE     a.SAA_CAREER_RPT = 'UGRD'
                                    AND a.TSCRPT_TYPE = 'ADV'
                                    AND a.RQRMNT_GROUP IN
                                            ('000026', '000027')
                                    AND a.ENTRY_R_TYPE = 'KEYRQL'
                                    AND a.ITEM_R_STATUS = 'FAIL') r
                                ON population.EMPLID = r.EMPLID)
                SELECT cap.EMPLID AS STUDENT_ID, 'No_Cap' AS CATEGORY_ID
                  FROM UBC_FAILS cap
                 WHERE cap.REQUIREMENT = '000100265'
                UNION
                SELECT cl1.EMPLID AS STUDENT_ID, 'No_CL1' AS CATEGORY_ID
                  FROM UBC_FAILS cl1
                 WHERE     cl1.REQUIREMENT = '000100261'
                       AND cl1.RQ_LINE_NBR IN ('0010',
                                               '0012',
                                               '0017',
                                               '0018')
                UNION
                SELECT cl2.EMPLID AS STUDENT_ID, 'No_CL2' AS CATEGORY_ID
                  FROM UBC_FAILS cl2
                 WHERE     cl2.REQUIREMENT = '000100261'
                       AND cl2.RQ_LINE_NBR IN ('0020', '0025')
                UNION
                SELECT div.EMPLID AS STUDENT_ID, 'No_DIV' AS CATEGORY_ID
                  FROM UBC_FAILS div
                 WHERE div.REQUIREMENT = '000101328'
                UNION
                SELECT DISTINCT
                       mqr.EMPLID AS STUDENT_ID, 'No_MQR' AS CATEGORY_ID
                  FROM UBC_FAILS mqr
                 WHERE mqr.REQUIREMENT = '000100262'
                UNION
                SELECT DISTINCT
                       GLB.EMPLID AS STUDENT_ID, 'No_GLB' AS CATEGORY_ID
                  FROM UBC_FAILS GLB
                 WHERE GLB.REQUIREMENT = '000100247'
                UNION
                SELECT thm.EMPLID AS STUDENT_ID, 'No_THM' AS CATEGORY_ID
                  FROM UBC_FAILS thm
                 WHERE thm.REQUIREMENT = '000100246'
                UNION
                SELECT DISTINCT
                       sli.EMPLID AS STUDENT_ID, 'No_SLI' AS CATEGORY_ID
                  FROM UBC_FAILS sli
                 WHERE sli.REQUIREMENT = '000100264'
                UNION
                SELECT DISTINCT
                       sem.EMPLID AS STUDENT_ID, 'No_SEM' AS CATEGORY_ID
                  FROM UBC_FAILS sem
                 WHERE sem.REQUIREMENT = '000100260')
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'CMP_UBC' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN ps_rpt.LOK_TERM_v t
               ON population.STRM = t.SOURCEKEY AND t.TERMENDDATE >= SYSDATE
           INNER JOIN ps_rpt.STUDENTTERM_CUR_V s
               ON     population.EMPLID = s.EMPLOYEEID
                  AND population.STRM = s.TERMSOURCEKEY
                  AND s.INSTITUTIONSOURCEKEY = 'UBFLO'
                  AND s.CAREERSOURCEKEY = 'UGRD'
                  AND s.PLANSOURCEKEY NOT LIKE '______X%'
                  AND s.DEGREESEEKINGINDSOURCEKEY = 'DEGRE'
           INNER JOIN
           (SELECT a.EMPLID,
                   a.ANALYSIS_DB_SEQ,
                   a.SAA_CAREER_RPT,
                   a.SAA_ENTRY_SEQ,
                   a.ITEM_R_STATUS,
                   a.TSCRPT_TYPE,
                   a.RQRMNT_GROUP
              FROM ps_rpt.PS_SAA_ADB_RESULTS_V a
             WHERE a.SAA_CAREER_RPT = 'UGRD' AND a.ENTRY_R_TYPE = 'KEYRQG') r
               ON     population.EMPLID = r.EMPLID
                  AND r.ITEM_R_STATUS = 'COMP'
                  AND r.TSCRPT_TYPE = 'ADV'
                  AND r.RQRMNT_GROUP IN ('000026')
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'FRFAI' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN ps_rpt.PS_SRVC_IND_DATA_v s
               ON population.EMPLID = s.EMPLID
     WHERE s.SRVC_IND_CD = 'FRF' AND s.SRVC_IND_REASON = 'FRFAI'
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'FRFFI' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN ps_rpt.PS_SRVC_IND_DATA_v s
               ON population.EMPLID = s.EMPLID
     WHERE s.SRVC_IND_CD = 'FRF' AND s.SRVC_IND_REASON = 'FRFFI'
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'BIL' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN ps_rpt.PS_SRVC_IND_DATA_v s
               ON population.EMPLID = s.EMPLID
     WHERE s.SRVC_IND_CD = 'BIL'
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'MEN' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN ps_rpt.PS_SRVC_IND_DATA_v s
               ON population.EMPLID = s.EMPLID
     WHERE s.SRVC_IND_CD = 'MEN'
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'IMM' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN ps_rpt.PS_SRVC_IND_DATA_v s
               ON population.EMPLID = s.EMPLID
     WHERE     s.SRVC_IND_CD = 'IMM'
           AND NOT EXISTS
                   (SELECT 'X'
                      FROM ps_rpt.PS_SRVC_IND_DATA_v s1
                     WHERE s1.EMPLID = s.EMPLID AND s1.SRVC_IND_CD = 'IMR')
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'NOADD' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN ps_rpt.PS_SRVC_IND_DATA_v s
               ON population.EMPLID = s.EMPLID
           INNER JOIN
           (SELECT DISTINCT A.SERVICE_IMPACT, A.SRVC_IND_CD
              FROM ps_rpt.PS_SERVICE_IMPACT_v A
             WHERE     A.EFFDT =
                       (SELECT MAX (A_ED.EFFDT)
                          FROM ps_rpt.PS_SERVICE_IMPACT_v A_ED
                         WHERE     A.INSTITUTION = A_ED.INSTITUTION
                               AND A.SRVC_IND_CD = A_ED.SRVC_IND_CD
                               AND A_ED.EFFDT <= SYSDATE)
                   AND A.SERVICE_IMPACT IN ('WENR',
                                            'CENR',
                                            'AENR',
                                            'IENR')) imp
               ON s.SRVC_IND_CD = imp.SRVC_IND_CD
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'FERPA' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN ps_rpt.ps_FERPA_OVERRIDE_v f
               ON population.EMPLID = f.EMPLID
    UNION
    SELECT population.EMPLID          AS STUDENT_ID,
           'INCL- ' || t.TERMTYPE     AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN ps_rpt.PS_STDNT_ENRL_v e
               ON population.EMPLID = e.EMPLID AND e.CRSE_GRADE_OFF LIKE 'I%'
           INNER JOIN ps_rpt.LOK_TERM_v t
               ON e.STRM = t.SOURCEKEY AND t.TERMENDDATE < SYSDATE
    UNION
    SELECT population.EMPLID    AS STUDENT_ID,
           (CASE
                WHEN AA.RQ_LINE_NBR IN ('0100',
                                        '0150',
                                        '0160',
                                        '0200',
                                        '0210',
                                        '0215')
                THEN
                    'MRA1'
                WHEN AA.RQ_LINE_NBR IN ('0140')
                THEN
                    'MRA2'
                WHEN AA.RQ_LINE_NBR IN ('0165',
                                        '0170',
                                        '0240',
                                        '0260')
                THEN
                    'MRA3'
                WHEN AA.RQ_LINE_NBR IN ('0220')
                THEN
                    'MRA4'
                WHEN AA.RQ_LINE_NBR IN ('0280')
                THEN
                    'MRA5'
                WHEN AA.RQ_LINE_NBR IN ('0295')
                THEN
                    'MRA6'
                WHEN AA.RQ_LINE_NBR IN ('0310')
                THEN
                    'MRA7'
            END)                AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN ps_rpt.ps_SAA_ADB_RESULTS_v AA
               ON population.EMPLID = AA.EMPLID
     WHERE     AA.SAA_CAREER_RPT = 'UGRD'
           AND AA.TSCRPT_TYPE = 'ADV'
           AND AA.ENTRY_R_TYPE = 'KEYRQL'
           AND AA.RQRMNT_GROUP = '000026'
           AND AA.REQUIREMENT = '000101743'
           AND AA.RQ_LINE_NBR IN ('0100',
                                  '0140',
                                  '0150',
                                  '0160',
                                  '0165',
                                  '0170',
                                  '0200',
                                  '0210',
                                  '0215',
                                  '0220',
                                  '0240',
                                  '0260',
                                  '0280',
                                  '0295',
                                  '0310')
    UNION
    SELECT population.EMPLID AS STUDENT_ID, c.CURRENT_CAREER AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (SELECT s.STUDENT_ID, s.CAREERSOURCEKEY CURRENT_CAREER
              FROM (SELECT a.EFFECTIVE_DATE,
                           a.STUDENT_ID,
                           a.MAJOR_1,
                           p.PLANSOURCEKEY,
                           p.CAREERSOURCEKEY,
                           p.SUBPLANSOURCEKEY,
                           ROW_NUMBER ()
                               OVER (PARTITION BY a.STUDENT_ID
                                     ORDER BY a.EFFECTIVE_DATE DESC)    PLN_RNK
                      FROM PS_RPT.CMP_STUDENT_TERM_MAJOR_CURR_MV  a,
                           PS_RPT.LOK_ACAD_PLAN_V                 p
                     WHERE     p.SUBPLANSOURCEKEY = '-----'
                           AND TRIM (a.MAJOR_1) = p.PLANSOURCEKEY
                           AND a.EFFECTIVE_DATE <=
                               TO_CHAR (SYSDATE, 'YYYYMMDD')) s
             WHERE s.PLN_RNK = 1) c
               ON population.EMPLID = c.STUDENT_ID
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'ARC' AS CATEGORY_ID
      FROM PS_RPT.PS_STDNT_ADVR_HIST_V  a
           JOIN PS_RPT.CMP_POPULATION_CURRENT_V population
               ON a.EMPLID = population.EMPLID
     WHERE     a.COMMITTEE_ID = 'ARC'
           AND a.EFFDT =
               (SELECT MAX (b.effdt)
                  FROM PS_RPT.PS_STDNT_ADVR_HIST_V b
                 WHERE     a.emplid = b.emplid
                       AND a.institution = b.institution
                       AND a.advisor_role = b.advisor_role)
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'MBA' AS CATEGORY_ID
      FROM PS_RPT.PS_STDNT_ADVR_HIST_V  a
           JOIN PS_RPT.CMP_POPULATION_CURRENT_V population
               ON a.EMPLID = population.EMPLID
     WHERE     a.COMMITTEE_ID = 'MBA'
           AND a.EFFDT =
               (SELECT MAX (b.effdt)
                  FROM PS_RPT.PS_STDNT_ADVR_HIST_V b
                 WHERE     a.emplid = b.emplid
                       AND a.institution = b.institution
                       AND a.advisor_role = b.advisor_role)
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'TEACH' AS CATEGORY_ID
      FROM PS_RPT.PS_STDNT_ADVR_HIST_V  a
           JOIN PS_RPT.CMP_POPULATION_CURRENT_V population
               ON a.EMPLID = population.EMPLID
     WHERE     a.COMMITTEE_ID = 'TEACH'
           AND a.EFFDT =
               (SELECT MAX (b.effdt)
                  FROM PS_RPT.PS_STDNT_ADVR_HIST_V b
                 WHERE     a.emplid = b.emplid
                       AND a.institution = b.institution
                       AND a.advisor_role = b.advisor_role)
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'SPPS1' AS CATEGORY_ID
      FROM PS_RPT.PS_STDNT_ADVR_HIST_V  a
           JOIN PS_RPT.CMP_POPULATION_CURRENT_V population
               ON a.EMPLID = population.EMPLID
     WHERE     a.COMMITTEE_ID = 'SPPS1'
           AND a.EFFDT =
               (SELECT MAX (b.effdt)
                  FROM PS_RPT.PS_STDNT_ADVR_HIST_V b
                 WHERE     a.emplid = b.emplid
                       AND a.institution = b.institution
                       AND a.advisor_role = b.advisor_role)
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'PHHP' AS CATEGORY_ID
      FROM PS_RPT.PS_STDNT_ADVR_HIST_V  a
           JOIN PS_RPT.CMP_POPULATION_CURRENT_V population
               ON a.EMPLID = population.EMPLID
     WHERE     a.COMMITTEE_ID = 'PHHP'
           AND a.EFFDT =
               (SELECT MAX (b.effdt)
                  FROM PS_RPT.PS_STDNT_ADVR_HIST_V b
                 WHERE     a.emplid = b.emplid
                       AND a.institution = b.institution
                       AND a.advisor_role = b.advisor_role)
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'NUR' AS CATEGORY_ID
      FROM PS_RPT.PS_STDNT_ADVR_HIST_V  a
           JOIN PS_RPT.CMP_POPULATION_CURRENT_V population
               ON a.EMPLID = population.EMPLID
     WHERE     a.COMMITTEE_ID = 'NUR'
           AND a.EFFDT =
               (SELECT MAX (b.effdt)
                  FROM PS_RPT.PS_STDNT_ADVR_HIST_V b
                 WHERE     a.emplid = b.emplid
                       AND a.institution = b.institution
                       AND a.advisor_role = b.advisor_role)
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'LAW1' AS CATEGORY_ID
      FROM PS_RPT.PS_STDNT_ADVR_HIST_V  a
           JOIN PS_RPT.CMP_POPULATION_CURRENT_V population
               ON a.EMPLID = population.EMPLID
     WHERE     a.COMMITTEE_ID = 'LAW'
           AND a.EFFDT =
               (SELECT MAX (b.effdt)
                  FROM PS_RPT.PS_STDNT_ADVR_HIST_V b
                 WHERE     a.emplid = b.emplid
                       AND a.institution = b.institution
                       AND a.advisor_role = b.advisor_role)
    UNION
    SELECT population.EMPLID                                         AS STUDENT_ID,
           (CASE WHEN att.ATTS > 2 THEN 'MTHNO' ELSE 'MTHOK' END)    AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (SELECT s.STUDENT_ID, s.CAREERSOURCEKEY
              FROM (SELECT a.EFFECTIVE_DATE,
                           a.STUDENT_ID,
                           a.MAJOR_1,
                           p.PLANSOURCEKEY,
                           p.CAREERSOURCEKEY,
                           ROW_NUMBER ()
                               OVER (PARTITION BY a.STUDENT_ID
                                     ORDER BY a.EFFECTIVE_DATE DESC)    PLN_RNK
                      FROM PS_RPT.CMP_STUDENT_TERM_MAJOR_CURR_MV  a,
                           PS_RPT.LOK_ACAD_PLAN_V                 p
                     WHERE     p.SUBPLANSOURCEKEY = '-----'
                           AND TRIM (a.MAJOR_1) = p.PLANSOURCEKEY
                           AND a.EFFECTIVE_DATE <=
                               TO_CHAR (SYSDATE, 'YYYYMMDD')) s
             WHERE s.PLN_RNK = 1) s1
               ON     population.EMPLID = s1.STUDENT_ID
                  AND s1.CAREERSOURCEKEY = 'UGRD'
           LEFT JOIN
           (  SELECT m.EMPLID,
                     m.TEST_ID,
                     m.TEST_COMPONENT,
                     COUNT (DISTINCT m.TEST_DT)     ATTS
                FROM PS_RPT.PS_STDNT_TEST_COMP_V m
               WHERE     m.TEST_ID = 'MATH'
                     AND m.TEST_COMPONENT = 'OVRL'
                     AND m.TEST_ADMIN = 'Y'
            GROUP BY m.EMPLID, m.TEST_ID, m.TEST_COMPONENT) att
               ON population.EMPLID = att.EMPLID
    UNION
    SELECT population.EMPLID            AS STUDENT_ID,
           'MJ' || F.GROUPSOURCEKEY     AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (SELECT DISTINCT A.EMPLID, A.ACAD_PROG, P.GROUPSOURCEKEY
              FROM ps_rpt.PS_ACAD_PROG_V  A
                   INNER JOIN ps_rpt.LOK_ACAD_PROG_v P
                       ON A.ACAD_PROG = P.SOURCEKEY
             WHERE     A.EFFDT =
                       (SELECT MAX (A_ED.EFFDT)
                          FROM ps_rpt.PS_ACAD_PROG_V A_ED
                         WHERE     A.EMPLID = A_ED.EMPLID
                               AND A.ACAD_CAREER = A_ED.ACAD_CAREER
                               AND A.STDNT_CAR_NBR = A_ED.STDNT_CAR_NBR
                               AND A_ED.EFFDT > SYSDATE)
                   AND A.EFFSEQ =
                       (SELECT MAX (A_ES.EFFSEQ)
                          FROM ps_rpt.PS_ACAD_PROG_V A_ES
                         WHERE     A.EMPLID = A_ES.EMPLID
                               AND A.ACAD_CAREER = A_ES.ACAD_CAREER
                               AND A.STDNT_CAR_NBR = A_ES.STDNT_CAR_NBR
                               AND A.EFFDT = A_ES.EFFDT)
                   AND A.PROG_STATUS = 'AC'
                   AND A.ACAD_CAREER = 'UGRD'
                   AND EXISTS
                           (SELECT 'X'
                              FROM ps_rpt.PS_STDNT_ADVR_HIST_V C
                             WHERE     A.EMPLID = C.EMPLID
                                   AND A.ACAD_CAREER = C.ACAD_CAREER
                                   AND A.INSTITUTION = C.INSTITUTION
                                   AND C.ADVISOR_ROLE = 'ADVR'
                                   AND C.EFFDT <= SYSDATE)
                   AND NOT EXISTS
                           (SELECT 'X'
                              FROM ps_rpt.PS_STDNT_ADVR_HIST_V D
                             WHERE     A.EMPLID = D.EMPLID
                                   AND A.ACAD_CAREER = D.ACAD_CAREER
                                   AND A.INSTITUTION = D.INSTITUTION
                                   AND SUBSTR (A.ACAD_PROG, 0, 2) =
                                       SUBSTR (D.ACAD_PROG, 0, 2)
                                   AND D.ADVISOR_ROLE = 'ADVR')) F
               ON population.EMPLID = F.EMPLID
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'RLOA' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (SELECT A.EMPLID
              FROM ps_rpt.PS_ACAD_PROG_v A
             WHERE     A.INSTITUTION = 'UBFLO'
                   AND A.EFFDT =
                       (SELECT MIN (A_ED.EFFDT)
                          FROM ps_rpt.PS_ACAD_PROG_v A_ED
                         WHERE     A.EMPLID = A_ED.EMPLID
                               AND A.ACAD_CAREER = A_ED.ACAD_CAREER
                               AND A.STDNT_CAR_NBR = A_ED.STDNT_CAR_NBR
                               AND A_ED.EFFDT > SYSDATE)
                   AND A.EFFSEQ =
                       (SELECT MAX (A_ES.EFFSEQ)
                          FROM ps_rpt.PS_ACAD_PROG_v A_ES
                         WHERE     A.EMPLID = A_ES.EMPLID
                               AND A.ACAD_CAREER = A_ES.ACAD_CAREER
                               AND A.STDNT_CAR_NBR = A_ES.STDNT_CAR_NBR
                               AND A.EFFDT = A_ES.EFFDT)
                   AND A.PROG_STATUS = 'AC'
                   AND A.PROG_ACTION = 'RLOA'
                   AND A.ACAD_CAREER = 'UGRD'
                   AND A.ACAD_PROG LIKE '__R3') F
               ON population.EMPLID = F.EMPLID
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'LATE199' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (SELECT s.*
              FROM (SELECT TO_CHAR (A.DTTM_STAMP_SEC, 'DD-MON-YYYY')
                               ADD_DATE,
                           A.EMPLID,
                           A.ACAD_CAREER,
                           A.INSTITUTION,
                           A.STRM,
                           A.CLASS_NBR,
                           A.ENRL_REQ_ACTION,
                           A.ENRL_REQ_DETL_STAT,
                           B.SUBJECT,
                           B.CATALOG_NBR,
                           B.DESCR,
                           TO_CHAR (t.TERM_BEGIN_DT, 'DD-MON-YYYY')
                               BOT,
                           ROW_NUMBER ()
                               OVER (
                                   PARTITION BY A.EMPLID,
                                                A.ACAD_CAREER,
                                                A.INSTITUTION
                                   ORDER BY A.DTTM_STAMP_SEC)
                               RNK
                      FROM ps_rpt.PS_ENRL_REQ_DETAIL_v  A
                           INNER JOIN ps_rpt.PS_CLASS_TBL_v B
                               ON     B.STRM = A.STRM
                                  AND A.CLASS_NBR = B.CLASS_NBR
                           INNER JOIN ps_rpt.PS_TERM_TBL_v t
                               ON     B.STRM = t.STRM
                                  AND B.ACAD_CAREER = t.ACAD_CAREER
                                  AND B.INSTITUTION = t.INSTITUTION
                     WHERE     A.ACAD_CAREER = 'UGRD'
                           AND A.INSTITUTION = 'UBFLO'
                           AND A.STRM >= '2179'
                           AND B.CATALOG_NBR LIKE '_199%'
                           AND A.ENRL_REQ_ACTION = 'E'
                           AND A.ENRL_REQ_DETL_STAT IN ('S', 'M')) s
             WHERE s.RNK = 1 AND MONTHS_BETWEEN (s.BOT, s.ADD_DATE) < 1) s1
               ON population.EMPLID = s1.EMPLID
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'REGES' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (SELECT DISTINCT
                   V1.STRM                                TARGET_TRM,
                   V1.INSTITUTION,
                   V1.FIRST_ENRL_DT,
                   V1.ENROLL_OPEN_DT,
                   ap.APPT_START_DT,
                   (CASE
                        WHEN ap.APPT_START_DT IS NULL
                        THEN
                            V1.ENROLL_OPEN_DT
                        ELSE
                            TO_DATE (
                                   SUBSTR (ap.APPT_START_DT, 6, 2)
                                || '/'
                                || SUBSTR (ap.APPT_START_DT, 9, 2)
                                || '/'
                                || SUBSTR (ap.APPT_START_DT, 1, 4),
                                'MM/DD/YYYY')
                    END)                                  ENR_ELG_DT,
                   TO_CHAR (V1.END_DT, 'YYYY-MM-DD')      ENR_END,
                   V1.EMPLID                              "EMPLID",
                   V1.ACAD_CAREER,
                   V1.ACAD_PROG_PRIMARY,
                   V1.PROG_STATUS,
                   V1.ADMIT_TERM,
                   V1.EXP_GRAD_TERM,
                   V1.DEGR_CHKOUT_STAT,
                   V1."Prev Regular Term",
                   V1."Prev Enrolled Term",
                   COUNT (DISTINCT x.CLASS_NBR)
                       OVER (
                           PARTITION BY x.INSTITUTION,
                                        x.EMPLID,
                                        x.ACAD_CAREER)    CRSES
              FROM (SELECT DISTINCT A.STRM,
                                    A.INSTITUTION,
                                    B.FIRST_ENRL_DT,
                                    B.ENROLL_OPEN_DT,
                                    C.END_DT,
                                    D.EMPLID     "EMPLID",
                                    D.ACAD_CAREER,
                                    D.ACAD_PROG_PRIMARY,
                                    E.PROG_STATUS,
                                    E.ADMIT_TERM,
                                    E.EXP_GRAD_TERM,
                                    E.DEGR_CHKOUT_STAT,
                                    "Prev Regular Term",
                                    "Prev Enrolled Term"
                      FROM PS_RPT.PS_TERM_TBL_V             A,
                           PS_RPT.PS_SESSION_TBL_V          B,
                           PS_RPT.PS_SESS_TIME_PEROD_V      C,
                           PS_RPT.PS_STDNT_CAR_TERM_V       D,
                           PS_RPT.PS_ACAD_PROG_V            E,
                           PS_RPT.PS_ACAD_PLAN_V            F,
                           PS_RPT.cmp_POPULATION_CURRENT_V  Z,
                           ---rank Fall and Spring terms starting with the most recent; a term becomes rankable only after the add/drop date
                            (SELECT A.STRM                             "Prev Regular Term",
                                    A.ACAD_CAREER                      "Career",
                                    ROW_NUMBER ()
                                        OVER (PARTITION BY A.ACAD_CAREER
                                              ORDER BY A.STRM DESC)    "Prev Regular Term Rank"
                               FROM PS_RPT.PS_TERM_TBL_V         A,
                                    PS_RPT.PS_SESSION_TBL_V      B,
                                    PS_RPT.PS_SESS_TIME_PEROD_V  C
                              WHERE     B.SESSION_CODE = A.SESSION_CODE
                                    AND B.STRM = A.STRM
                                    AND B.ACAD_CAREER = A.ACAD_CAREER
                                    AND B.INSTITUTION = A.INSTITUTION
                                    AND C.INSTITUTION = B.INSTITUTION
                                    AND C.ACAD_CAREER = B.ACAD_CAREER
                                    AND C.STRM = B.STRM
                                    AND C.SESSION_CODE = B.SESSION_CODE
                                    AND A.TERM_CATEGORY = 'R'
                                    AND B.SESSION_CODE = '1'
                                    AND C.TIME_PERIOD = '135'
                                    AND C.END_DT < SYSDATE
                                    AND A.ACAD_CAREER = 'UGRD') prevreg,
                           ---rank previous enrolled Fall and Spring terms starting with the most recent
                            (SELECT I.EMPLID                         "Emplid",
                                    I.ACAD_CAREER                    "Career",
                                    I.STRM                           "Prev Enrolled Term",
                                    ROW_NUMBER ()
                                        OVER (
                                            PARTITION BY I.EMPLID,
                                                         I.ACAD_CAREER
                                            ORDER BY I.STRM DESC)    "Prev Enrolled Term Rank"
                               FROM PS_RPT.PS_STDNT_ENRL_V  I,
                                    PS_RPT.PS_TERM_TBL_V    T
                              WHERE     I.STRM = T.STRM
                                    AND I.ACAD_CAREER = T.ACAD_CAREER
                                    AND I.ACAD_CAREER = 'UGRD'
                                    AND I.STDNT_ENRL_STATUS = 'E'
                                    AND T.TERM_CATEGORY = 'R') prevenr
                     WHERE     Z.EMPLID = D.EMPLID
                           AND Z.STRM = D.STRM
                           AND D.EMPLID = prevenr."Emplid"
                           AND D.ACAD_CAREER = prevenr."Career"
                           AND prevenr."Prev Enrolled Term Rank" = 1
                           AND prevreg."Prev Regular Term Rank" = 1
                           AND prevreg."Prev Regular Term" =
                               prevenr."Prev Enrolled Term"
                           AND (   (E.EXP_GRAD_TERM = ' ')
                                OR (E.EXP_GRAD_TERM >= A.STRM)
                                OR (    E.EXP_GRAD_TERM < A.STRM
                                    AND E.DEGR_CHKOUT_STAT = 'DN'))
                           AND B.SESSION_CODE = A.SESSION_CODE
                           AND B.STRM = A.STRM
                           AND B.ACAD_CAREER = A.ACAD_CAREER
                           AND B.INSTITUTION = A.INSTITUTION
                           AND C.INSTITUTION = B.INSTITUTION
                           AND C.ACAD_CAREER = B.ACAD_CAREER
                           AND C.STRM = B.STRM
                           AND C.SESSION_CODE = B.SESSION_CODE
                           AND A.TERM_CATEGORY = 'R'
                           AND B.SESSION_CODE = '1'
                           AND C.TIME_PERIOD = '135'
                           AND C.END_DT >= SYSDATE
                           AND A.ACAD_CAREER = 'UGRD'
                           AND C.INSTITUTION = D.INSTITUTION
                           AND C.ACAD_CAREER = D.ACAD_CAREER
                           AND C.STRM = D.STRM
                           AND D.ACAD_LEVEL_BOT NOT LIKE 'ND'
                           AND                 ---D.UNT_TAKEN_PRGRSS = '0' AND
                               D.EMPLID = E.EMPLID
                           AND D.ACAD_CAREER = E.ACAD_CAREER
                           AND D.INSTITUTION = E.INSTITUTION
                           AND F.EMPLID = E.EMPLID
                           AND F.ACAD_CAREER = E.ACAD_CAREER
                           AND F.STDNT_CAR_NBR = E.STDNT_CAR_NBR
                           AND F.EFFDT = E.EFFDT
                           AND F.EFFSEQ = E.EFFSEQ
                           AND E.EFFDT =
                               (SELECT MAX (E_ED.EFFDT)
                                  FROM PS_RPT.PS_ACAD_PROG_V E_ED
                                 WHERE     E.EMPLID = E_ED.EMPLID
                                       AND E.ACAD_CAREER = E_ED.ACAD_CAREER
                                       AND E.STDNT_CAR_NBR =
                                           E_ED.STDNT_CAR_NBR
                                       AND E.EFFDT <= A.TERM_END_DT)
                           AND E.EFFSEQ =
                               (SELECT MAX (E_ES.EFFSEQ)
                                  FROM PS_RPT.PS_ACAD_PROG_V E_ES
                                 WHERE     E.EMPLID = E_ES.EMPLID
                                       AND E.ACAD_CAREER = E_ES.ACAD_CAREER
                                       AND E.STDNT_CAR_NBR =
                                           E_ES.STDNT_CAR_NBR
                                       AND E.EFFDT = E_ES.EFFDT)
                           AND ---limit to students with active program status; filter select Plans
                               E.PROG_STATUS = 'AC'
                           AND F.ACAD_PLAN NOT LIKE '______X%'
                           AND F.ACAD_PLAN NOT IN ('MBC031R0',
                                                   'ICE012R0A',
                                                   'ICE012R0I',
                                                   'ICE012R5A',
                                                   'ICE012R5I',
                                                   'IEE012R5I',
                                                   'IEE012R0A',
                                                   'IEE012R0I',
                                                   'IEE012R5A')
                           AND (E.ACAD_PROG NOT LIKE '__N_')
                           AND           ---exclude certain Academic Standings
                               NOT EXISTS
                                   (SELECT 'X'
                                      FROM PS_RPT.PS_ACAD_STDNG_ACTN_V G
                                     WHERE     G.EFFDT =
                                               (SELECT MAX (G_ED.EFFDT)
                                                  FROM PS_RPT.PS_ACAD_STDNG_ACTN_V
                                                       G_ED
                                                 WHERE     G.EMPLID =
                                                           G_ED.EMPLID
                                                       AND G.ACAD_CAREER =
                                                           G_ED.ACAD_CAREER
                                                       AND G.INSTITUTION =
                                                           G_ED.INSTITUTION)
                                           AND G.EFFSEQ =
                                               (SELECT MAX (G_ES.EFFSEQ)
                                                  FROM PS_RPT.PS_ACAD_STDNG_ACTN_V
                                                       G_ES
                                                 WHERE     G.EMPLID =
                                                           G_ES.EMPLID
                                                       AND G.ACAD_CAREER =
                                                           G_ES.ACAD_CAREER
                                                       AND G.INSTITUTION =
                                                           G_ES.INSTITUTION
                                                       AND G.EFFDT =
                                                           G_ES.EFFDT)
                                           AND G.EMPLID = D.EMPLID
                                           AND G.ACAD_CAREER = D.ACAD_CAREER
                                           AND G.INSTITUTION = D.INSTITUTION
                                           AND G.ACAD_STNDNG_ACTN IN ('COND',
                                                                      'APPL',
                                                                      'APSU',
                                                                      'DISD',
                                                                      'DISM',
                                                                      'DISV'))
                           AND ---exclude students term-activated in other Careers
                               NOT EXISTS
                                   (SELECT 'X'
                                      FROM PS_RPT.PS_STDNT_CAR_TERM_V H
                                     WHERE     H.EMPLID = D.EMPLID
                                           AND H.STRM = D.STRM
                                           AND H.ACAD_CAREER <> D.ACAD_CAREER))
                   V1
                   INNER JOIN PS_RPT.PS_SSR_REGFORM_V x
                       ON     V1.INSTITUTION = x.INSTITUTION
                          AND V1.EMPLID = x.EMPLID
                          AND V1.STRM = x.STRM
                          AND V1.ACAD_CAREER = x.ACAD_CAREER
                   LEFT JOIN PS_RPT.STUDENT_APPOINTMENT_V ap
                       ON     V1.INSTITUTION = ap.INSTITUTION
                          AND V1.EMPLID = ap.EMPLID
                          AND V1.STRM = ap.STRM
                          AND V1.ACAD_CAREER = ap.ACAD_CAREER) e
               ON population.EMPLID = e.EMPLID
     WHERE e.ENR_ELG_DT <= SYSDATE
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'RSGNA' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (  SELECT e.INSTITUTION,
                     e.STRM,
                     e.EMPLID,
                     e.ACAD_CAREER,
                     SUM (e.UNT_TAKEN)                                       T_UNITS,
                     SUM (DECODE (e.CRSE_GRADE_OFF, 'R', e.UNT_TAKEN, 0))    R_UNITS
                FROM PS_RPT.PS_STDNT_ENRL_V e
                     INNER JOIN PS_RPT.PS_TERM_TBL_V t
                         ON     e.INSTITUTION = t.INSTITUTION
                            AND e.ACAD_CAREER = t.ACAD_CAREER
                            AND e.STRM = t.STRM
               WHERE     e.INSTITUTION = 'UBFLO'
                     AND e.ACAD_CAREER = 'UGRD'
                     AND e.STDNT_ENRL_STATUS = 'E'
                     AND e.UNT_TAKEN <> 0
                     AND SYSDATE BETWEEN t.TERM_BEGIN_DT AND t.TERM_END_DT
            GROUP BY e.INSTITUTION,
                     e.STRM,
                     e.EMPLID,
                     e.ACAD_CAREER
              HAVING SUM (DECODE (e.CRSE_GRADE_OFF, 'R', e.UNT_TAKEN, 0)) =
                     SUM (e.UNT_TAKEN)) r
               ON population.EMPLID = r.EMPLID
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'REGE' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (SELECT V1.STRM                              TARGET_TRM,
                   V1.INSTITUTION,
                   V1.FIRST_ENRL_DT,
                   V1.ENROLL_OPEN_DT,
                   ap.APPT_START_DT,
                   (CASE
                        WHEN ap.APPT_START_DT IS NULL
                        THEN
                            V1.ENROLL_OPEN_DT
                        ELSE
                            TO_DATE (
                                   SUBSTR (ap.APPT_START_DT, 6, 2)
                                || '/'
                                || SUBSTR (ap.APPT_START_DT, 9, 2)
                                || '/'
                                || SUBSTR (ap.APPT_START_DT, 1, 4),
                                'MM/DD/YYYY')
                    END)                                ENR_ELG_DT,
                   TO_CHAR (V1.END_DT, 'YYYY-MM-DD')    ENR_END,
                   V1.EMPLID                            "EMPLID",
                   V1.ACAD_CAREER,
                   V1.ACAD_PROG_PRIMARY,
                   V1.PROG_STATUS,
                   V1.ADMIT_TERM,
                   V1.EXP_GRAD_TERM,
                   V1.DEGR_CHKOUT_STAT,
                   V1."Prev Regular Term",
                   V1."Prev Enrolled Term"
              FROM (SELECT DISTINCT A.STRM,
                                    A.INSTITUTION,
                                    B.FIRST_ENRL_DT,
                                    B.ENROLL_OPEN_DT,
                                    C.END_DT,
                                    D.EMPLID     "EMPLID",
                                    D.ACAD_CAREER,
                                    D.ACAD_PROG_PRIMARY,
                                    E.PROG_STATUS,
                                    E.ADMIT_TERM,
                                    E.EXP_GRAD_TERM,
                                    E.DEGR_CHKOUT_STAT,
                                    "Prev Regular Term",
                                    "Prev Enrolled Term"
                      FROM PS_RPT.PS_TERM_TBL_V             A,
                           PS_RPT.PS_SESSION_TBL_V          B,
                           PS_RPT.PS_SESS_TIME_PEROD_V      C,
                           PS_RPT.PS_STDNT_CAR_TERM_V       D,
                           PS_RPT.PS_ACAD_PROG_V            E,
                           PS_RPT.PS_ACAD_PLAN_V            F,
                           PS_RPT.cmp_POPULATION_CURRENT_V  Z,
                           ---rank Fall and Spring terms starting with the most recent; a term becomes rankable only after the add/drop date
                            (SELECT A.STRM                             "Prev Regular Term",
                                    A.ACAD_CAREER                      "Career",
                                    ROW_NUMBER ()
                                        OVER (PARTITION BY A.ACAD_CAREER
                                              ORDER BY A.STRM DESC)    "Prev Regular Term Rank"
                               FROM PS_RPT.PS_TERM_TBL_V         A,
                                    PS_RPT.PS_SESSION_TBL_V      B,
                                    PS_RPT.PS_SESS_TIME_PEROD_V  C
                              WHERE     B.SESSION_CODE = A.SESSION_CODE
                                    AND B.STRM = A.STRM
                                    AND B.ACAD_CAREER = A.ACAD_CAREER
                                    AND B.INSTITUTION = A.INSTITUTION
                                    AND C.INSTITUTION = B.INSTITUTION
                                    AND C.ACAD_CAREER = B.ACAD_CAREER
                                    AND C.STRM = B.STRM
                                    AND C.SESSION_CODE = B.SESSION_CODE
                                    AND A.TERM_CATEGORY = 'R'
                                    AND B.SESSION_CODE = '1'
                                    AND C.TIME_PERIOD = '135'
                                    AND C.END_DT < SYSDATE
                                    AND A.ACAD_CAREER = 'UGRD') prevreg,
                           ---rank previous enrolled Fall and Spring terms starting with the most recent
                            (SELECT I.EMPLID                         "Emplid",
                                    I.ACAD_CAREER                    "Career",
                                    I.STRM                           "Prev Enrolled Term",
                                    ROW_NUMBER ()
                                        OVER (
                                            PARTITION BY I.EMPLID,
                                                         I.ACAD_CAREER
                                            ORDER BY I.STRM DESC)    "Prev Enrolled Term Rank"
                               FROM PS_RPT.PS_STDNT_ENRL_V  I,
                                    PS_RPT.PS_TERM_TBL_V    T
                              WHERE     I.STRM = T.STRM
                                    AND I.ACAD_CAREER = T.ACAD_CAREER
                                    AND I.ACAD_CAREER = 'UGRD'
                                    AND I.STDNT_ENRL_STATUS = 'E'
                                    AND T.TERM_CATEGORY = 'R') prevenr
                     WHERE     Z.EMPLID = D.EMPLID
                           AND Z.STRM = D.STRM
                           AND D.EMPLID = prevenr."Emplid"
                           AND D.ACAD_CAREER = prevenr."Career"
                           AND prevenr."Prev Enrolled Term Rank" = 1
                           AND prevreg."Prev Regular Term Rank" = 1
                           AND prevreg."Prev Regular Term" =
                               prevenr."Prev Enrolled Term"
                           AND (   (E.EXP_GRAD_TERM = ' ')
                                OR (E.EXP_GRAD_TERM >= A.STRM)
                                OR (    E.EXP_GRAD_TERM < A.STRM
                                    AND E.DEGR_CHKOUT_STAT = 'DN'))
                           AND B.SESSION_CODE = A.SESSION_CODE
                           AND B.STRM = A.STRM
                           AND B.ACAD_CAREER = A.ACAD_CAREER
                           AND B.INSTITUTION = A.INSTITUTION
                           AND C.INSTITUTION = B.INSTITUTION
                           AND C.ACAD_CAREER = B.ACAD_CAREER
                           AND C.STRM = B.STRM
                           AND C.SESSION_CODE = B.SESSION_CODE
                           AND A.TERM_CATEGORY = 'R'
                           AND B.SESSION_CODE = '1'
                           AND C.TIME_PERIOD = '135'
                           AND C.END_DT >= SYSDATE
                           AND A.ACAD_CAREER = 'UGRD'
                           AND C.INSTITUTION = D.INSTITUTION
                           AND C.ACAD_CAREER = D.ACAD_CAREER
                           AND C.STRM = D.STRM
                           AND D.ACAD_LEVEL_BOT NOT LIKE 'ND'
                           AND                 ---D.UNT_TAKEN_PRGRSS = '0' AND
                               D.EMPLID = E.EMPLID
                           AND D.ACAD_CAREER = E.ACAD_CAREER
                           AND D.INSTITUTION = E.INSTITUTION
                           AND F.EMPLID = E.EMPLID
                           AND F.ACAD_CAREER = E.ACAD_CAREER
                           AND F.STDNT_CAR_NBR = E.STDNT_CAR_NBR
                           AND F.EFFDT = E.EFFDT
                           AND F.EFFSEQ = E.EFFSEQ
                           AND E.EFFDT =
                               (SELECT MAX (E_ED.EFFDT)
                                  FROM PS_RPT.PS_ACAD_PROG_V E_ED
                                 WHERE     E.EMPLID = E_ED.EMPLID
                                       AND E.ACAD_CAREER = E_ED.ACAD_CAREER
                                       AND E.STDNT_CAR_NBR =
                                           E_ED.STDNT_CAR_NBR
                                       AND E.EFFDT <= A.TERM_END_DT)
                           AND E.EFFSEQ =
                               (SELECT MAX (E_ES.EFFSEQ)
                                  FROM PS_RPT.PS_ACAD_PROG_V E_ES
                                 WHERE     E.EMPLID = E_ES.EMPLID
                                       AND E.ACAD_CAREER = E_ES.ACAD_CAREER
                                       AND E.STDNT_CAR_NBR =
                                           E_ES.STDNT_CAR_NBR
                                       AND E.EFFDT = E_ES.EFFDT)
                           AND ---limit to students with active program status; filter select Plans
                               E.PROG_STATUS = 'AC'
                           AND F.ACAD_PLAN NOT LIKE '______X%'
                           AND F.ACAD_PLAN NOT IN ('MBC031R0',
                                                   'ICE012R0A',
                                                   'ICE012R0I',
                                                   'ICE012R5A',
                                                   'ICE012R5I',
                                                   'IEE012R5I',
                                                   'IEE012R0A',
                                                   'IEE012R0I',
                                                   'IEE012R5A')
                           AND (E.ACAD_PROG NOT LIKE '__N_')
                           AND           ---exclude certain Academic Standings
                               NOT EXISTS
                                   (SELECT 'X'
                                      FROM PS_RPT.PS_ACAD_STDNG_ACTN_V G
                                     WHERE     G.EFFDT =
                                               (SELECT MAX (G_ED.EFFDT)
                                                  FROM PS_RPT.PS_ACAD_STDNG_ACTN_V
                                                       G_ED
                                                 WHERE     G.EMPLID =
                                                           G_ED.EMPLID
                                                       AND G.ACAD_CAREER =
                                                           G_ED.ACAD_CAREER
                                                       AND G.INSTITUTION =
                                                           G_ED.INSTITUTION)
                                           AND G.EFFSEQ =
                                               (SELECT MAX (G_ES.EFFSEQ)
                                                  FROM PS_RPT.PS_ACAD_STDNG_ACTN_V
                                                       G_ES
                                                 WHERE     G.EMPLID =
                                                           G_ES.EMPLID
                                                       AND G.ACAD_CAREER =
                                                           G_ES.ACAD_CAREER
                                                       AND G.INSTITUTION =
                                                           G_ES.INSTITUTION
                                                       AND G.EFFDT =
                                                           G_ES.EFFDT)
                                           AND G.EMPLID = D.EMPLID
                                           AND G.ACAD_CAREER = D.ACAD_CAREER
                                           AND G.INSTITUTION = D.INSTITUTION
                                           AND G.ACAD_STNDNG_ACTN IN ('COND',
                                                                      'APPL',
                                                                      'APSU',
                                                                      'DISD',
                                                                      'DISM',
                                                                      'DISV'))
                           AND ---exclude students term-activated in other Careers
                               NOT EXISTS
                                   (SELECT 'X'
                                      FROM PS_RPT.PS_STDNT_CAR_TERM_V H
                                     WHERE     H.EMPLID = D.EMPLID
                                           AND H.STRM = D.STRM
                                           AND H.ACAD_CAREER <> D.ACAD_CAREER))
                   V1
                   LEFT JOIN PS_RPT.STUDENT_APPOINTMENT_V ap
                       ON     V1.INSTITUTION = ap.INSTITUTION
                          AND V1.EMPLID = ap.EMPLID
                          AND V1.STRM = ap.STRM
                          AND V1.ACAD_CAREER = ap.ACAD_CAREER) e
               ON population.EMPLID = e.EMPLID
     WHERE e.ENR_ELG_DT <= SYSDATE
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'COACH' AS CATEGORY_ID
      FROM PS_RPT.PS_STDNT_ADVR_HIST_V  a
           JOIN PS_RPT.CMP_POPULATION_CURRENT_V population
               ON a.EMPLID = population.EMPLID
     WHERE     a.COMMITTEE_ID IN ('COACH')
           AND a.EFFDT =
               (SELECT MAX (b.effdt)
                  FROM PS_RPT.PS_STDNT_ADVR_HIST_V b
                 WHERE a.emplid = b.emplid AND a.institution = b.institution)
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'MPH' AS CATEGORY_ID
      FROM PS_RPT.PS_STDNT_ADVR_HIST_V  a
           JOIN PS_RPT.CMP_POPULATION_CURRENT_V population
               ON a.EMPLID = population.EMPLID
     WHERE     a.COMMITTEE_ID IN ('MPH')
           AND a.EFFDT =
               (SELECT MAX (b.effdt)
                  FROM PS_RPT.PS_STDNT_ADVR_HIST_V b
                 WHERE a.emplid = b.emplid AND a.institution = b.institution)
    UNION
    SELECT population.EMPLID                      AS STUDENT_ID,
           l.ACAD_CAREER || ' ' || l.PHRM_LVL     AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (WITH
                TRM
                AS
                    (SELECT ACAD_CAREER,
                            INSTITUTION,
                            STRM,
                            DESCR,
                            TERM_BEGIN_DT,
                            TERM_END_DT,
                            LEAD (TERM_BEGIN_DT)
                                OVER (PARTITION BY ACAD_CAREER, INSTITUTION
                                      ORDER BY STRM)    NXT_BOT
                       FROM ps_rpt.PS_TERM_TBL_v)
            SELECT A.EMPLID,
                   A.ACAD_CAREER,
                   A.INSTITUTION,
                   A.STRM,
                   A.ACAD_LEVEL_BOT     PHRM_LVL
              FROM ps_rpt.PS_STDNT_CAR_TERM_v  A
                   INNER JOIN TRM
                       ON     TRM.STRM = A.STRM
                          AND TRM.ACAD_CAREER = A.ACAD_CAREER
                          AND TRM.INSTITUTION = A.INSTITUTION
                          AND (   SYSDATE BETWEEN TRM.TERM_BEGIN_DT
                                              AND TERM_END_DT
                               OR SYSDATE BETWEEN TRM.TERM_END_DT
                                              AND TRM.NXT_BOT)
             WHERE A.INSTITUTION = 'UBFLO' AND A.ACAD_CAREER = 'PHRM') l
               ON population.EMPLID = l.EMPLID
    UNION
    SELECT population.EMPLID                          AS STUDENT_ID,
           l2.ACAD_CAREER || ' JD ' || l2.LAW_LVL     AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (WITH
                TRM
                AS
                    (SELECT ACAD_CAREER,
                            INSTITUTION,
                            STRM,
                            DESCR,
                            TERM_BEGIN_DT,
                            TERM_END_DT,
                            LEAD (TERM_BEGIN_DT)
                                OVER (PARTITION BY ACAD_CAREER, INSTITUTION
                                      ORDER BY STRM)    NXT_BOT
                       FROM ps_rpt.PS_TERM_TBL_v)
            SELECT A.EMPLID,
                   A.ACAD_CAREER,
                   A.INSTITUTION,
                   A.STRM,
                   A.ACAD_LEVEL_BOT     LAW_LVL
              FROM ps_rpt.PS_STDNT_CAR_TERM_v  A
                   INNER JOIN TRM
                       ON     TRM.STRM = A.STRM
                          AND TRM.ACAD_CAREER = A.ACAD_CAREER
                          AND TRM.INSTITUTION = A.INSTITUTION
                          AND (   SYSDATE BETWEEN TRM.TERM_BEGIN_DT
                                              AND TERM_END_DT
                               OR SYSDATE BETWEEN TRM.TERM_END_DT
                                              AND TRM.NXT_BOT)
             WHERE     A.INSTITUTION = 'UBFLO'
                   AND A.ACAD_PROG_PRIMARY NOT IN ('10R8', '10N0')
                   AND A.ACAD_CAREER = 'LAW') l2
               ON population.EMPLID = l2.EMPLID
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'BPS' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN (SELECT A.EMPLID,
                              A.EXT_ORG_ID,
                              A.EXT_CAREER,
                              A.EXT_DATA_NBR,
                              A.EXT_SUMM_TYPE,
                              A.EXT_ACAD_LEVEL,
                              A.TERM_YEAR,
                              A.EXT_TERM_TYPE,
                              A.EXT_TERM,
                              A.INSTITUTION,
                              A.UNT_TYPE,
                              A.UNT_ATMP_TOTAL,
                              A.UNT_COMP_TOTAL,
                              A.CLASS_RANK,
                              A.CLASS_SIZE,
                              A.GPA_TYPE,
                              A.EXT_GPA,
                              A.CONVERT_GPA,
                              A.PERCENTILE,
                              A.RANK_TYPE
                         FROM ps_rpt.PS_EXT_ACAD_SUM_v A
                        WHERE     A.EXT_ORG_ID IN ('1015838',
                                                   '1015795',
                                                   '1015796',
                                                   '50381551',
                                                   '1015800',
                                                   '1015804',
                                                   '1015807',
                                                   '1015822',
                                                   '1015859',
                                                   '101828',
                                                   '1015848',
                                                   '1015836',
                                                   '50382151',
                                                   '1015837',
                                                   '50294330',
                                                   '1015818',
                                                   '1015839',
                                                   '1015849',
                                                   '50263536',
                                                   '50380263',
                                                   '50440604',
                                                   '1015850',
                                                   '10155858',
                                                   '1040660',
                                                   '50263536')
                              AND A.EXT_SUMM_TYPE = 'HSOV') bps
               ON population.EMPLID = bps.EMPLID
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'DOCN' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (SELECT A.EMPLID,
                   A.ACAD_CAREER,
                   A.STDNT_CAR_NBR,
                   TO_CHAR (A.EFFDT, 'YYYY-MM-DD'),
                   A.EFFSEQ,
                   A.INSTITUTION,
                   A.ACAD_PROG,
                   A.PROG_STATUS
              FROM ps_rpt.PS_ACAD_PROG_v A
             WHERE (    A.EFFDT =
                        (SELECT MAX (A_ED.EFFDT)
                           FROM ps_rpt.PS_ACAD_PROG_v A_ED
                          WHERE     A.EMPLID = A_ED.EMPLID
                                AND A.ACAD_CAREER = A_ED.ACAD_CAREER
                                AND A.STDNT_CAR_NBR = A_ED.STDNT_CAR_NBR
                                AND A_ED.EFFDT <= SYSDATE)
                    AND A.EFFSEQ =
                        (SELECT MAX (A_ES.EFFSEQ)
                           FROM ps_rpt.PS_ACAD_PROG_v A_ES
                          WHERE     A.EMPLID = A_ES.EMPLID
                                AND A.ACAD_CAREER = A_ES.ACAD_CAREER
                                AND A.STDNT_CAR_NBR = A_ES.STDNT_CAR_NBR
                                AND A.EFFDT = A_ES.EFFDT)
                    AND A.INSTITUTION = 'UBFLO'
                    AND A.PROG_STATUS = 'AC'
                    AND SUBSTR (A.ACAD_PROG, 4, 1) IN ('5', '6'))) F
               ON population.EMPLID = F.EMPLID
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'DOC' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (SELECT DISTINCT A.EMPLID, A.ACAD_CAREER, C.DEGREE
              FROM ps_rpt.PS_ACAD_PROG_v      A,
                   ps_rpt.PS_ACAD_PLAN_v      B,
                   ps_rpt.PS_ACAD_PLAN_TBL_v  C,
                   ps_rpt.PS_TERM_TBL_v       t
             WHERE     B.EMPLID = A.EMPLID
                   AND B.ACAD_CAREER = A.ACAD_CAREER
                   AND B.STDNT_CAR_NBR = A.STDNT_CAR_NBR
                   AND B.EFFDT = A.EFFDT
                   AND B.EFFSEQ = A.EFFSEQ
                   AND A.EFFDT =
                       (SELECT MAX (A_ED.EFFDT)
                          FROM ps_rpt.PS_ACAD_PROG_v A_ED
                         WHERE     A.EMPLID = A_ED.EMPLID
                               AND A.ACAD_CAREER = A_ED.ACAD_CAREER
                               AND A.STDNT_CAR_NBR = A_ED.STDNT_CAR_NBR
                               AND A_ED.EFFDT <= SYSDATE)
                   AND A.EFFSEQ =
                       (SELECT MAX (A_ES.EFFSEQ)
                          FROM ps_rpt.PS_ACAD_PROG_v A_ES
                         WHERE     A.EMPLID = A_ES.EMPLID
                               AND A.ACAD_CAREER = A_ES.ACAD_CAREER
                               AND A.STDNT_CAR_NBR = A_ES.STDNT_CAR_NBR
                               AND A.EFFDT = A_ES.EFFDT)
                   AND A.PROG_STATUS = 'AC'
                   AND B.ACAD_PLAN = C.ACAD_PLAN
                   AND C.EFFDT =
                       (SELECT MAX (C_ED.EFFDT)
                          FROM ps_rpt.PS_ACAD_PLAN_TBL_v C_ED
                         WHERE     C.INSTITUTION = C_ED.INSTITUTION
                               AND C.ACAD_PLAN = C_ED.ACAD_PLAN
                               AND C_ED.EFFDT <= SYSDATE)
                   AND C.DEGREE = 'PHD'
                   AND A.INSTITUTION = t.INSTITUTION
                   AND A.ACAD_CAREER = t.ACAD_CAREER
                   AND A.ADMIT_TERM = t.STRM
                   AND SYSDATE >= t.TERM_BEGIN_DT) F
               ON population.EMPLID = F.EMPLID
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'ASO' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN (SELECT A.EMPLID,
                              A.DEGREE,
                              A.DESCR,
                              TO_CHAR (A.DEGREE_DT, 'YYYY-MM-DD')
                         FROM ps_rpt.PS_EXT_DEGREE_v A
                        WHERE     A.DEGREE_STATUS = 'C'
                              AND A.DEGREE IN ('AA',
                                               'AAS',
                                               'AOS',
                                               'AS')) d
               ON population.EMPLID = d.EMPLID
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'BHOLD' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (SELECT COMMON_ID, SEQ_3C
              FROM PS_RPT.PS_PERSON_CHECKLST_V
             WHERE     INSTITUTION = 'UBFLO'
                   AND CHECKLIST_CD = 'BHOLD'
                   AND CHECKLIST_STATUS = 'I') BH
               ON population.EMPLID = BH.COMMON_ID
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'MPHC' AS CATEGORY_ID
      FROM PS_RPT.PS_STDNT_ADVR_HIST_V  a
           JOIN PS_RPT.CMP_POPULATION_CURRENT_V population
               ON a.EMPLID = population.EMPLID
     WHERE     a.COMMITTEE_ID IN ('MPHC')
           AND a.EFFDT =
               (SELECT MAX (b.effdt)
                  FROM PS_RPT.PS_STDNT_ADVR_HIST_V b
                 WHERE a.emplid = b.emplid AND a.institution = b.institution)
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'PHHPG' AS CATEGORY_ID
      FROM PS_RPT.PS_STDNT_ADVR_HIST_V  a
           JOIN PS_RPT.CMP_POPULATION_CURRENT_V population
               ON a.EMPLID = population.EMPLID
     WHERE     a.COMMITTEE_ID IN ('PHHPG')
           AND a.EFFDT =
               (SELECT MAX (b.effdt)
                  FROM PS_RPT.PS_STDNT_ADVR_HIST_V b
                 WHERE a.emplid = b.emplid AND a.institution = b.institution)
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'NO_NUS' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (  SELECT MAX (a.AUDIT_STAMP),
                     a.AUDIT_ACTN,
                     a.INSTITUTION,
                     a.SRVC_IND_CD,
                     a.SRVC_IND_REASON,
                     a.SRVC_IND_ACT_TERM,
                     a.SCC_SI_END_TERM,
                     a.EMPLID,
                     t.TERMBEGINDATE,
                     x.SRVC_IND_CD     xnus
                FROM PS_RPT.PS_AUDIT_SRVC_IND_V a
                     INNER JOIN PS_RPT.LOK_TERM_V t
                         ON a.SRVC_IND_ACT_TERM = t.SOURCEKEY
                     LEFT JOIN PS_RPT.PS_SRVC_IND_DATA_V x
                         ON     a.EMPLID = x.EMPLID
                            AND a.SRVC_IND_CD = x.SRVC_IND_CD
               WHERE     a.INSTITUTION = 'UBFLO'
                     AND a.SRVC_IND_CD = 'NUS'
                     AND a.SRVC_IND_REASON = 'ODF'
            GROUP BY a.AUDIT_ACTN,
                     a.INSTITUTION,
                     a.SRVC_IND_CD,
                     a.SRVC_IND_REASON,
                     a.SRVC_IND_ACT_TERM,
                     a.SCC_SI_END_TERM,
                     a.EMPLID,
                     t.TERMBEGINDATE,
                     x.SRVC_IND_CD) si
               ON population.EMPLID = si.EMPLID AND si.AUDIT_ACTN = 'D'
     WHERE si.xnus IS NULL
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'DSPG' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (SELECT DISTINCT A.EMPLID
              FROM ps_rpt.PS_ACAD_PROG_V A
             WHERE     A.EFFDT =
                       (SELECT MAX (A_ED.EFFDT)
                          FROM ps_rpt.PS_ACAD_PROG_V A_ED
                         WHERE     A.EMPLID = A_ED.EMPLID
                               AND A.ACAD_CAREER = A_ED.ACAD_CAREER
                               AND A.STDNT_CAR_NBR = A_ED.STDNT_CAR_NBR
                               AND A_ED.EFFDT <= SYSDATE)
                   AND A.EFFSEQ =
                       (SELECT MAX (A_ES.EFFSEQ)
                          FROM ps_rpt.PS_ACAD_PROG_V A_ES
                         WHERE     A.EMPLID = A_ES.EMPLID
                               AND A.ACAD_CAREER = A_ES.ACAD_CAREER
                               AND A.STDNT_CAR_NBR = A_ES.STDNT_CAR_NBR
                               AND A.EFFDT = A_ES.EFFDT)
                   AND A.PROG_STATUS = 'AC'
                   AND A.ACAD_PROG LIKE '02_3'
                   AND A.ACAD_CAREER = 'UGRD'
                   AND A.PROG_REASON = 'DSPG') F
               ON population.EMPLID = F.EMPLID
    UNION ALL
    SELECT population.EMPLID AS STUDENT_ID, 'DADM' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (SELECT DISTINCT A.EMPLID
              FROM ps_rpt.PS_ACAD_PROG_V A
             WHERE     A.EFFDT =
                       (SELECT MAX (A_ED.EFFDT)
                          FROM ps_rpt.PS_ACAD_PROG_V A_ED
                         WHERE     A.EMPLID = A_ED.EMPLID
                               AND A.ACAD_CAREER = A_ED.ACAD_CAREER
                               AND A.STDNT_CAR_NBR = A_ED.STDNT_CAR_NBR
                               AND A_ED.EFFDT <= SYSDATE)
                   AND A.EFFSEQ =
                       (SELECT MAX (A_ES.EFFSEQ)
                          FROM ps_rpt.PS_ACAD_PROG_V A_ES
                         WHERE     A.EMPLID = A_ES.EMPLID
                               AND A.ACAD_CAREER = A_ES.ACAD_CAREER
                               AND A.STDNT_CAR_NBR = A_ES.STDNT_CAR_NBR
                               AND A.EFFDT = A_ES.EFFDT)
                   AND A.PROG_STATUS = 'AC'
                   AND A.ACAD_PROG LIKE '02_3'
                   AND A.ACAD_CAREER = 'UGRD'
                   AND A.PROG_REASON = 'DADM') F
               ON population.EMPLID = F.EMPLID
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'AA1' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (SELECT A.EMPLID,
                   TO_CHAR (CAST ((A.SRVC_IND_DTTM) AS TIMESTAMP),
                            'YYYY-MM-DD-HH24.MI.SS.FF'),
                   A.OPRID,
                   A.INSTITUTION,
                   A.SRVC_IND_CD
              FROM ps_rpt.PS_SRVC_IND_DATA_v A
             WHERE A.SRVC_IND_CD = 'AA1') AA
               ON population.EMPLID = AA.EMPLID
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'PATH' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (SELECT RQ_AA_WHO_DATA
              FROM PS_RPT.PS_AA_OVERRIDE_V
             WHERE     DESCR IN ('Thematic', 'Global')
                   AND INSTITUTION = 'UBFLO'
                   AND ACAD_CAREER = 'UGRD') pw
               ON     population.EMPLID = pw.RQ_AA_WHO_DATA
                  AND population.EMPLID IN
                          (SELECT A.EMPLID
                             FROM ps_rpt.PS_ACAD_PROG_v  A,
                                  ps_rpt.PS_ACAD_PLAN_v  B
                            WHERE     B.EMPLID = A.EMPLID
                                  AND B.ACAD_CAREER = A.ACAD_CAREER
                                  AND B.STDNT_CAR_NBR = A.STDNT_CAR_NBR
                                  AND B.EFFDT = A.EFFDT
                                  AND B.EFFSEQ = A.EFFSEQ
                                  AND A.EFFDT =
                                      (SELECT MAX (A_ED.EFFDT)
                                         FROM ps_rpt.PS_ACAD_PROG_v A_ED
                                        WHERE     A.EMPLID = A_ED.EMPLID
                                              AND A.ACAD_CAREER =
                                                  A_ED.ACAD_CAREER
                                              AND A.STDNT_CAR_NBR =
                                                  A_ED.STDNT_CAR_NBR
                                              AND A_ED.EFFDT <= SYSDATE)
                                  AND A.EFFSEQ =
                                      (SELECT MAX (A_ES.EFFSEQ)
                                         FROM ps_rpt.PS_ACAD_PROG_v A_ES
                                        WHERE     A.EMPLID = A_ES.EMPLID
                                              AND A.ACAD_CAREER =
                                                  A_ES.ACAD_CAREER
                                              AND A.STDNT_CAR_NBR =
                                                  A_ES.STDNT_CAR_NBR
                                              AND A.EFFDT = A_ES.EFFDT)
                                  AND A.PROG_STATUS = 'AC'
                                  AND A.ACAD_CAREER = 'UGRD'
                                  AND A.ACAD_PROG NOT LIKE '__N_'
                                  AND B.ACAD_PLAN NOT LIKE '______X%')
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'NOPATH' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN ps_rpt.PS_STDNT_CAR_TERM_v s
               ON     population.EMPLID = s.EMPLID
                  AND population.EMPLID = s.EMPLID
                  AND s.BILLING_CAREER = 'UGRD'
                  AND s.ACAD_PROG_PRIMARY NOT LIKE '__N_'
           LEFT JOIN
           (SELECT RQ_AA_WHO_DATA
              FROM PS_RPT.PS_AA_OVERRIDE_V
             WHERE     DESCR IN ('Thematic', 'Global')
                   AND INSTITUTION = 'UBFLO'
                   AND ACAD_CAREER = 'UGRD') pw
               ON population.EMPLID = pw.RQ_AA_WHO_DATA
     WHERE     pw.RQ_AA_WHO_DATA IS NULL
           AND population.EMPLID IN
                   (SELECT A.EMPLID
                      FROM ps_rpt.PS_ACAD_PROG_v A, ps_rpt.PS_ACAD_PLAN_v B
                     WHERE     B.EMPLID = A.EMPLID
                           AND B.ACAD_CAREER = A.ACAD_CAREER
                           AND B.STDNT_CAR_NBR = A.STDNT_CAR_NBR
                           AND B.EFFDT = A.EFFDT
                           AND B.EFFSEQ = A.EFFSEQ
                           AND A.EFFDT =
                               (SELECT MAX (A_ED.EFFDT)
                                  FROM ps_rpt.PS_ACAD_PROG_v A_ED
                                 WHERE     A.EMPLID = A_ED.EMPLID
                                       AND A.ACAD_CAREER = A_ED.ACAD_CAREER
                                       AND A.STDNT_CAR_NBR =
                                           A_ED.STDNT_CAR_NBR
                                       AND A_ED.EFFDT <= SYSDATE)
                           AND A.EFFSEQ =
                               (SELECT MAX (A_ES.EFFSEQ)
                                  FROM ps_rpt.PS_ACAD_PROG_v A_ES
                                 WHERE     A.EMPLID = A_ES.EMPLID
                                       AND A.ACAD_CAREER = A_ES.ACAD_CAREER
                                       AND A.STDNT_CAR_NBR =
                                           A_ES.STDNT_CAR_NBR
                                       AND A.EFFDT = A_ES.EFFDT)
                           AND A.PROG_STATUS = 'AC'
                           AND A.ACAD_CAREER = 'UGRD'
                           AND A.ACAD_PROG NOT LIKE '__N_'
                           AND B.ACAD_PLAN NOT LIKE '______X%')
    UNION ALL
    SELECT population.EMPLID AS STUDENT_ID, 'JOINT' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (SELECT A.EMPLID,
                   A.ACAD_CAREER,
                   A.STDNT_CAR_NBR,
                   TO_CHAR (A.EFFDT, 'YYYY-MM-DD'),
                   A.EFFSEQ,
                   A.INSTITUTION,
                   A.ACAD_PROG
              FROM ps_rpt.PS_ACAD_PROG_v A
             WHERE     A.EFFDT =
                       (SELECT MAX (A_ED.EFFDT)
                          FROM ps_rpt.PS_ACAD_PROG_v A_ED
                         WHERE     A.EMPLID = A_ED.EMPLID
                               AND A.ACAD_CAREER = A_ED.ACAD_CAREER
                               AND A.STDNT_CAR_NBR = A_ED.STDNT_CAR_NBR
                               AND A_ED.EFFDT <= SYSDATE)
                   AND A.EFFSEQ =
                       (SELECT MAX (A_ES.EFFSEQ)
                          FROM ps_rpt.PS_ACAD_PROG_v A_ES
                         WHERE     A.EMPLID = A_ES.EMPLID
                               AND A.ACAD_CAREER = A_ES.ACAD_CAREER
                               AND A.STDNT_CAR_NBR = A_ES.STDNT_CAR_NBR
                               AND A.EFFDT = A_ES.EFFDT)
                   AND A.JOINT_PROG_APPR = 'Y'
                   AND A.PROG_STATUS = 'AC') j
               ON population.EMPLID = j.EMPLID
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'DOUBLE_DG' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (SELECT A.EMPLID,
                   COUNT (DISTINCT C.DEGREE) OVER (PARTITION BY A.EMPLID)    DEGS
              FROM ps_rpt.PS_ACAD_PROG_v      A,
                   ps_rpt.PS_ACAD_PLAN_v      B,
                   ps_rpt.PS_ACAD_PLAN_TBL_v  C
             WHERE     B.EMPLID = A.EMPLID
                   AND B.ACAD_CAREER = A.ACAD_CAREER
                   AND B.STDNT_CAR_NBR = A.STDNT_CAR_NBR
                   AND B.EFFDT = A.EFFDT
                   AND B.EFFSEQ = A.EFFSEQ
                   AND A.EFFDT =
                       (SELECT MAX (A_ED.EFFDT)
                          FROM ps_rpt.PS_ACAD_PROG_v A_ED
                         WHERE     A.EMPLID = A_ED.EMPLID
                               AND A.ACAD_CAREER = A_ED.ACAD_CAREER
                               AND A.STDNT_CAR_NBR = A_ED.STDNT_CAR_NBR
                               AND A_ED.EFFDT <= SYSDATE)
                   AND A.EFFSEQ =
                       (SELECT MAX (A_ES.EFFSEQ)
                          FROM ps_rpt.PS_ACAD_PROG_v A_ES
                         WHERE     A.EMPLID = A_ES.EMPLID
                               AND A.ACAD_CAREER = A_ES.ACAD_CAREER
                               AND A.STDNT_CAR_NBR = A_ES.STDNT_CAR_NBR
                               AND A.EFFDT = A_ES.EFFDT)
                   AND A.PROG_STATUS = 'AC'
                   AND A.JOINT_PROG_APPR = 'N'
                   AND B.ACAD_PLAN = C.ACAD_PLAN
                   AND C.EFFDT =
                       (SELECT MAX (C_ED.EFFDT)
                          FROM ps_rpt.PS_ACAD_PLAN_TBL_v C_ED
                         WHERE     C.INSTITUTION = C_ED.INSTITUTION
                               AND C.ACAD_PLAN = C_ED.ACAD_PLAN
                               AND C_ED.EFFDT <= SYSDATE)
                   AND C.DEGREE NOT IN (' ', 'CERT')
                   AND A.ACAD_CAREER = 'UGRD') dd
               ON population.EMPLID = dd.EMPLID AND dd.DEGS > 1
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'DOUBLE_M' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (SELECT A.EMPLID,
                   COUNT (DISTINCT C.DEGREE) OVER (PARTITION BY A.EMPLID)
                       DEGS,
                   COUNT (DISTINCT B.ACAD_PLAN) OVER (PARTITION BY A.EMPLID)
                       PLNS
              FROM ps_rpt.PS_ACAD_PROG_v      A,
                   ps_rpt.PS_ACAD_PLAN_v      B,
                   ps_rpt.PS_ACAD_PLAN_TBL_v  C
             WHERE     B.EMPLID = A.EMPLID
                   AND B.ACAD_CAREER = A.ACAD_CAREER
                   AND B.STDNT_CAR_NBR = A.STDNT_CAR_NBR
                   AND B.EFFDT = A.EFFDT
                   AND B.EFFSEQ = A.EFFSEQ
                   AND A.EFFDT =
                       (SELECT MAX (A_ED.EFFDT)
                          FROM ps_rpt.PS_ACAD_PROG_v A_ED
                         WHERE     A.EMPLID = A_ED.EMPLID
                               AND A.ACAD_CAREER = A_ED.ACAD_CAREER
                               AND A.STDNT_CAR_NBR = A_ED.STDNT_CAR_NBR
                               AND A_ED.EFFDT <= SYSDATE)
                   AND A.EFFSEQ =
                       (SELECT MAX (A_ES.EFFSEQ)
                          FROM ps_rpt.PS_ACAD_PROG_v A_ES
                         WHERE     A.EMPLID = A_ES.EMPLID
                               AND A.ACAD_CAREER = A_ES.ACAD_CAREER
                               AND A.STDNT_CAR_NBR = A_ES.STDNT_CAR_NBR
                               AND A.EFFDT = A_ES.EFFDT)
                   AND A.PROG_STATUS = 'AC'
                   AND A.JOINT_PROG_APPR = 'N'
                   AND B.ACAD_PLAN = C.ACAD_PLAN
                   AND C.EFFDT =
                       (SELECT MAX (C_ED.EFFDT)
                          FROM ps_rpt.PS_ACAD_PLAN_TBL_v C_ED
                         WHERE     C.INSTITUTION = C_ED.INSTITUTION
                               AND C.ACAD_PLAN = C_ED.ACAD_PLAN
                               AND C_ED.EFFDT <= SYSDATE)
                   AND C.ACAD_PLAN_TYPE NOT IN ('MIN',
                                                'OSM',
                                                'OSN',
                                                'ND')
                   AND A.ACAD_CAREER = 'UGRD') dm
               ON     population.EMPLID = dm.EMPLID
                  AND dm.DEGS = 1
                  AND dm.PLNS > 1
    UNION ALL
    SELECT population.EMPLID AS STUDENT_ID, 'BAD_MID' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (SELECT DISTINCT b.EMPLID, b.ACAD_CAREER, b.INSTITUTION
              FROM PS_RPT.PS_GRADE_RSTR_TYPE_V  a
                   INNER JOIN PS_RPT.PS_GRADE_ROSTER_V b
                       ON     a.GRD_RSTR_TYPE_SEQ = b.GRD_RSTR_TYPE_SEQ
                          AND a.CLASS_NBR = b.CLASS_NBR
                          AND a.STRM = b.STRM
                   INNER JOIN PS_RPT.LOK_TERM_V t ON b.STRM = t.SOURCEKEY
             WHERE     a.GRADE_ROSTER_TYPE = 'MID'
                   AND b.ACAD_CAREER = 'UGRD'
                   AND b.INSTITUTION = 'UBFLO'
                   AND b.CRSE_GRADE_INPUT IN ('MU',
                                              'U',
                                              'C-',
                                              'D+',
                                              'D',
                                              'D-',
                                              'F',
                                              'F1',
                                              'F2',
                                              'F3',
                                              'FX',
                                              'IC-',
                                              'ID+',
                                              'ID',
                                              'ID-',
                                              'IF',
                                              'IF1',
                                              'IF2',
                                              'IF3',
                                              'IFX',
                                              'IW',
                                              'IU')
                   AND t.TERMENDDATE > SYSDATE) mt
               ON population.EMPLID = mt.EMPLID
    UNION ALL
    SELECT population.EMPLID AS STUDENT_ID, 'GREG' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (WITH
                prvtrm
                AS
                    (SELECT A.STRM                             "Prev Regular Term",
                            A.ACAD_CAREER                      "Career",
                            RANK ()
                                OVER (PARTITION BY A.ACAD_CAREER
                                      ORDER BY A.STRM DESC)    "Prev Regular Term Rank"
                       FROM PS_RPT.PS_TERM_TBL_V A
                      WHERE     A.TERM_CATEGORY = 'R'
                            AND (A.TERM_BEGIN_DT + 14) < SYSDATE
                            AND A.ACAD_CAREER <> 'UGRD'),
                prevenr
                AS
                    (SELECT DISTINCT
                            I.EMPLID          "Emplid",
                            I.ACAD_CAREER     "Career",
                            I.STRM            "Prev Enrolled Term"
                       FROM PS_RPT.PS_STDNT_ENRL_V           I,
                            PS_RPT.PS_TERM_TBL_V             T,
                            prvtrm,
                            ps_rpt.cmp_POPULATION_CURRENT_V  p
                      WHERE     p.EMPLID = I.EMPLID
                            AND prvtrm."Prev Regular Term Rank" = 1
                            AND prvtrm."Prev Regular Term" = I.STRM
                            AND prvtrm."Career" = I.ACAD_CAREER
                            AND I.STDNT_ENRL_STATUS = 'E'
                            AND T.TERM_CATEGORY = 'R'),
                PP
                AS
                    (SELECT A.EMPLID,
                            A.ACAD_CAREER,
                            A.STDNT_CAR_NBR,
                            TO_CHAR (A.EFFDT, 'YYYY-MM-DD'),
                            A.EFFSEQ,
                            A.INSTITUTION,
                            A.ACAD_PROG,
                            A.PROG_STATUS,
                            B.ACAD_PLAN,
                            A.DEGR_CHKOUT_STAT,
                            A.EXP_GRAD_TERM
                       FROM ps_rpt.PS_ACAD_PROG_v A, ps_rpt.PS_ACAD_PLAN_v B
                      WHERE     B.EMPLID = A.EMPLID
                            AND B.ACAD_CAREER = A.ACAD_CAREER
                            AND B.STDNT_CAR_NBR = A.STDNT_CAR_NBR
                            AND B.EFFDT = A.EFFDT
                            AND B.EFFSEQ = A.EFFSEQ
                            AND A.EFFDT =
                                (SELECT MAX (A_ED.EFFDT)
                                   FROM ps_rpt.PS_ACAD_PROG_v A_ED
                                  WHERE     A.EMPLID = A_ED.EMPLID
                                        AND A.ACAD_CAREER = A_ED.ACAD_CAREER
                                        AND A.STDNT_CAR_NBR =
                                            A_ED.STDNT_CAR_NBR
                                        AND A_ED.EFFDT <= SYSDATE)
                            AND A.EFFSEQ =
                                (SELECT MAX (A_ES.EFFSEQ)
                                   FROM ps_rpt.PS_ACAD_PROG_v A_ES
                                  WHERE     A.EMPLID = A_ES.EMPLID
                                        AND A.ACAD_CAREER = A_ES.ACAD_CAREER
                                        AND A.STDNT_CAR_NBR =
                                            A_ES.STDNT_CAR_NBR
                                        AND A.EFFDT = A_ES.EFFDT)
                            AND A.INSTITUTION = 'UBFLO'
                            AND A.ACAD_CAREER <> 'UGRD'
                            AND A.PROG_STATUS = 'AC'
                            AND B.ACAD_PLAN NOT LIKE '______X%'
                            AND B.ACAD_PLAN NOT IN ('MBC031R0',
                                                    'ICE012R0A',
                                                    'ICE012R0I',
                                                    'ICE012R5A',
                                                    'ICE012R5I',
                                                    'IEE012R5I',
                                                    'IEE012R0A',
                                                    'IEE012R0I',
                                                    'IEE012R5A'))
            SELECT C."Prev Enrolled Term",
                   A.EMPLID,
                   A.ACAD_CAREER,
                   A.INSTITUTION,
                   A.STRM,
                   A.STDNT_CAR_NBR,
                   A.ACAD_PROG_PRIMARY,
                   A.BILLING_CAREER,
                   A.UNT_TAKEN_PRGRSS,
                   A.ACADEMIC_LOAD,
                   D.DEGR_CHKOUT_STAT,
                   D.EXP_GRAD_TERM
              FROM ps_rpt.PS_STDNT_CAR_TERM_v  A,
                   ps_rpt.PS_TERM_TBL_v        B,
                   prevenr                     C,
                   pp                          D
             WHERE     C."Emplid" = A.EMPLID
                   AND C."Career" = A.ACAD_CAREER
                   AND B.STRM = A.STRM
                   AND B.ACAD_CAREER = A.ACAD_CAREER
                   AND B.INSTITUTION = A.INSTITUTION
                   AND A.ACAD_CAREER <> 'UGRD'
                   AND A.BILLING_CAREER = A.ACAD_CAREER
                   AND A.INSTITUTION = 'UBFLO'
                   AND B.TERM_CATEGORY = 'R'
                   AND B.TERM_BEGIN_DT + 14 > SYSDATE
                   AND A.ACAD_PROG_PRIMARY NOT LIKE '__N_'
                   AND A.ACADEMIC_LOAD = 'N'
                   AND A.EMPLID = D.EMPLID
                   AND A.ACAD_CAREER = D.ACAD_CAREER
                   AND A.INSTITUTION = D.INSTITUTION
                   AND A.STDNT_CAR_NBR = D.STDNT_CAR_NBR
                   AND D.EXP_GRAD_TERM <> C."Prev Enrolled Term") nr
               ON population.EMPLID = nr.EMPLID
    UNION ALL
    SELECT population.EMPLID AS STUDENT_ID, 'MJA' || Z.PRG_CD AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (SELECT EMPLID,
                   UB_SEAS_MAJOR,
                   SCHOOL,
                   DECODE (SUBSTR (UB_SEAS_MAJOR, 0, 2),
                           '02', 'EPAC',
                           '03', 'ARC',
                           '07', 'SEAS',
                           '08', 'SPHHP',
                           '10', 'LAW',
                           '11', 'MGMT',
                           '13', 'JSMBS',
                           '14', 'NUR',
                           '15', 'PHARM',
                           '27', 'CAS')    PRG_CD
              FROM ps_rpt.PS_UB_AA_SEAS_MAJR_v) Z
               ON population.EMPLID = Z.EMPLID
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'GRPR_DEGA' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN
           (SELECT A.EMPLID,
                   A.ACAD_CAREER,
                   A.STDNT_CAR_NBR,
                   TO_CHAR (A.EFFDT, 'YYYY-MM-DD'),
                   A.EFFSEQ,
                   A.INSTITUTION,
                   A.ACAD_PROG,
                   A.PROG_STATUS,
                   A.EXP_GRAD_TERM,
                   A.DEGR_CHKOUT_STAT,
                   TO_CHAR (B.TERM_BEGIN_DT, 'YYYY-MM-DD'),
                   ROUND (MONTHS_BETWEEN (B.TERM_END_DT, SYSDATE))
              FROM ps_rpt.PS_ACAD_PROG_v A, ps_rpt.PS_TERM_TBL_v B
             WHERE (    A.EFFDT =
                        (SELECT MAX (A_ED.EFFDT)
                           FROM ps_rpt.PS_ACAD_PROG_v A_ED
                          WHERE     A.EMPLID = A_ED.EMPLID
                                AND A.ACAD_CAREER = A_ED.ACAD_CAREER
                                AND A.STDNT_CAR_NBR = A_ED.STDNT_CAR_NBR
                                AND A_ED.EFFDT <= SYSDATE)
                    AND A.EFFSEQ =
                        (SELECT MAX (A_ES.EFFSEQ)
                           FROM ps_rpt.PS_ACAD_PROG_v A_ES
                          WHERE     A.EMPLID = A_ES.EMPLID
                                AND A.ACAD_CAREER = A_ES.ACAD_CAREER
                                AND A.STDNT_CAR_NBR = A_ES.STDNT_CAR_NBR
                                AND A.EFFDT = A_ES.EFFDT)
                    AND A.PROG_STATUS = 'AC'
                    AND A.ACAD_CAREER <> 'UGRD'
                    AND A.EXP_GRAD_TERM > '2119'
                    AND A.DEGR_CHKOUT_STAT NOT IN ('DN', ' ')
                    AND A.ACAD_CAREER = B.ACAD_CAREER
                    AND B.INSTITUTION = A.INSTITUTION
                    AND A.EXP_GRAD_TERM = B.STRM
                    AND ROUND (MONTHS_BETWEEN (B.TERM_END_DT, SYSDATE)) < 12))
           g
               ON population.EMPLID = g.EMPLID
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'CC1' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN ps_rpt.PS_SRVC_IND_DATA_v s
               ON population.EMPLID = s.EMPLID
     WHERE s.SRVC_IND_CD = 'CC1'
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'BFA' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN ps_rpt.PS_SRVC_IND_DATA_v s
               ON population.EMPLID = s.EMPLID
     WHERE s.SRVC_IND_CD = 'BFA'
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'RUL' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN ps_rpt.PS_SRVC_IND_DATA_v s
               ON population.EMPLID = s.EMPLID
     WHERE s.SRVC_IND_CD = 'RUL'
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'THSL' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN ps_rpt.PS_SRVC_IND_DATA_v s
               ON population.EMPLID = s.EMPLID
     WHERE s.SRVC_IND_CD = 'TSL' AND s.SRVC_IND_REASON = 'HSL'
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'TMSL' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN ps_rpt.PS_SRVC_IND_DATA_v s
               ON population.EMPLID = s.EMPLID
     WHERE s.SRVC_IND_CD = 'TSL' AND s.SRVC_IND_REASON = 'MSL'
    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'TLSL' AS CATEGORY_ID
      FROM ps_rpt.cmp_POPULATION_CURRENT_V  population
           INNER JOIN ps_rpt.PS_SRVC_IND_DATA_v s
               ON population.EMPLID = s.EMPLID
     WHERE s.SRVC_IND_CD = 'TSL' AND s.SRVC_IND_REASON = 'LSL'

    UNION
    SELECT population.EMPLID AS STUDENT_ID, 'AIX' AS CATEGORY_ID
      FROM PS_RPT.PS_STDNT_ADVR_HIST_V  a
           JOIN PS_RPT.CMP_POPULATION_CURRENT_V population
               ON a.EMPLID = population.EMPLID
     WHERE     a.COMMITTEE_ID = 'AIX'
           AND a.EFFDT =
               (SELECT MAX (b.effdt)
                  FROM PS_RPT.PS_STDNT_ADVR_HIST_V b
                 WHERE     a.emplid = b.emplid
                       AND a.institution = b.institution
                       AND a.advisor_role = b.advisor_role)