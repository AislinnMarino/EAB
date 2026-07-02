SELECT DISTINCT STBL.SUBJECT AS SUBJECT_CD, STBL.DESCRFORMAL AS NAME
        FROM PS_SUBJECT_TBL STBL
        --We want to include both inactive and active subjects
       WHERE STBL.EFFDT = (SELECT MAX (EFFDT)
                             FROM PS_SUBJECT_TBL
                            WHERE STBL.SUBJECT = SUBJECT)
    ORDER BY STBL.SUBJECT ASC