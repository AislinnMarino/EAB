SELECT md."STUDENT_ID",
          md."MINOR_DESCRIPTION",
          md."RANK_NO"
     FROM cmp_population_current_v cp
          INNER JOIN cmp_minor_declar_v md
             ON cp.emplid = md.student_id