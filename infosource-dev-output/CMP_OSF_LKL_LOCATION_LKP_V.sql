WITH
    MaxDatedFacilCampusMap
    AS
        (SELECT DISTINCT
                FAC_TBL.FACILITY_ID,
                FAC_TBL.BLDG_CD,
                CASE
                    WHEN FAC_TBL.LOCATION = 'AAG'
                    THEN
                        'OFC'
                    ELSE
                        CASE
                            WHEN FAC_TBL.LOCATION = 'EC'
                            THEN
                                'NT'
                            ELSE
                                CASE
                                    WHEN FAC_TBL.LOCATION = 'RP'
                                    THEN
                                        'DT'
                                    ELSE
                                        CASE
                                            WHEN FAC_TBL.LOCATION = 'SINGSIM'
                                            THEN
                                                'OS'
                                            ELSE
                                                FAC_TBL.LOCATION
                                        END
                                END
                        END
                END             AS LOCATION,
                FAC_TBL.ROOM    AS ROOM
           FROM PS_RPT.PS_FACILITY_TBL FAC_TBL
          WHERE     FAC_TBL.EFF_STATUS = 'A'
                AND FAC_TBL.EFFDT =
                    (SELECT MAX (EFFDT)
                       FROM PS_RPT.PS_FACILITY_TBL
                      WHERE FAC_TBL.FACILITY_ID = FACILITY_ID)),
    MaxDatedActiveCampuses
    AS
        (SELECT CAMPUS_TBL.INSTITUTION,
                CAMPUS_TBL.CAMPUS,
                CAMPUS_TBL.EFFDT,
                CAMPUS_TBL.EFF_STATUS,
                CAMPUS_TBL.DESCR,
                CAMPUS_TBL.DESCRSHORT,
                CAMPUS_TBL.LOCATION,
                CAMPUS_TBL.FACILITY_CONFLICT
           FROM PS_RPT.PS_CAMPUS_TBL CAMPUS_TBL
          WHERE     EFFDT = (SELECT MAX (EFFDT)
                               FROM PS_RPT.PS_CAMPUS_TBL
                              WHERE CAMPUS_TBL.CAMPUS = CAMPUS)
                AND EFF_STATUS = 'A'),
    MaxDatedActiveBuildings
    AS
        (SELECT BLDG_TBL.BLDG_CD,
                BLDG_TBL.EFFDT,
                BLDG_TBL.EFF_STATUS,
                BLDG_TBL.DESCR,
                BLDG_TBL.DESCRSHORT,
                BLDG_TBL.SCC_LATITUDE,
                BLDG_TBL.SCC_LONGITUDE
           FROM PS_RPT.PS_BLDG_TBL BLDG_TBL
          WHERE     BLDG_TBL.EFF_STATUS = 'A'
                AND BLDG_TBL.EFFDT = (SELECT MAX (EFFDT)
                                        FROM PS_RPT.PS_BLDG_TBL
                                       WHERE BLDG_TBL.BLDG_CD = BLDG_CD))
  SELECT DISTINCT
         FC_MAP.FACILITY_ID    AS LOCATION_CD,
         CMP_V.CAMPUS          AS CAMPUS_CD,
         CASE
             WHEN     FC_MAP.LOCATION IN ('DT', 'NT', 'ST')
                  AND FC_MAP.ROOM <> 'ARR'
             THEN
                 FC_MAP.ROOM || ' ' || BLDG_V.DESCR
             ELSE
                 BLDG_V.DESCR
         END                   AS NAME,
         CASE
             WHEN BLDG_V.SCC_LATITUDE = '0' AND BLDG_V.SCC_LONGITUDE = '0'
             THEN
                 NULL
             ELSE
                 BLDG_V.SCC_LATITUDE || ',' || BLDG_V.SCC_LONGITUDE
         END                   AS ADDRESS
    FROM MaxDatedActiveBuildings BLDG_V
         JOIN MaxDatedFacilCampusMap FC_MAP ON BLDG_V.BLDG_CD = FC_MAP.BLDG_CD
         JOIN MaxDatedActiveCampuses CMP_V ON FC_MAP.LOCATION = CMP_V.LOCATION
ORDER BY FC_MAP.FACILITY_ID ASC