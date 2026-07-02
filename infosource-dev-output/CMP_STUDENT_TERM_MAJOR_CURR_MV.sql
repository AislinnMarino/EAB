SELECT stm."STUDENT_ID",
           stm."EFFECTIVE_DATE",
           stm."COLLEGE_1",
           stm."MAJOR_1",
           stm."DEGREE_1",
           stm."CONCENTRATION_1",
           stm."COLLEGE_2",
           stm."MAJOR_2",
           stm."DEGREE_2",
           stm."CONCENTRATION_2",
           stm."COLLEGE_3",
           stm."MAJOR_3",
           stm."DEGREE_3",
           stm."CONCENTRATION_3",
           stm."COLLEGE_4",
           stm."MAJOR_4",
           stm."DEGREE_4",
           stm."CONCENTRATION_4",
           stm."MAXRNO"
      FROM ps_rpt.cmp_population_current_v  cp
           INNER JOIN ps_rpt.CMP_STUDENT_TERM_MAJOR_V stm
               ON cp.emplid = stm.student_id