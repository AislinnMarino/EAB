SELECT sg."STUDENT_ID",
          sg."EXAM_CD",
          sg."EXAM_DESC",
          sg."EXAM_SUBJECT_CD",
          sg."EXAM_SCORE",
          sg."EXAM_DT",
          sg."EXAM_MIN_SCORE",
          sg."EXAM_MAX_SCORE",
          sg."ADMISSION_REQUEST_IND",
          sg."LOAD_DT"
     FROM ps_rpt.cmp_population_current_v cp
          INNER JOIN ps_rpt.cmp_student_exam_v sg
             ON cp.emplid = sg.student_id