SELECT CASE
               WHEN REGEXP_LIKE (SUBSTR (RQ.DESCR, -1), '^[a-zA-Z]*$')
               THEN
                      REPLACE (RQ.DESCR, ' ', '')
                   || EXTRACT (YEAR FROM RQ.EFFDT)
               ELSE
                   REPLACE (RQ.DESCR, ' ', '')
           END
               AS nk,
           RQ.ACAD_PLAN
               AS cd,
           RQ.SAA_DESCR80
               AS name,
           RQ.DESCRLONG
               AS descr,
           DG.DEGREE
               AS degree_cd,
           PLAN.CIP_CODE
               AS cip,
           RQ.ACAD_PLAN
               AS area_of_study,
           RQ.ACAD_SUB_PLAN
               AS concentration,
           PROG.ACAD_GROUP
               AS college_cd,
           CASE WHEN PLAN.EFF_STATUS = 'A' THEN 'Y' ELSE 'N' END
               AS is_offered,
           ' '
               AS is_transfer,
           EXTRACT (YEAR FROM RQ.EFFDT)
               AS cat_yr,
           CASE WHEN PLAN.EFF_STATUS = 'A' THEN 'Y' ELSE 'N' END
               AS IS_ACTIVE
      FROM PS_RPT.PS_RQ_GRP_TBL  RQ
           JOIN PS_RPT.PS_ACAD_PLAN_TBL PLAN ON RQ.ACAD_PLAN = PLAN.ACAD_PLAN
           JOIN PS_RPT.PS_DEGREE_TBL DG ON DG.DEGREE = PLAN.DEGREE
           LEFT JOIN PS_RPT.PS_ACAD_PROG_TBL PROG
               ON     RQ.ACAD_PROG = PROG.ACAD_PROG
                  AND RQ.ACAD_PLAN = PROG.ACAD_PLAN
     WHERE RQ.RQRMNT_USEAGE = 'ADV' AND RQ.DESCR NOT LIKE '%ACC%'