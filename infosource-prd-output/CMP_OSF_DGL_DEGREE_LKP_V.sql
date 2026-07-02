SELECT DEGREE    AS DEGREE_CD,
             DESCR     AS DEGREE_DESC,
             CASE
                 WHEN DESCR LIKE 'Associate%' THEN 'ASSOCIATES'
                 WHEN DESCR LIKE 'Bach%' THEN 'BACHELORS'
                 WHEN DESCR LIKE 'Bachelor%' THEN 'BACHELORS'
                 WHEN DESCR LIKE 'Certificate%' THEN 'CERTIFICATE'
                 WHEN DESCR LIKE '%Diploma' THEN 'DIPLOMA'
                 WHEN DESCR LIKE 'Doctor%' THEN 'DOCTORATE'
                 WHEN DESCR LIKE 'Juris%' THEN 'DOCTORATE'
                 WHEN DESCR LIKE 'Master%' THEN 'MASTERS'
                 WHEN DESCR LIKE 'MBA%' THEN 'MASTERS'
                 WHEN DEGREE = 'ARMBA' THEN 'MASTERS'
                 WHEN DEGREE = 'MBMSW' THEN 'MASTERS'
                 WHEN DEGREE = 'MC' THEN 'CERTIFICATE'
                 WHEN DEGREE = 'MPHMSW' THEN 'MASTERS'
                 WHEN DEGREE = 'OTHER' THEN 'DIPLOMA'
                 WHEN DESCR = 'Advanced Certificate' THEN 'CERTIFICATE'
             END       AS Degree_Type
        FROM ps_rpt.PS_DEGREE_TBL a
       WHERE     EFF_STATUS = 'A'
             AND a.EFFDT = (SELECT MAX (EFFDT)
                              FROM ps_rpt.PS_DEGREE_TBL
                             WHERE DEGREE = a.DEGREE AND DESCR = a.DESCR)
    ORDER BY 1