SELECT sts."STUDENT_ID",
          sts."TERM_ID",
          sts."KEY",
          sts."VALUE"
     FROM cmp_population_current_v cp
          INNER JOIN cmp_student_term_data_v sts
             ON cp.emplid = sts.student_id