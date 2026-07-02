SELECT major1.EMPLID                  AS STUDENT_ID
       , NVL(major1.COMPLETION_TERM, '')    AS TERM_ID
       , NVL(major1.ACAD_PLAN, '')        AS GRAD_MAJOR_CD_1
       , NVL(major2.ACAD_PLAN, '')        AS GRAD_MAJOR_CD_2
       , NVL(major3.ACAD_PLAN, '')        AS GRAD_MAJOR_CD_3
      , NVL(major4.ACAD_PLAN, '')        AS GRAD_MAJOR_CD_4
from (SELECT deg_plan.EMPLID,
       deg_plan.ACAD_PLAN,
       deg_plan.STDNT_DEGR,
       completion_term,
       plan_seq.RANKNO
  FROM ps_rpt.PS_ACAD_DEGR_PLAN deg_plan
       JOIN
       (SELECT PLAN.EMPLID,
              PLAN.ACAD_CAREER,
               PLAN.ACAD_PLAN,
              
               PLAN.STDNT_DEGR,
            
               D.COMPLETION_TERM,
               ROW_NUMBER ()
               OVER (PARTITION BY PLAN.EMPLID, D.COMPLETION_TERM
                     
                     order by d.completion_term, d.stdnt_degr)
                  AS RANKNO
          FROM ps_rpt.PS_ACAD_DEGR_PLAN plan
          JOIN ps_rpt.PS_ACAD_DEGR d
                
          ON PLAN.EMPLID = D.EMPLID
          AND PLAN.STDNT_DEGR = D.STDNT_DEGR
         WHERE 1 = 1 
         ) plan_seq
          ON     deg_plan.EMPLID = plan_seq.EMPLID
             AND deg_plan.ACAD_PLAN = plan_seq.ACAD_PLAN
             AND deg_plan.STDNT_DEGR = plan_seq.STDNT_DEGR
             AND deg_plan.ACAD_CAREER = plan_seq.ACAD_CAREER
 WHERE 1 = 1  
 and plan_seq.rankno = 1
 ) major1
 LEFT JOIN
 (SELECT deg_plan.EMPLID,
       deg_plan.ACAD_PLAN,
       deg_plan.STDNT_DEGR,
       completion_term,
       plan_seq.RANKNO
  FROM ps_rpt.PS_ACAD_DEGR_PLAN deg_plan
       JOIN
       (SELECT PLAN.EMPLID,
              PLAN.ACAD_CAREER,
               PLAN.ACAD_PLAN,
              
               PLAN.STDNT_DEGR,
            
               D.COMPLETION_TERM,
               ROW_NUMBER ()
               OVER (PARTITION BY PLAN.EMPLID, D.COMPLETION_TERM
                     
                     order by d.completion_term, d.stdnt_degr)
                  AS RANKNO
          FROM ps_rpt.PS_ACAD_DEGR_PLAN plan
          JOIN ps_rpt.PS_ACAD_DEGR d
                
          ON PLAN.EMPLID = D.EMPLID
          AND PLAN.STDNT_DEGR = D.STDNT_DEGR
         WHERE 1 = 1 
         ) plan_seq
          ON     deg_plan.EMPLID = plan_seq.EMPLID
             AND deg_plan.ACAD_PLAN = plan_seq.ACAD_PLAN
             AND deg_plan.STDNT_DEGR = plan_seq.STDNT_DEGR
             AND deg_plan.ACAD_CAREER = plan_seq.ACAD_CAREER
 WHERE 1 = 1 
 and plan_seq.rankno = 2)major2
 on major1.emplid = major2.emplid
 and major1.completion_term = major2.completion_term
 LEFT JOIN
 (SELECT deg_plan.EMPLID,
       deg_plan.ACAD_PLAN,
       deg_plan.STDNT_DEGR,
       completion_term,
       plan_seq.RANKNO
  FROM ps_rpt.PS_ACAD_DEGR_PLAN deg_plan
       JOIN
       (SELECT PLAN.EMPLID,
              PLAN.ACAD_CAREER,
               PLAN.ACAD_PLAN,
              
               PLAN.STDNT_DEGR,
            
               D.COMPLETION_TERM,
               ROW_NUMBER ()
               OVER (PARTITION BY PLAN.EMPLID, D.COMPLETION_TERM
                     
                     order by d.completion_term, d.stdnt_degr)
                  AS RANKNO
          FROM ps_rpt.PS_ACAD_DEGR_PLAN plan
          JOIN ps_rpt.PS_ACAD_DEGR d
                
          ON PLAN.EMPLID = D.EMPLID
          AND PLAN.STDNT_DEGR = D.STDNT_DEGR
         WHERE 1 = 1 
         ) plan_seq
          ON     deg_plan.EMPLID = plan_seq.EMPLID
             AND deg_plan.ACAD_PLAN = plan_seq.ACAD_PLAN
             AND deg_plan.STDNT_DEGR = plan_seq.STDNT_DEGR
             AND deg_plan.ACAD_CAREER = plan_seq.ACAD_CAREER
 WHERE 1 = 1 
 and plan_seq.rankno = 3)major3
 on major2.emplid = major3.emplid
 and major2.completion_term = major3.completion_term
 LEFT JOIN
 (SELECT deg_plan.EMPLID,
       deg_plan.ACAD_PLAN,
       deg_plan.STDNT_DEGR,
       completion_term,
       plan_seq.RANKNO
  FROM ps_rpt.PS_ACAD_DEGR_PLAN deg_plan
       JOIN
       (SELECT PLAN.EMPLID,
              PLAN.ACAD_CAREER,
               PLAN.ACAD_PLAN,
              
               PLAN.STDNT_DEGR,
            
               D.COMPLETION_TERM,
               ROW_NUMBER ()
               OVER (PARTITION BY PLAN.EMPLID, D.COMPLETION_TERM
                     
                     order by d.completion_term, d.stdnt_degr)
                  AS RANKNO
          FROM ps_rpt.PS_ACAD_DEGR_PLAN plan
          JOIN ps_rpt.PS_ACAD_DEGR d                
          ON PLAN.EMPLID = D.EMPLID
          AND PLAN.STDNT_DEGR = D.STDNT_DEGR
         WHERE 1 = 1 
         ) plan_seq
          ON     deg_plan.EMPLID = plan_seq.EMPLID
             AND deg_plan.ACAD_PLAN = plan_seq.ACAD_PLAN
             AND deg_plan.STDNT_DEGR = plan_seq.STDNT_DEGR
             AND deg_plan.ACAD_CAREER = plan_seq.ACAD_CAREER
 WHERE 1 = 1 
 and plan_seq.rankno = 4)major4
 on major3.emplid = major4.emplid
 and major3.completion_term = major4.completion_term
 order by student_id