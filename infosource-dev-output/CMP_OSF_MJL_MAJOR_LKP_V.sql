SELECT ACAD_PLAN                                           AS MAJOR_CD,
     DESCR                                               AS MAJOR_DESC,
     CIP_CODE                                            AS CIP_CODE,
     CASE --If the acad plan is intended and there is no degree code, then get the degree code from the corresponding approved plan
         WHEN (SUBSTR (ACAD_PLAN, -1, 1) = 'I' AND DEGREE = ' ')
         THEN
             CASE
                 WHEN (SELECT ACAD_P.DEGREE -- If the degree on the approved plan is blank, then pull the degree from the non-approved plan. Otherwise, prioritize the degree that is on the approved plan.
                         FROM PS_ACAD_PLAN_TBL ACAD_P
                        WHERE     ACAD_P.ACAD_PLAN =
                                  (   SUBSTR (A.ACAD_PLAN,
                                              1,
                                              LENGTH (A.ACAD_PLAN) - 1)
                                   || 'A')
                              AND EFFDT =
                                  (SELECT MAX (EFFDT)
                                     FROM PS_ACAD_PLAN_TBL
                                    WHERE ACAD_PLAN = ACAD_P.ACAD_PLAN)) =
                      ' '
                 THEN
                     (SELECT NON_APPROVED.DEGREE
                        FROM PS_ACAD_PLAN_TBL NON_APPROVED
                       WHERE     NON_APPROVED.ACAD_PLAN =
                                 SUBSTR (A.ACAD_PLAN,
                                         1,
                                         LENGTH (A.ACAD_PLAN) - 1)
                             AND EFFDT =
                                 (SELECT MAX (EFFDT)
                                    FROM PS_ACAD_PLAN_TBL
                                   WHERE ACAD_PLAN = NON_APPROVED.ACAD_PLAN))
                 ELSE
                     (SELECT APPROVED.DEGREE
                        FROM PS_ACAD_PLAN_TBL APPROVED
                       WHERE     APPROVED.ACAD_PLAN =
                                 (   SUBSTR (A.ACAD_PLAN,
                                             1,
                                             LENGTH (A.ACAD_PLAN) - 1)
                                  || 'A')
                             AND EFFDT =
                                 (SELECT MAX (EFFDT)
                                    FROM PS_ACAD_PLAN_TBL
                                   WHERE ACAD_PLAN = APPROVED.ACAD_PLAN))
             END
         ELSE
             CASE
                 WHEN (SUBSTR (ACAD_PLAN, -1, 1) = 'A' AND DEGREE = ' ') --If an approved plan does not have a degree, then pull the degree from the non-approved. Otherwise, just return the degree field of the acad_plan.
                 THEN
                     (SELECT NON_APPROVED_2.DEGREE
                        FROM PS_ACAD_PLAN_TBL NON_APPROVED_2
                       WHERE     NON_APPROVED_2.ACAD_PLAN =
                                 SUBSTR (A.ACAD_PLAN,
                                         1,
                                         LENGTH (A.ACAD_PLAN) - 1)
                             AND EFFDT =
                                 (SELECT MAX (EFFDT)
                                    FROM PS_ACAD_PLAN_TBL
                                   WHERE ACAD_PLAN =
                                         NON_APPROVED_2.ACAD_PLAN))
                 ELSE
                     DEGREE
             END
     END                                                 AS DEGREE_CD,
     CASE WHEN EFF_STATUS = 'A' THEN 'Y' ELSE 'N' END    AS IS_ACTIVE
FROM ps_rpt.PS_ACAD_PLAN_TBL a
WHERE     1 = 1
     --  AND a.EFF_STATUS = 'A'                  -- Might not want to include eff_status = 'A' if majors are no longer active but will still show for historical students that we are grabbing
     AND a.EFFDT = (SELECT MAX (EFFDT) -- Only use if effdt is relevant in ps_acad_plan_tbl
                      FROM ps_rpt.PS_ACAD_PLAN_TBL
                     WHERE ACAD_PLAN = a.ACAD_PLAN --                   AND EFF_STATUS = 'A'   -- See above
                                                  )