WITH
        emp_perm_phone
        AS
            (SELECT cell.emplid, cell.phone
               FROM ps_rpt.ps_personal_phone  cell
                    INNER JOIN ps_rpt.cmp_population_current_v pop
                       ON cell.emplid = pop.emplid
              WHERE cell.phone_type = 'PERM'),
        emp_cell_phone
        AS
            (SELECT cell.emplid, cell.phone
               FROM ps_rpt.ps_personal_phone  cell
                    INNER JOIN ps_rpt.cmp_population_current_v pop
                        ON cell.emplid = pop.emplid
              WHERE cell.phone_type = 'CELL'),
        camp_email
        AS
            (SELECT camp.emplid, camp.email_addr
               FROM PS_RPT.ps_email_addresses  camp
                    --INNER JOIN ps_rpt.cmp_population_current_v pop
                        --ON camp.emplid = pop.emplid
              WHERE camp.e_addr_type = 'CAMP'),
        pers_email
        AS
            (SELECT pers.emplid, pers.email_addr
               FROM PS_RPT.ps_email_addresses  pers
                    --INNER JOIN ps_rpt.cmp_population_current_v pop
                        --ON pers.emplid = pop.emplid
              WHERE pers.e_addr_type = 'PERS'
              AND pers.pref_email_flag = 'Y')
              
        SELECT EMP.PERSON_NUMBER          user_id,
               INITCAP (
                   CASE
                       WHEN NAMES.FIRST_NAME IS NULL
                       THEN
                           CASE
                               WHEN NOT REGEXP_LIKE (EMP.FIRST_NAME,
                                                     '^[A-Za-z]')
                               THEN
                                   'X'
                               ELSE
                                   COALESCE (EMP.FIRST_NAME, 'X')
                           END
                       ELSE
                           CASE
                               WHEN NOT REGEXP_LIKE (NAMES.FIRST_NAME,
                                                     '^[A-Za-z]')
                               THEN
                                   'X'
                               ELSE
                                   COALESCE (NAMES.FIRST_NAME, 'X')
                           END
                   END)                   AS FIRST_NAME,
               INITCAP (EMP.LAST_NAME)    AS LAST_NAME,
               CASE
                   WHEN camp.email_addr IS NOT NULL THEN(camp.email_addr)
                   WHEN pers.email_addr IS NOT NULL THEN(pers.email_addr)
                   WHEN PNT.PRINCIPAL IS NULL THEN EMP.PERSON_NUMBER || '@buffalo.edu'
                   ELSE
                       PNT.PRINCIPAL || '@buffalo.edu'
               END                        AS EMAIL_ADDR,
               ' '                        alternate_email,
               CASE
                   WHEN perm.phone IS NOT NULL THEN (perm.phone)
                   ELSE ' '
               END                        AS home_phone,
               CASE
                   WHEN cell.phone IS NOT NULL THEN (cell.phone)
                   ELSE ' '
               END                        AS cell_phone,
               ' '                        work_phone
          FROM UBS_EMP.EMPLOYEE_BASICS_V  emp
               LEFT JOIN DCE.PERSON_NUMBER_T PNT
                   ON     PNT.PERSON_NUMBER = EMP.PERSON_NUMBER
                      AND PNT.STATUS = 'A'
               LEFT JOIN
               (SELECT NM.EMPLID, NM.FIRST_NAME
                  FROM PS_RPT.PS_NAMES NM
                 WHERE     NM.NAME_TYPE = 'PRF'
                       AND NM.EFF_STATUS = 'A'
                       AND NM.EFFDT =
                           (SELECT MAX (NMDT.EFFDT)
                              FROM PS_RPT.PS_NAMES NMDT
                             WHERE     NMDT.EMPLID = NM.EMPLID
                                   AND NMDT.NAME_TYPE = NM.NAME_TYPE
                                   AND NMDT.EFFDT <= SYSDATE)) NAMES
                   ON NAMES.EMPLID = EMP.PERSON_NUMBER
               LEFT OUTER JOIN emp_perm_phone perm
                   ON emp.person_number = perm.emplid
               LEFT OUTER JOIN emp_cell_phone cell
                   ON emp.person_number = cell.emplid
               LEFT OUTER JOIN camp_email camp 
                   ON emp.person_number = camp.emplid
               LEFT OUTER JOIN pers_email pers
                   ON emp.person_number = pers.emplid
        UNION
        SELECT 'XXXXXXX1'                       user_id,
               'UB'                             first_name,
               'Advisor'                        last_name,
               'unknownadvisor@buffalo.edu'     email_addr,
               ' '                              alternate_email,
               ' '                              home_phone,
               ' '                              cell_phone,
               ' '                              work_phone
          FROM DUAL
        UNION
        SELECT 'XXXXXXX2'                     user_id,
               'CPMC'                         first_name,
               'Tutor'                        last_name,
               'unknowntutor@buffalo.edu'     email_addr,
               ' '                            alternate_email,
               ' '                            home_phone,
               ' '                            cell_phone,
               ' '                            work_phone
          FROM DUAL