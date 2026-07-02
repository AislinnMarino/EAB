WITH
        ActiveStu
        AS
            (SELECT DISTINCT STUDENT_ID
               FROM PS_RPT.CMP_STUDENT_GENERAL_CURRENT_V),
        ActiveStaff
        AS
            (SELECT EMPB.PERSON_NUMBER
                        AS STAFF_ID,
                    NVL (CASE WHEN PNT.STATUS = 'A' THEN 'A' ELSE 'N' END,
                         'N')
                        AS ACTIVE_FLAG,
                    'N'
                        AS CAN_LOGIN,
                    'N'
                        AS SEND_ACTIVATION_EMAIL,
                    ' '
                        AS PIN,
                    PNT.PRINCIPAL
                        AS SSO_ID,
                    ' '
                        AS ALTERNATE_USER_ID
               FROM UBS_EMP.EMPLOYEE_BASICS_V  EMPB
                    JOIN UBS_EMP.ACTIVE_APPOINTMENTS ACT
                        ON EMPB.PERSON_NUMBER = ACT.PERSON_NUMBER
                    JOIN APP_CFG.APPT_TYPES ATYP
                        ON ACT.APPOINTMENT_TYPE = ATYP.appt_type
                    JOIN UBS_ENT.ENTITIES ENT
                        ON ACT.UB_ENT_NUMBER = ENT.UB_ENT_NUMBER
                    LEFT JOIN DCE.PERSON_NUMBER_T PNT
                        ON     PNT.PERSON_NUMBER = EMPB.PERSON_NUMBER
                           AND PNT.STATUS = 'A'
              WHERE     ACT.PRIMARY_APPOINTMENT_INDICATOR = 'Y'
                    AND ACT.TERMINATION_REASON_CD = '00'),
        ExtendedStaff
        AS
            (SELECT DISTINCT EMPB.PERSON_NUMBER AS STAFF_ID
               FROM UBS_EMP.EMPLOYEE_BASICS_V  EMPB
                    LEFT JOIN DCE.PERSON_NUMBER_T PNT
                        ON     PNT.PERSON_NUMBER = EMPB.PERSON_NUMBER
                           AND PNT.STATUS = 'A'),
        EntirePop
        AS
            (SELECT ActiveStu.STUDENT_ID
                        AS STAFF_ID,
                    CASE
                        WHEN ActiveStu.STUDENT_ID IS NULL THEN 'N'
                        ELSE 'A'
                    END
                        AS ACTIVE_FLAG,
                    'N'
                        AS CAN_LOGIN,
                    'N'
                        AS SEND_ACTIVATION_EMAIL,
                    ' '
                        AS PIN,
                    CASE
                        WHEN ActiveStu.STUDENT_ID IS NULL THEN ' '
                        ELSE PNT.PRINCIPAL
                    END
                        AS SSO_ID,
                    ' '
                        AS ALTERNATE_USER_ID
               FROM DCE.PERSON_NUMBER_T  PNT
                    --                      ON     PNT.PERSON_NUMBER = ExtendedStu.STUDENT_ID
                    --                         AND PNT.STATUS = 'A'
                    LEFT JOIN ActiveStu
                        ON ActiveStu.STUDENT_ID = PNT.PERSON_NUMBER
             UNION
             SELECT ExtendedStaff.STAFF_ID,
                    CASE
                        WHEN ActiveStaff.STAFF_ID IS NULL THEN 'N'
                        ELSE 'A'
                    END
                        AS ACTIVE_FLAG,
                    'N'
                        AS CAN_LOGIN,
                    'N'
                        AS SEND_ACTIVATION_EMAIL,
                    ' '
                        AS PIN,
                    CASE
                        WHEN ActiveStaff.SSO_ID IS NULL THEN ' '
                        ELSE ActiveStaff.SSO_ID
                    END
                        AS SSO_ID,
                    ' '
                        AS ALTERNATE_USER_ID
               FROM ExtendedStaff
                    LEFT JOIN ActiveStaff
                        ON ActiveStaff.STAFF_ID = ExtendedStaff.STAFF_ID)
    SELECT STAFF_ID,
           ACTIVE_FLAG,
           CAN_LOGIN,
           SEND_ACTIVATION_EMAIL,
           PIN,
           SSO_ID,
           ALTERNATE_USER_ID
      FROM (SELECT STAFF_ID,
                   ACTIVE_FLAG,
                   CAN_LOGIN,
                   SEND_ACTIVATION_EMAIL,
                   PIN,
                   SSO_ID,
                   ALTERNATE_USER_ID,
                   --rank the results always giving precedence to an active association
                   DENSE_RANK ()
                       OVER (PARTITION BY STAFF_ID ORDER BY ACTIVE_FLAG)
                       AS SEQ_NO
              FROM EntirePop)
     WHERE SEQ_NO = 1
    UNION
    SELECT 'XXXXXXX1' AS STAFF_ID,
           'N'        AS ACTIVE_FLAG,
           'N'        AS CAN_LOGIN,
           'N'        AS SEND_ACTIVATION_EMAIL,
           ' '        AS PIN,
           ' '        AS SSO_ID,
           ' '        AS ALTERNATE_USER_ID
      FROM DUAL
    UNION
    SELECT 'XXXXXXX2' AS STAFF_ID,
           'N'        AS ACTIVE_FLAG,
           'N'        AS CAN_LOGIN,
           'N'        AS SEND_ACTIVATION_EMAIL,
           ' '        AS PIN,
           ' '        AS SSO_ID,
           ' '        AS ALTERNATE_USER_ID
      FROM DUAL