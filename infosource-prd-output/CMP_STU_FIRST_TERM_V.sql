SELECT POPSELECT.STUDENT_ID     AS NK,
         POPSELECT.STUDENT_ID     AS STUDENT,
         MINTERM.STRM             AS TERM,
         'Y'                      AS IS_ACTIVE
    FROM PS_RPT.CMP_STUDENT_GENERAL_CURRENT_V  POPSELECT
         JOIN PS_RPT.PS_STDNT_CAR_TERM MINTERM
             ON     POPSELECT.STUDENT_ID = MINTERM.EMPLID
                AND MINTERM.STRM = (SELECT MIN (B.STRM)
                                      FROM PS_RPT.PS_STDNT_CAR_TERM B
                                     WHERE B.EMPLID = MINTERM.EMPLID)