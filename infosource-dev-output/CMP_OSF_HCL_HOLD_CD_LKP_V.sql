WITH
        MaxDatedSrvcIndCd
        AS
            (SELECT SRVC_CD_TBL.INSTITUTION,
                    SRVC_CD_TBL.SRVC_IND_CD,
                    SRVC_CD_TBL.EFFDT,
                    SRVC_CD_TBL.EFF_STATUS,
                    SRVC_CD_TBL.DESCR,
                    SRVC_CD_TBL.DESCRSHORT,
                    SRVC_CD_TBL.POS_SRVC_INDICATOR,
                    SRVC_CD_TBL.SCC_HOLD_DISPLAY,
                    SRVC_CD_TBL.SCC_SI_PERS,
                    SRVC_CD_TBL.SCC_SI_ORG,
                    SRVC_CD_TBL.SCC_DFLT_ACTDATE,
                    SRVC_CD_TBL.SCC_DFLT_ACTTERM,
                    SRVC_CD_TBL.DFLT_SRVC_IND_RSN,
                    SRVC_CD_TBL.SRV_IND_DCSD_FLAG
               FROM PS_RPT.PS_SRVC_IND_CD_TBL_V SRVC_CD_TBL
              WHERE     EFF_STATUS = 'A'
                    AND INSTITUTION = 'UBFLO'
                    AND EFFDT =
                        (SELECT MAX (EFFDT)
                           FROM PS_RPT.PS_SRVC_IND_CD_TBL_V
                          WHERE     SRVC_CD_TBL.SRVC_IND_CD = SRVC_IND_CD
                                AND INSTITUTION = 'UBFLO')),
        MaxDatedSrvcIndRsn
        AS
            (SELECT SRVC_RSN_TBL.INSTITUTION,
                    SRVC_RSN_TBL.SRVC_IND_CD,
                    SRVC_RSN_TBL.EFFDT,
                    SRVC_RSN_TBL.SRVC_IND_REASON,
                    SRVC_RSN_TBL.DESCR,
                    SRVC_RSN_TBL.DESCRSHORT,
                    SRVC_RSN_TBL.SRVC_IN_REF_TYPE,
                    SRVC_RSN_TBL.DEPTID,
                    SRVC_RSN_TBL.POSITION_NBR,
                    SRVC_RSN_TBL.CHECKLIST_CONTROL,
                    SRVC_RSN_TBL.MULTPLE_OCCUR,
                    SRVC_RSN_TBL.DESCRLONG
               FROM PS_RPT.PS_SRVC_IN_RSN_TBL_V SRVC_RSN_TBL
              WHERE     INSTITUTION = 'UBFLO'
                    AND EFFDT =
                        (SELECT MAX (EFFDT)
                           FROM PS_RPT.PS_SRVC_IN_RSN_TBL_V
                          WHERE     SRVC_RSN_TBL.SRVC_IND_CD = SRVC_IND_CD
                                AND SRVC_RSN_TBL.SRVC_IND_REASON =
                                    SRVC_IND_REASON
                                AND INSTITUTION = 'UBFLO')),
        MaxDatedActiveSrvcIndCdImpacts
        AS
            (SELECT SRVC_IMPACT.INSTITUTION,
                    SRVC_IMPACT.SRVC_IND_CD,
                    SRVC_IMPACT.EFFDT,
                    SRVC_IMPACT.SERVICE_IMPACT,
                    SRVC_IMPACT.TERM_CATEGORY,
                    SRVC_IMPACT.DESCRLONG
               FROM PS_RPT.PS_SERVICE_IMPACT_V  SRVC_IMPACT
                    JOIN PS_RPT.PS_SRVC_IMPACT_TBL_V SRVC_IMP_TBL
                        ON     SRVC_IMPACT.INSTITUTION =
                               SRVC_IMP_TBL.INSTITUTION
                           AND SRVC_IMPACT.SERVICE_IMPACT =
                               SRVC_IMP_TBL.SERVICE_IMPACT
              WHERE     SRVC_IMPACT.INSTITUTION = 'UBFLO'
                    AND SRVC_IMP_TBL.INSTITUTION = 'UBFLO'
                    AND SRVC_IMPACT.EFFDT =
                        (SELECT MAX (EFFDT)
                           FROM PS_RPT.PS_SERVICE_IMPACT_V
                          WHERE     SRVC_IMPACT.SRVC_IND_CD = SRVC_IND_CD
                                AND SRVC_IMPACT.SERVICE_IMPACT =
                                    SERVICE_IMPACT
                                AND INSTITUTION = 'UBFLO')
                    AND SRVC_IMP_TBL.EFFDT =
                        (SELECT MAX (EFFDT)
                           FROM PS_RPT.PS_SRVC_IMPACT_TBL_V
                          WHERE     SRVC_IMP_TBL.SERVICE_IMPACT =
                                    SERVICE_IMPACT
                                AND INSTITUTION = 'UBFLO')
                    AND SRVC_IMP_TBL.EFF_STATUS = 'A')
      SELECT (SrvcIndCd.SRVC_IND_CD || '-' || SrvcIndRsn.SRVC_IND_REASON)
                 AS HOLD_CD,
             (SrvcIndCd.DESCR || ' - ' || SrvcIndRsn.DESCR)
                 AS DESCRIPTION,
             CASE
                 WHEN (SELECT 'X'
                         FROM MaxDatedActiveSrvcIndCdImpacts
                        WHERE     SrvcIndCd.SRVC_IND_CD = SRVC_IND_CD
                              AND SERVICE_IMPACT IN ('WENR', 'AENR', 'CENR')) =
                      'X'
                 THEN
                     'Y'
                 ELSE
                     'N'
             END
                 AS REGISTRATION_HOLD
        FROM MaxDatedSrvcIndCd SrvcIndCd
             JOIN MaxDatedSrvcIndRsn SrvcIndRsn
                 ON     SrvcIndCd.INSTITUTION = SrvcIndRsn.INSTITUTION
                    AND SrvcIndCd.SRVC_IND_CD = SrvcIndRsn.SRVC_IND_CD
       WHERE     SrvcIndCd.POS_SRVC_INDICATOR = 'N'
             AND SrvcIndCd.SCC_HOLD_DISPLAY = 'Y'
    ORDER BY HOLD_CD ASC