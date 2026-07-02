SELECT DISTINCT
            a.FIELDVALUE AS STUDENT_TIME_CD,
            a.XLATLONGNAME AS STUDENT_TIME_DESC
       FROM ps_rpt.PSXLATITEM a
      WHERE     1 = 1
            AND a.FIELDNAME = 'ACADEMIC_LOAD'
            AND a.EFFDT =
                   (SELECT MAX (EFFDT)
                      FROM ps_rpt.PSXLATITEM
                     WHERE     FIELDVALUE = a.FIELDVALUE
                           AND XLATLONGNAME = a.XLATLONGNAME)
   ORDER BY 1