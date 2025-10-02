DECLARE
   sql_msg_ VARCHAR2(32000);
   stmt_    VARCHAR2(32000);
   attr_    VARCHAR2(32000);   
BEGIN    
    stmt_ := 'DECLARE
    attr_cf_   VARCHAR2(32000);
    c_pl_type_ VARCHAR2(10);
    c_pl_no_   VARCHAR2(100);
    c_value_   VARCHAR2(32000);
    c_count_   NUMBER := 0;
    c_line_no_ NUMBER := 0;
    info_      VARCHAR2(2000);
    objid_     VARCHAR2(500);
    objversion_ VARCHAR2(500);
    planned_ship_date_ VARCHAR2(50) := ''&C_PLANNED_SHIP_DATE_PROJ'';
    planned_ship_time_ VARCHAR2(50) := ''&C_PLANNED_SHIP_TIME_PROJ'';

    CURSOR get_pl_lines_ IS
      SELECT * 
      FROM INVENTORY_PART_RESERVATION 
      WHERE PICK_LIST_NO = ''&NEW:PICK_LIST_NO''
      AND LOCATION_NO = ''AS'';
    
    CURSOR check_exists_ IS
      SELECT COUNT(*) AS CNT
      FROM C_Platned_As_Pl_Lines_CLV
      WHERE CF$_C_PL_NO = ''&NEW:PICK_LIST_NO'';

    BEGIN    
    
      FOR line_rec IN get_pl_lines_ LOOP
        
        IF c_value_ IS NULL THEN
            c_value_ := ''['';
        ELSE
            c_value_ := c_value_ || '','';
        END IF;
        
        c_pl_no_   := ''&NEW:PICK_LIST_NO'';
        c_line_no_ := c_line_no_ + 1;

        c_value_ := c_value_ || ''{'' ||
            ''"TransactionId": 20250814,'' ||
            ''"ExtPickListId": "PD^'' || line_rec.PICK_LIST_NO || ''^",'' ||
            ''"ExtPickListLineId": '' || c_line_no_ || '','' ||
            ''"ExtOrderId": "PD^'' || line_rec.PICK_LIST_NO || ''^'' || line_rec.SOURCE_REF1 || ''^'' || 
                          line_rec.SOURCE_REF2 || ''^'' || line_rec.SOURCE_REF3 || ''^",'' ||
            ''"ExtOrderLineId": '' || c_line_no_ || '','' ||
            ''"ExtProductId": "'' || line_rec.PART_NO || ''",'' ||
            ''"BatchId": "'' || NVL(line_rec.LOT_BATCH_NO, '''') || ''",'' ||
            ''"Quantity": '' || line_rec.QTY_RESERVED || '','' ||
            ''"OrderTypeId": "PD",'' ||
            ''"OrderTypeText": "Project Deliverables",'' ||
            ''"ExtPickDate": "'' || planned_ship_date_ || ''",'' ||
            ''"ExtPickTime": "'' || CASE WHEN planned_ship_time_ = 0 THEN ''000000'' 
                                       ELSE planned_ship_time_ END || ''",'' ||
            ''"OrderLineNote": "'' || NVL(line_rec.CONTRACT, '''') || ''",'' ||
            ''"StockReservationKey": "'' || NVL(line_rec.CONTRACT, '''') || ''",'' ||
            ''"LineItemNo": "'' || line_rec.SOURCE_REF2 || ''"'' ||              
            ''}'';
      END LOOP;

      IF c_value_ IS NOT NULL THEN
          c_value_ := c_value_ || '']'';
      ELSE
          c_value_ := ''[]'';
      END IF;

      OPEN check_exists_;
      FETCH check_exists_ INTO c_count_;
      IF (c_count_ = 0) then
        CLIENT_SYS.Clear_Attr(attr_cf_);
        CLIENT_SYS.Add_To_Attr(''CF$_C_PL_TYPE'', ''PD'', attr_cf_);
        CLIENT_SYS.Add_To_Attr(''CF$_C_PL_NO'', c_pl_no_, attr_cf_);
        CLIENT_SYS.Add_To_Attr(''CF$_C_PL_LINES_BODY'', c_value_, attr_cf_);
        
        C_Platned_As_Pl_Lines_CLP.New__(info_,
                                        objid_,
                                        objversion_,
                                        attr_cf_,
                                        ''DO'');
      END IF;
      CLOSE check_exists_;
        
    END;';
            
    sql_msg_ := Message_SYS.Construct('DEFERREDEVENT');
    Message_SYS.Add_Attribute(sql_msg_, 'SQL', stmt_);
    Client_SYS.Clear_Attr(attr_);
    Client_SYS.Add_To_Attr('SQL_DATA_', sql_msg_, attr_);
    Client_SYS.Add_To_Attr('MSG_', '', attr_);
    Transaction_SYS.Deferred_Call('Fnd_Event_Action_API.Action_Executeonlinesql',
                                  'PARAMETER',
                                  attr_,
                                  Language_SYS.Translate_Constant('Event',
                                                                  'UPDATES: Platned AS Event for - Build Pick List Lines JSON. (PD)',
                                                                  NULL));
    sql_msg_ := null;
  
END;