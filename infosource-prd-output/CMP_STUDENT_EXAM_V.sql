SELECT a.EMPLID AS STUDENT_ID,
          a.TEST_ID AS EXAM_CD,
          '' AS EXAM_DESC,
          a.TEST_COMPONENT AS EXAM_SUBJECT_CD,
          a.SCORE AS EXAM_SCORE,
          a.TEST_DT AS EXAM_DT,
          maxMin.MIN_SCORE AS EXAM_MIN_SCORE,
          maxMin.MAX_SCORE AS EXAM_MAX_SCORE,
          '' AS ADMISSION_REQUEST_IND,
          a.DATE_LOADED AS LOAD_DT
     FROM ps_rpt.PS_STDNT_TEST_COMP a
          LEFT JOIN
          (SELECT *
             FROM ps_rpt.PS_SA_TCMP_REL_TBL a
            WHERE EFFDT =
                     (SELECT MAX (EFFDT)
                        FROM ps_rpt.PS_SA_TCMP_REL_TBL
                       WHERE     a.TEST_ID = TEST_ID
                             AND TEST_COMPONENT = a.TEST_COMPONENT)) maxMin
             ON     maxMin.TEST_ID = a.TEST_ID
                AND maxmin.TEST_COMPONENT = a.TEST_COMPONENT
    WHERE     a.TEST_ID <> '!BEST'
          AND a.DATE_LOADED =
                 (SELECT MAX (TDT.DATE_LOADED)
                    FROM PS_RPT.PS_STDNT_TEST_COMP TDT
                   WHERE     TDT.EMPLID = a.EMPLID
                         AND TDT.TEST_ID = a.TEST_ID
                         AND TDT.TEST_COMPONENT = a.TEST_COMPONENT
                         AND TDT.TEST_DT = a.TEST_DT)