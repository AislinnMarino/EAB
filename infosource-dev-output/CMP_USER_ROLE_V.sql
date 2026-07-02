WITH UserRoles                                     
        AS (SELECT DISTINCT STUPOP.EMPLID AS USER_ID, 'UB_Student' AS ROLE_ID
              FROM (SELECT emplid FROM PS_RPT.CMP_POPULATION_HISTORIC_V 
                    UNION ALL
                    SELECT emplid FROM PS_RPT.CMP_POPULATION_CURRENT_V)
                   STUPOP
            UNION ALL
            SELECT DISTINCT
                   INSPOP.INSTRUCTOR_ID AS USER_ID, 'UB_Faculty' AS ROLE_ID
              FROM PS_RPT.CMP_INSTRUCTION_V INSPOP)
     SELECT USER_ID,
            ROLE_ID,
            DENSE_RANK () OVER (PARTITION BY USER_ID ORDER BY ROLE_ID)
               PRIMARY_IND
       FROM UserRoles
   ORDER BY USER_ID, ROLE_ID