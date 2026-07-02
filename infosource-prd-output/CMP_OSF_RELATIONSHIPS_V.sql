WITH
        max_hist
        AS
            (SELECT AdvHist.ADVISOR_ROLE   AS NAME,
                    AdvHist.ADVISOR_ID     AS STAFF_ID,
                    AdvHist.EMPLID         AS STUDENT_ID,
                    AdvType.XLATLONGNAME AS ADVISOR_TYPE,
                    'UB'                   AS GROUP_ID,
                    AdvHist.COMMITTEE_ID,
                    ADVHIST.ACAD_CAREER,
                    ADVHIST.ACAD_PROG
               FROM PS_RPT.PS_STDNT_ADVR_HIST AdvHist JOIN PS_RPT.PSXLATITEM_V AdvType on AdvHist.ADVISOR_ROLE = AdvType.FieldValue AND FIELDNAME = 'ADVISOR_ROLE'
              WHERE     1 = 1
                    AND AdvHist.EFFDT =
                        (SELECT MAX (AdvHistDate.EFFDT)
                           FROM PS_RPT.PS_STDNT_ADVR_HIST AdvHistDate
                          WHERE AdvHistDate.EMPLID = AdvHist.EMPLID))
      SELECT m.name,
             m.staff_id,
             m.student_id,
             1     AS rank_no,
             m.advisor_type,
             m.GROUP_ID
        FROM max_hist m
       WHERE m.COMMITTEE_ID = ' ' 
    GROUP BY name,
             staff_id,
             student_id,
             advisor_type,
             GROUP_ID