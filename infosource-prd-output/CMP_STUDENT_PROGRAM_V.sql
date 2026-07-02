SELECT DISTINCT POPSELECT.STUDENT_ID            AS student_id,
                A.ACAD_PLAN                     AS PROGRAM,
                LOWTRM.REQ_TERM                 AS TERM_ID,
                'Y'                             AS Is_active,
                EXTRACT (YEAR FROM B.EFFDT)     AS Cat_yr
  FROM PS_RPT.PS_SAA_ADB_RESULTS  A
       JOIN PS_RPT.PS_RQ_GRP_TBL B
           ON     SUBSTR (A.ACAD_PLAN, 1, 7) = SUBSTR (B.ACAD_PLAN, 1, 7)
              AND A.RQRMNT_GROUP = B.RQRMNT_GROUP
              AND A.ACAD_CAREER = B.ACAD_CAREER
              AND A.TSCRPT_TYPE = 'ADV'
              AND A.ENTRY_R_TYPE = 'KEYREQ'
       JOIN PS_RPT.CMP_STUDENT_TERM_MAJOR_CURR_MV C
           ON     A.EMPLID = C.STUDENT_ID
              AND A.ACAD_PLAN IN (C.MAJOR_1, C.MAJOR_2)
       JOIN PS_RPT.CMP_STUDENT_GENERAL_CURRENT_V POPSELECT
           ON A.EMPLID = POPSELECT.STUDENT_ID
       JOIN PS_RPT.PS_ACAD_PLAN_V LOWTRM
           ON     A.ACAD_CAREER = LOWTRM.ACAD_CAREER
              AND A.EMPLID = LOWTRM.EMPLID
              AND A.ACAD_PLAN = LOWTRM.ACAD_PLAN
 WHERE     B.EFFDT =
           (SELECT MAX (B_ED.EFFDT)
              FROM PS_RPT.PS_RQ_GRP_TBL B_ED
             WHERE     B.RQRMNT_GROUP = B_ED.RQRMNT_GROUP
                   AND B_ED.EFFDT <= SYSDATE)
       AND A.SAA_ENTRY_SEQ =
           (SELECT MAX (SAA_ENTRY_SEQ)
              FROM PS_RPT.PS_SAA_ADB_RESULTS C
             WHERE     A.EMPLID = C.EMPLID
                   AND A.ACAD_PLAN = C.ACAD_PLAN
                   AND A.ENTRY_R_TYPE = C.ENTRY_R_TYPE
                   AND A.TSCRPT_TYPE = C.TSCRPT_TYPE)
       AND LOWTRM.REQ_TERM =
           (SELECT MIN (PV.REQ_TERM)
              FROM PS_RPT.PS_ACAD_PLAN_V PV
             WHERE     LOWTRM.EMPLID = PV.EMPLID
                   AND LOWTRM.ACAD_PLAN = PV.ACAD_PLAN
                   AND PV.ACAD_CAREER = 'UGRD')
       AND C.EFFECTIVE_DATE =
           (SELECT MAX (EFFECTIVE_DATE)
              FROM PS_RPT.CMP_STUDENT_TERM_MAJOR_CURR_MV PV
             WHERE     C.STUDENT_ID = PV.STUDENT_ID
                   AND PV.MAXRNO <> '00000000000')
       AND B.DESCR NOT LIKE '%ACC%'
       AND B.DESCR NOT LIKE '%MNR%'
       AND B.EFF_STATUS = 'A'