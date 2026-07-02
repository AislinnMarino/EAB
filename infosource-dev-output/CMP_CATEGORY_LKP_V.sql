SELECT 'ATHL'                           AS Category_ID,
           'Athlete - Active on Roster'     AS Category_Desc,
           'UB'                             AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'ATNO'                                         AS Category_ID,
           'Athlete - Cheerleaders, Managers, Others'     AS Category_Desc,
           'UB'                                           AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT a.STDNT_GROUP     AS Category_ID,
           a.DESCR           AS Category_Desc,
           'UB'              AS GROUP_ID
      FROM ps_rpt.PS_STDNT_GROUP_TBL a
     WHERE a.STDNT_GROUP IN ('AAS',
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
    UNION ALL
    SELECT a.STDNT_GROUP     AS Category_ID,
           a.DESCR           AS Category_Desc,
           'UB'              AS GROUP_ID
      FROM ps_rpt.PS_STDNT_GROUP_TBL a
     WHERE a.STDNT_GROUP LIKE 'Z%'
    UNION ALL
    SELECT 'INTL'                      AS Category_ID,
           'International Student'     AS Category_Desc,
           'UB'                        AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'TRNS'                 AS Category_ID,
           'Transfer Student'     AS Category_Desc,
           'UB'                   AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'DORM'                   AS Category_ID,
           'On Campus Resident'     AS Category_Desc,
           'UB'                     AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'COMM'                    AS Category_ID,
           'Off Campus Resident'     AS Category_Desc,
           'UB'                      AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'SPNO'                             AS Category_ID,
           'SAP - Does Not Meet Criteria'     AS Category_Desc,
           'UB'                               AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'SPOK'                     AS Category_ID,
           'SAP - Meets Criteria'     AS Category_Desc,
           'UB'                       AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'SPPB'                AS Category_ID,
           'SAP - Probation'     AS Category_Desc,
           'UB'                  AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'SPWN'              AS Category_ID,
           'SAP - Warning'     AS Category_Desc,
           'UB'                AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'TAP'               AS Category_ID,
           'Tap Certified'     AS Category_Desc,
           'UB'                AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'URM'                          AS Category_ID,
           'Underrepresented Student'     AS Category_Desc,
           'UB'                           AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'VET'                           AS Category_ID,
           'Veteran or Active Service'     AS Category_Desc,
           'UB'                            AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'EPAC'                AS Category_ID,
           'Major Explorers'     AS Category_Desc,
           'UB'                  AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'CAS'                                     AS Category_ID,
           'CAS Students- No Special Population'     AS Category_Desc,
           'UB'                                      AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'CASC'                        AS Category_ID,
           'CAS Continuing Students'     AS Category_Desc,
           'UB'                          AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'BUE'                                        AS Category_ID,
           'Jacobs School Undergrad Students - INT'     AS Category_Desc,
           'UB'                                         AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'OEPG'                                  AS Category_ID,
           'Educator Prep Programs - Graduate'     AS Category_Desc,
           'UB'                                    AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'MGPO'                             AS Category_ID,
           'Management Graduate Programs'     AS Category_Desc,
           'UB'                               AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'EOP'             AS Category_ID,
           'EOP Student'     AS Category_Desc,
           'UB'              AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'CONT'                         AS Category_ID,
           'Continuing Undergraduate'     AS Category_Desc,
           'UB'                           AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'GCOT'                                 AS Category_ID,
           'Continuing Graduate/Professional'     AS Category_Desc,
           'UB'                                   AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'EPACTR'                                  AS Category_ID,
           'Student in Transition - Exploratory'     AS Category_Desc,
           'UB'                                      AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'FR' || B.SOURCEKEY                                 AS Category_ID,
           'New First-Year' || ' (' || B.DESCRIPTION || ')'    Category_Desc,
           'UB'                                                AS GROUP_ID
      FROM PS_RPT.LOK_TERM_V B
     WHERE B.SOURCEKEY >= '2116'
    UNION
    SELECT 'RE' || B.SOURCEKEY                                AS Category_ID,
           'New Re-Entry' || ' (' || B.DESCRIPTION || ')'     Category_Desc,
           'UB'                                               AS GROUP_ID
      FROM PS_RPT.LOK_TERM_V B
     WHERE B.SOURCEKEY >= '2116'
    UNION
    SELECT 'TF' || B.SOURCEKEY                                AS Category_ID,
           'New Transfer' || ' (' || B.DESCRIPTION || ')'     Category_Desc,
           'UB'                                               AS GROUP_ID
      FROM PS_RPT.LOK_TERM_V B
     WHERE B.SOURCEKEY >= '2116'
    UNION
    SELECT 'GR' || B.SOURCEKEY
               AS Category_ID,
           'New Grad/Professional' || ' (' || B.DESCRIPTION || ')'
               Category_Desc,
           'UB'
               AS GROUP_ID
      FROM PS_RPT.LOK_TERM_V B
     WHERE B.SOURCEKEY >= '2116'
    UNION
    SELECT 'ND' || B.SOURCEKEY                                 AS Category_ID,
           'New Non-degree' || ' (' || B.DESCRIPTION || ')'    Category_Desc,
           'UB'                                                AS GROUP_ID
      FROM PS_RPT.LOK_TERM_V B
     WHERE B.SOURCEKEY >= '2116'
    UNION
    SELECT 'SB' || B.SOURCEKEY                                 AS Category_ID,
           'New Subsequent' || ' (' || B.DESCRIPTION || ')'    Category_Desc,
           'UB'                                                AS GROUP_ID
      FROM PS_RPT.LOK_TERM_V B
     WHERE B.SOURCEKEY >= '2116'
    UNION ALL
    SELECT DISTINCT
           A.ACAD_STNDNG_STAT || A.STRM
               CATEGORY_ID,
           L1.XLATLONGNAME || ' (' || T.DESCRIPTION || ')'
               AS Category_Desc,
           'UB'
               AS GROUP_ID
      FROM ps_rpt.PS_ACAD_STDNG_ACTN_v  A
           INNER JOIN PS_RPT.LOK_TERM_V T ON A.STRM = T.SOURCEKEY
           LEFT JOIN PS_RPT.PSXLATITEM_V L1
               ON     A.ACAD_STNDNG_STAT = L1.FIELDVALUE
                  AND L1.FIELDNAME = 'ACAD_STNDNG_STAT'
     WHERE     A.ACAD_STNDNG_ACTN <> ' '
           AND A.STRM >= '2119'
           AND A.ACAD_CAREER = 'UGRD'
    UNION ALL
    SELECT 'COMP'                             AS Category_ID,
           'Undergrad Degree - Completed'     AS Category_Desc,
           'UB'                               AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'DEGA' || t.SOURCEKEY
               AS Category_ID,
           'Undergrad Degree - Applied (' || t.DESCRIPTION || ')'
               AS Category_Desc,
           'UB'
               AS GROUP_ID
      FROM ps_rpt.LOK_TERM_V t
     WHERE     1 = 1
           AND MONTHS_BETWEEN ((t.TERMENDDATE + 60), SYSDATE) BETWEEN 0 AND 9
    UNION ALL
    SELECT 'LOA_U'                                         AS Category_ID,
           'Leave of Absence (Current) in UGRD Career'     AS Category_Desc,
           'UB'                                            AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'LOA_G'                                         AS Category_ID,
           'Leave of Absence (Current) in GRAD Career'     AS Category_Desc,
           'UB'                                            AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'LOA_L'                                        AS Category_ID,
           'Leave of Absence (Current) in LAW Career'     AS Category_Desc,
           'UB'                                           AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'LOA_P'                                         AS Category_ID,
           'Leave of Absence (Current) in PHRM Career'     AS Category_Desc,
           'UB'                                            AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'LOA_D'                                        AS Category_ID,
           'Leave of Absence (Current) in SDM Career'     AS Category_Desc,
           'UB'                                           AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'LOA_M'                                        AS Category_ID,
           'Leave of Absence (Current) in MED Career'     AS Category_Desc,
           'UB'                                           AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'FLOA_U'                                         AS Category_ID,
           'Leave of Absence (Upcoming) in UGRD Career'     AS Category_Desc,
           'UB'                                             AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'FLOA_G'                                         AS Category_ID,
           'Leave of Absence (Upcoming) in GRAD Career'     AS Category_Desc,
           'UB'                                             AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'FLOA_L'                                        AS Category_ID,
           'Leave of Absence (Upcoming) in LAW Career'     AS Category_Desc,
           'UB'                                            AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'FLOA_P'                                         AS Category_ID,
           'Leave of Absence (Upcoming) in PHRM Career'     AS Category_Desc,
           'UB'                                             AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'FLOA_D'                                        AS Category_ID,
           'Leave of Absence (Upcoming) in SDM Career'     AS Category_Desc,
           'UB'                                            AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'FLOA_M'                                        AS Category_ID,
           'Leave of Absence (Upcoming) in MED Career'     AS Category_Desc,
           'UB'                                            AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'REG'                                      AS Category_ID,
           'Eligible to Register - Undergraduate'     AS Category_Desc,
           'UB'                                       AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'SEAS'                                   AS Category_ID,
           'Engineering Undergraduate Students'     AS Category_Desc,
           'UB'                                     AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'WES'
               AS Category_ID,
           'Missing AlcoholEDU, Sexual Assault Prevention Requirements'
               AS Category_Desc,
           'UB'
               AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'PHARMD'              AS Category_ID,
           'PharmD Students'     AS Category_Desc,
           'UB'                  AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'JSMBS'                          AS Category_ID,
           'Jacobs School - No Advisor'     AS Category_Desc,
           'UB'                             AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'MLTCR'                                  AS Category_ID,
           'Student Active in Multiple Careers'     AS Category_Desc,
           'UB'                                     AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'DISC'                  AS Category_ID,
           'No Active Program'     AS Category_Desc,
           'UB'                    AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'NODEG'
               AS Category_ID,
           'Closed AAR, No Graduation App (no combined, SBSQ)'
               AS Category_Desc,
           'UB'
               AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'MGT'                                   AS Category_ID,
           'Management Undergraduate Students'     AS Category_Desc,
           'UB'                                    AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'No_CAP'                           AS Category_ID,
           'UBC - Capstone Not Satisfied'     AS Category_Desc,
           'UB'                               AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'No_CL1'                             AS Category_ID,
           'UBC - Comm Lit I Not Satisfied'     AS Category_Desc,
           'UB'                                 AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'No_CL2'                              AS Category_ID,
           'UBC - Comm Lit II Not Satisfied'     AS Category_Desc,
           'UB'                                  AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'No_DIV'                            AS Category_ID,
           'UBC - Diversity Not Satisfied'     AS Category_Desc,
           'UB'                                AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'No_MQR'                                        AS Category_ID,
           'UBC - Math and Quant Reason Not Satisfied'     AS Category_Desc,
           'UB'                                            AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'No_GLB'                                 AS Category_ID,
           'UBC - Global Pathway Not Satisfied'     AS Category_Desc,
           'UB'                                     AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'No_THM'                                   AS Category_ID,
           'UBC - Thematic Pathway Not Satisfied'     AS Category_Desc,
           'UB'                                       AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'No_SLI'
               AS Category_ID,
           'UBC - Scientific Lit and Inquiry Not Satisfied'
               AS Category_Desc,
           'UB'
               AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'No_SEM'                          AS Category_ID,
           'UBC - Seminar Not Satisfied'     AS Category_Desc,
           'UB'                              AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'CMP_UBC'                 AS Category_ID,
           'UBC - All Satisfied'     AS Category_Desc,
           'UB'                      AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'FRFAI'                           AS Category_ID,
           'FERPA Release Academic Info'     AS Category_Desc,
           'UB'                              AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'FRFFI'                            AS Category_ID,
           'FERPA Release Financial Info'     AS Category_Desc,
           'UB'                               AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'FERPA'                      AS Category_ID,
           'FERPA Hold - Check HUB'     AS Category_Desc,
           'UB'                         AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'BIL'                  AS Category_ID,
           'Unpaid Bill Hold'     AS Category_Desc,
           'UB'                   AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'MEN'                              AS Category_ID,
           'Meningitis Waiver Incomplete'     AS Category_Desc,
           'UB'                               AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'MMR'                            AS Category_ID,
           'Incomplete MMR Requirement'     AS Category_Desc,
           'UB'                             AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'NOADD'                               AS Category_ID,
           'Hold Restricting Adding a Class'     AS Category_Desc,
           'UB'                                  AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'INCL-Fall'                AS Category_ID,
           'Incomplete from Fall'     AS Category_Desc,
           'UB'                       AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'INCL-Winter'                AS Category_ID,
           'Incomplete from Winter'     AS Category_Desc,
           'UB'                         AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'INCL-Spring'                AS Category_ID,
           'Incomplete from Spring'     AS Category_Desc,
           'UB'                         AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'INCL-Summer'                AS Category_ID,
           'Incomplete from Summer'     AS Category_Desc,
           'UB'                         AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'MRA1'                                 AS Category_ID,
           'MTH Placement: MTH 121, 131, 141'     AS Category_Desc,
           'UB'                                   AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'MRA2'                                      AS Category_ID,
           'MTH Placement: MTH 114, 121, 131, 141'     AS Category_Desc,
           'UB'                                        AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'MRA3'                            AS Category_ID,
           'MTH Placement: MTH 121, 131'     AS Category_Desc,
           'UB'                              AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'MRA4'                                           AS Category_ID,
           'MTH Placement: MTH 108, 109, 114, 121, 131'     AS Category_Desc,
           'UB'                                             AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'MRA5'                                 AS Category_ID,
           'MTH Placement: MTH 108, 113, 114'     AS Category_Desc,
           'UB'                                   AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'MTH MRA6'                                      AS Category_ID,
           'MTH Placement: MTH 113, 114 or Retake MRA'     AS Category_Desc,
           'UB'                                            AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'MRA7'                        AS Category_ID,
           'MTH Placement: Take MRA'     AS Category_Desc,
           'UB'                          AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'UGRD'                              AS Category_ID,
           'Current Career: Undergraduate'     AS Category_Desc,
           'UB'                                AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'GRAD'                         AS Category_ID,
           'Current Career: Graduate'     AS Category_Desc,
           'UB'                           AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'PHRM'                         AS Category_ID,
           'Current Career: Pharmacy'     AS Category_Desc,
           'UB'                           AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'MED'                          AS Category_ID,
           'Current Career: Medicine'     AS Category_Desc,
           'UB'                           AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'LAW'                     AS Category_ID,
           'Current Career: Law'     AS Category_Desc,
           'UB'                      AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'SDM'                                 AS Category_ID,
           'Current Career: Dental Medicine'     AS Category_Desc,
           'UB'                                  AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'ARC'                             AS Category_ID,
           'Architecture Undergraduates'     AS Category_Desc,
           'UB'                              AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'MBA'              AS Category_ID,
           'MBA Students'     AS Category_Desc,
           'UB'               AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'TEACH'                AS Category_ID,
           'UBTeach Students'     AS Category_Desc,
           'UB'                   AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'SPPS1'                                 AS Category_ID,
           'School of Pharmacy Undergraduates'     AS Category_Desc,
           'UB'                                    AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'PHHP'                             AS Category_ID,
           'Public Health Undergraduates'     AS Category_Desc,
           'UB'                               AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'NUR'                        AS Category_ID,
           'Nursing Undergraduates'     AS Category_Desc,
           'UB'                         AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'LAW1'                   AS Category_ID,
           'Law Undergraduates'     AS Category_Desc,
           'UB'                     AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'MTHNO'                               AS Category_ID,
           'MRA - Online Attempts Exhausted'     AS Category_Desc,
           'UB'                                  AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'MTHOK'                             AS Category_ID,
           'MRA - Online Attempts Allowed'     AS Category_Desc,
           'UB'                                AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'LATE199'                            AS Category_ID,
           'Late UBS 199 Fall Registration'     AS Category_Desc,
           'UB'                                 AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'MJ0226'                         AS Category_ID,
           'Future Major Change to ARC'     AS Category_Desc,
           'UB'                             AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'MJ0301'                          AS Category_ID,
           'Future Major Change to SEAS'     AS Category_Desc,
           'UB'                              AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'MJ0317'                         AS Category_ID,
           'Future Major Change to LAW'     AS Category_Desc,
           'UB'                             AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'MJ0377'                         AS Category_ID,
           'Future Major Change to MGT'     AS Category_Desc,
           'UB'                             AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'MJ0456'                           AS Category_ID,
           'Future Major Change to JSMBS'     AS Category_Desc,
           'UB'                               AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'MJ0494'                         AS Category_ID,
           'Future Major Change to NUR'     AS Category_Desc,
           'UB'                             AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'MJ0508'                          AS Category_ID,
           'Future Major Change to PHRM'     AS Category_Desc,
           'UB'                              AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'MJ1084'                         AS Category_ID,
           'Future Major Change to CAS'     AS Category_Desc,
           'UB'                             AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'MJ0448'                           AS Category_ID,
           'Future Major Change to SPHHP'     AS Category_Desc,
           'UB'                               AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'MJ0716'                          AS Category_ID,
           'Future Major Change to EPAC'     AS Category_Desc,
           'UB'                              AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'REGE'                                           AS Category_ID,
           'Eligible to Register - UGRD - OpenEnrlAppt'     AS Category_Desc,
           'UB'                                             AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'REGES'
               AS Category_ID,
           'Eligible to Register - UGRD - OpenEnrlAppt + ShopCart'
               AS Category_Desc,
           'UB'
               AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'RSGNA'                                     AS Category_ID,
           'Resigned All Classes for Current Term'     AS Category_Desc,
           'UB'                                        AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'COACH'                           AS Category_ID,
           'Students with Success Coach'     AS Category_Desc,
           'UB'                              AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'MPH'              AS Category_ID,
           'MPH Programs'     AS Category_Desc,
           'UB'               AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'LAW JD P1'             AS Category_ID,
           'Law JD First Year'     AS Category_Desc,
           'UB'                    AS GROUP_ID
      FROM DUAL
    UNION
    SELECT 'LAW JD P2'              AS Category_ID,
           'Law JD Second Year'     AS Category_Desc,
           'UB'                     AS GROUP_ID
      FROM DUAL
    UNION
    SELECT 'LAW JD P3'             AS Category_ID,
           'Law JD Third Year'     AS Category_Desc,
           'UB'                    AS GROUP_ID
      FROM DUAL
    UNION ALL
    SELECT 'PHRM P1'               AS Category_ID,
           'PharmD First Year'     AS Category_Desc,
           'UB'                    AS GROUP_ID
      FROM DUAL
    UNION
    SELECT 'PHRM P2'                AS Category_ID,
           'PharmD Second Year'     AS Category_Desc,
           'UB'                     AS GROUP_ID
      FROM DUAL
    UNION
    SELECT 'PHRM P3'               AS Category_ID,
           'PharmD Third Year'     AS Category_Desc,
           'UB'                    AS GROUP_ID
      FROM DUAL
    UNION
    SELECT 'PHRM P4'                AS Category_ID,
           'PharmD Fourth Year'     AS Category_Desc,
           'UB'                     AS GROUP_ID
      FROM DUAL
    UNION
    SELECT 'BPS'                                AS Category_ID,
           'Attended Buffalo Public School'     AS Category_Desc,
           'UB'                                 AS GROUP_ID
      FROM DUAL
    UNION
    SELECT 'DOC'                  AS Category_ID,
           'Doctoral Student'     AS Category_Desc,
           'UB'                   AS GROUP_ID
      FROM DUAL
    UNION
    SELECT 'DOCN'                          AS Category_ID,
           'Doctoral Students - No MD'     AS Category_Desc,
           'UB'                            AS GROUP_ID
      FROM DUAL
    UNION
    SELECT 'ASO'                          AS Category_ID,
           'Earned Associates Degree'     AS Category_Desc,
           'UB'                           AS GROUP_ID
      FROM DUAL
    UNION
    SELECT 'BHOLD'                          AS Category_ID,
           'Potential Unpaid Bill Hold'     AS Category_Desc,
           'UB'                             AS GROUP_ID
      FROM DUAL
    UNION
    SELECT 'MPHC'                                AS Category_ID,
           'MPH - Community Health Programs'     AS Category_Desc,
           'UB'                                  AS GROUP_ID
      FROM DUAL
    UNION
    SELECT 'PHHPG'                               AS Category_ID,
           'Public Health Graduate Students'     AS Category_Desc,
           'UB'                                  AS GROUP_ID
      FROM DUAL
    UNION
    SELECT 'NO_NUS'               AS Category_ID,
           'NUS Hold Removed'     AS Category_Desc,
           'UB'                   AS GROUP_ID
      FROM DUAL
    UNION
    SELECT 'DSPG'
               AS Category_ID,
           'Exploring Alternatives - Dismissed from Program'
               AS Category_Desc,
           'UB'
               AS GROUP_ID
      FROM DUAL
    UNION
    SELECT 'DADM'
               AS Category_ID,
           'Exploring Alternatives - Denied Admission to Program'
               AS Category_Desc,
           'UB'
               AS GROUP_ID
      FROM DUAL
    UNION
    SELECT 'AA1'          AS Category_ID,
           'AA1 Hold'     AS Category_Desc,
           'UB'           AS GROUP_ID
      FROM DUAL
    UNION
    SELECT 'PATH'               AS Category_ID,
           'Pathways Saved'     AS Category_Desc,
           'UB'                 AS GROUP_ID
      FROM DUAL
    UNION
    SELECT 'NOPATH'                 AS Category_ID,
           'Pathways Not Saved'     AS Category_Desc,
           'UB'                     AS GROUP_ID
      FROM DUAL
    UNION
    SELECT 'JOINT'                    AS Category_ID,
           'Joint Major Approval'     AS Category_Desc,
           'UB'                       AS GROUP_ID
      FROM DUAL
    UNION
    SELECT 'DOUBLE_DG'                           AS Category_ID,
           'Multiple Majors, Double Degrees'     AS Category_Desc,
           'UB'                                  AS GROUP_ID
      FROM DUAL
    UNION
    SELECT 'DOUBLE_M'                         AS Category_ID,
           'Multiple Majors, Same Degree'     AS Category_Desc,
           'UB'                               AS GROUP_ID
      FROM DUAL
    UNION
    SELECT 'BAD_MID'                                    AS Category_ID,
           'Negative Mid-Term Grade - Current Term'     AS Category_Desc,
           'UB'                                         AS GROUP_ID
      FROM DUAL
    UNION
    SELECT 'GREG'                            AS Category_ID,
           'Eligible to Register - Grad'     AS Category_Desc,
           'UB'                              AS GROUP_ID
      FROM DUAL
    UNION
    SELECT 'MJAEPAC'                             AS Category_ID,
           'Applied for Major Change - EPAC'     AS Category_Desc,
           'UB'                                  AS GROUP_ID
      FROM DUAL
    UNION
    SELECT 'MJAARC'                             AS Category_ID,
           'Applied for Major Change - ARC'     AS Category_Desc,
           'UB'                                 AS GROUP_ID
      FROM DUAL
    UNION
    SELECT 'MJASEAS'                             AS Category_ID,
           'Applied for Major Change - SEAS'     AS Category_Desc,
           'UB'                                  AS GROUP_ID
      FROM DUAL
    UNION
    SELECT 'MJASPHHP'                             AS Category_ID,
           'Applied for Major Change - SPHHP'     AS Category_Desc,
           'UB'                                   AS GROUP_ID
      FROM DUAL
    UNION
    SELECT 'MJALAW'                             AS Category_ID,
           'Applied for Major Change - LAW'     AS Category_Desc,
           'UB'                                 AS GROUP_ID
      FROM DUAL
    UNION
    SELECT 'MJAMGMT'                             AS Category_ID,
           'Applied for Major Change - MGMT'     AS Category_Desc,
           'UB'                                  AS GROUP_ID
      FROM DUAL
    UNION
    SELECT 'MJAJSMBS'                             AS Category_ID,
           'Applied for Major Change - JSMBS'     AS Category_Desc,
           'UB'                                   AS GROUP_ID
      FROM DUAL
    UNION
    SELECT 'MJANUR'                             AS Category_ID,
           'Applied for Major Change - NUR'     AS Category_Desc,
           'UB'                                 AS GROUP_ID
      FROM DUAL
    UNION
    SELECT 'MJAPHARM'                             AS Category_ID,
           'Applied for Major Change - PHARM'     AS Category_Desc,
           'UB'                                   AS GROUP_ID
      FROM DUAL
    UNION
    SELECT 'MJACAS'                             AS Category_ID,
           'Applied for Major Change - CAS'     AS Category_Desc,
           'UB'                                 AS GROUP_ID
      FROM DUAL
    UNION
    SELECT 'GRPR_DEGA'                                     AS Category_ID,
           'Applied for Graduation - Graduate Program'     AS Category_Desc,
           'UB'                                            AS GROUP_ID
      FROM DUAL
    UNION
    SELECT 'CC1'                          AS Category_ID,
           'Profile Information Hold'     AS Category_Desc,
           'UB'                           AS GROUP_ID
      FROM DUAL
    UNION
    SELECT 'BFA'                          AS Category_ID,
           'Financial Agreement Hold'     AS Category_Desc,
           'UB'                           AS GROUP_ID
      FROM DUAL
    UNION
    SELECT 'RUL'                            AS Category_ID,
           'Rules and Regulations Hold'     AS Category_Desc,
           'UB'                             AS GROUP_ID
      FROM DUAL
    UNION
    SELECT 'THSL'                         AS Category_ID,
           'TrACE High Support Level'     AS Category_Desc,
           'UB'                           AS GROUP_ID
      FROM DUAL
    UNION
    SELECT 'TMSL'                           AS Category_ID,
           'TrACE Medium Support Level'     AS Category_Desc,
           'UB'                             AS GROUP_ID
      FROM DUAL
    UNION
    SELECT 'TLSL'                        AS Category_ID,
           'TrACE Low Support Level'     AS Category_Desc,
           'UB'                          AS GROUP_ID
      FROM DUAL
	UNION
 SELECT 'AIX'                        AS Category_ID,
           'AI Undergraduate Majors - Includes Spec Pop'     AS Category_Desc,
           'UB'                          AS GROUP_ID
      FROM DUAL
    ORDER BY Category_Desc