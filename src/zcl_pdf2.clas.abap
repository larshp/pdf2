CLASS zcl_pdf2 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        iv_page_width  TYPE i DEFAULT 595
        iv_page_height TYPE i DEFAULT 842
      RAISING
        zcx_pdf2.

    METHODS add_page
      RETURNING
        VALUE(rv_page) TYPE i.

    METHODS add_text
      IMPORTING
        iv_page      TYPE i
        iv_x         TYPE i
        iv_y         TYPE i
        iv_text      TYPE string
        iv_font_size TYPE i DEFAULT 12
      RAISING
        zcx_pdf2.

    METHODS add_line
      IMPORTING
        iv_page       TYPE i
        iv_x1         TYPE i
        iv_y1         TYPE i
        iv_x2         TYPE i
        iv_y2         TYPE i
        iv_line_width TYPE i DEFAULT 1
      RAISING
        zcx_pdf2.

    METHODS add_rectangle
      IMPORTING
        iv_page       TYPE i
        iv_x          TYPE i
        iv_y          TYPE i
        iv_width      TYPE i
        iv_height     TYPE i
        iv_line_width TYPE i DEFAULT 1
        iv_fill       TYPE abap_bool DEFAULT abap_false
      RAISING
        zcx_pdf2.

    METHODS to_xstring
      RETURNING
        VALUE(rv_pdf) TYPE xstring.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_page,
        content TYPE string,
      END OF ty_page,
      ty_pages TYPE STANDARD TABLE OF ty_page WITH EMPTY KEY.

    CONSTANTS c_max_page_size TYPE i VALUE 14400.

    DATA mv_page_width  TYPE i.
    DATA mv_page_height TYPE i.
    DATA mt_pages       TYPE ty_pages.

    METHODS append_content
      IMPORTING
        iv_page    TYPE i
        iv_content TYPE string
      RAISING
        zcx_pdf2.
ENDCLASS.

CLASS zcl_pdf2 IMPLEMENTATION.
  METHOD constructor.
    IF iv_page_width <= 0 OR iv_page_height <= 0
       OR iv_page_width > c_max_page_size
       OR iv_page_height > c_max_page_size.
      RAISE EXCEPTION TYPE zcx_pdf2
        EXPORTING
          iv_text = 'Page dimensions must be between 1 and 14400 points'.
    ENDIF.

    mv_page_width = iv_page_width.
    mv_page_height = iv_page_height.
    APPEND INITIAL LINE TO mt_pages.
  ENDMETHOD.

  METHOD add_page.
    APPEND INITIAL LINE TO mt_pages.
    rv_page = lines( mt_pages ).
  ENDMETHOD.

  METHOD add_text.
    DATA lo_converter TYPE REF TO cl_abap_conv_out_ce.
    DATA lv_encoded   TYPE xstring.
    DATA lv_hex       TYPE string.
    DATA lv_byte      TYPE x LENGTH 1.
    DATA lv_byte_hex  TYPE c LENGTH 2.
    DATA lv_offset    TYPE i.

    IF iv_font_size <= 0.
      RAISE EXCEPTION TYPE zcx_pdf2
        EXPORTING
          iv_text = 'Font size must be positive'.
    ENDIF.

    TRY.
        lo_converter = cl_abap_conv_out_ce=>create( encoding = 'WINDOWS-1252' ).
        lv_encoded = lo_converter->convert( source = iv_text ).
      CATCH cx_sy_conversion_codepage.
        RAISE EXCEPTION TYPE zcx_pdf2
          EXPORTING
            iv_text = 'Text contains characters not supported by Windows-1252'.
    ENDTRY.

    DO xstrlen( lv_encoded ) TIMES.
      lv_offset = sy-index - 1.
      lv_byte = lv_encoded+lv_offset(1).
      WRITE lv_byte TO lv_byte_hex.
      TRANSLATE lv_byte_hex TO UPPER CASE.
      CONCATENATE lv_hex lv_byte_hex INTO lv_hex.
    ENDDO.

    append_content(
      iv_page    = iv_page
      iv_content = |BT /F1 { iv_font_size } Tf { iv_x } { iv_y } Td <{ lv_hex }> Tj ET| ).
  ENDMETHOD.

  METHOD add_line.
    IF iv_line_width <= 0.
      RAISE EXCEPTION TYPE zcx_pdf2
        EXPORTING
          iv_text = 'Line width must be positive'.
    ENDIF.

    append_content(
      iv_page    = iv_page
      iv_content = |q { iv_line_width } w { iv_x1 } { iv_y1 } m { iv_x2 } { iv_y2 } l S Q| ).
  ENDMETHOD.

  METHOD add_rectangle.
    DATA lv_operator TYPE string.

    IF iv_width <= 0 OR iv_height <= 0.
      RAISE EXCEPTION TYPE zcx_pdf2
        EXPORTING
          iv_text = 'Rectangle width and height must be positive'.
    ENDIF.
    IF iv_line_width <= 0.
      RAISE EXCEPTION TYPE zcx_pdf2
        EXPORTING
          iv_text = 'Line width must be positive'.
    ENDIF.

    IF iv_fill = abap_true.
      lv_operator = 'f'.
    ELSE.
      lv_operator = 'S'.
    ENDIF.

    append_content(
      iv_page    = iv_page
      iv_content = |q { iv_line_width } w { iv_x } { iv_y } { iv_width } { iv_height } re { lv_operator } Q| ).
  ENDMETHOD.

  METHOD append_content.
    FIELD-SYMBOLS <page> TYPE ty_page.

    READ TABLE mt_pages ASSIGNING <page> INDEX iv_page.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_pdf2
        EXPORTING
          iv_text = 'Page index is outside the document'.
    ENDIF.

    IF <page>-content IS INITIAL.
      <page>-content = iv_content.
    ELSE.
      <page>-content = <page>-content && cl_abap_char_utilities=>newline && iv_content.
    ENDIF.
  ENDMETHOD.

  METHOD to_xstring.
    DATA lt_objects       TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    DATA lt_offsets       TYPE STANDARD TABLE OF i WITH EMPTY KEY.
    DATA lv_kids          TYPE string.
    DATA lv_pdf_text      TYPE string.
    DATA lv_xref           TYPE string.
    DATA lv_stream         TYPE string.
    DATA lv_page_object_id TYPE i.
    DATA lv_content_id     TYPE i.
    DATA lv_object_id      TYPE i.
    DATA lv_object_count   TYPE i.
    DATA lv_size           TYPE i.
    DATA lv_offset         TYPE i.
    DATA lv_xref_offset    TYPE i.
    DATA lv_stream_length  TYPE i.
    DATA ls_page           TYPE ty_page.
    DATA lv_object         TYPE string.
    DATA lo_converter      TYPE REF TO cl_abap_conv_out_ce.

    APPEND '<< /Type /Catalog /Pages 2 0 R >>' TO lt_objects.

    LOOP AT mt_pages INTO ls_page.
      lv_page_object_id = 4 + ( sy-tabix - 1 ) * 2.
      IF lv_kids IS INITIAL.
        lv_kids = |{ lv_page_object_id } 0 R|.
      ELSE.
        lv_kids = lv_kids && | { lv_page_object_id } 0 R|.
      ENDIF.
    ENDLOOP.
    APPEND |<< /Type /Pages /Kids [ { lv_kids } ] /Count { lines( mt_pages ) } >>| TO lt_objects.
    APPEND '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>' TO lt_objects.

    LOOP AT mt_pages INTO ls_page.
      lv_page_object_id = 4 + ( sy-tabix - 1 ) * 2.
      lv_content_id = lv_page_object_id + 1.

      lv_object = |<< /Type /Page /Parent 2 0 R /MediaBox [0 0 { mv_page_width } { mv_page_height }]|
        && | /Resources << /Font << /F1 3 0 R >> >> /Contents { lv_content_id } 0 R >>|.
      APPEND lv_object TO lt_objects.

      lv_stream = ls_page-content && cl_abap_char_utilities=>newline.
      lv_stream_length = strlen( lv_stream ).
      lv_object = |<< /Length { lv_stream_length } >>{ cl_abap_char_utilities=>newline }|
        && |stream{ cl_abap_char_utilities=>newline }{ lv_stream }endstream|.
      APPEND lv_object TO lt_objects.
    ENDLOOP.

    lv_object_count = lines( lt_objects ).
    lv_size = lv_object_count + 1.
    APPEND 0 TO lt_offsets.
    lv_pdf_text = |%PDF-1.4{ cl_abap_char_utilities=>newline }|.

    LOOP AT lt_objects INTO lv_object.
      lv_offset = strlen( lv_pdf_text ).
      APPEND lv_offset TO lt_offsets.
      lv_object_id = sy-tabix.
      lv_pdf_text = lv_pdf_text
        && |{ lv_object_id } 0 obj{ cl_abap_char_utilities=>newline }{ lv_object }{ cl_abap_char_utilities=>newline }endobj{ cl_abap_char_utilities=>newline }|.
    ENDLOOP.

    lv_xref_offset = strlen( lv_pdf_text ).
    lv_xref = |xref{ cl_abap_char_utilities=>newline }0 { lv_size }{ cl_abap_char_utilities=>newline }|
      && |0000000000 65535 f { cl_abap_char_utilities=>newline }|.
    LOOP AT lt_offsets INTO lv_offset FROM 2.
      lv_xref = lv_xref
        && |{ lv_offset WIDTH = 10 ALIGN = RIGHT PAD = '0' } 00000 n { cl_abap_char_utilities=>newline }|.
    ENDLOOP.

    lv_pdf_text = lv_pdf_text && lv_xref
      && |trailer{ cl_abap_char_utilities=>newline }|
      && |<< /Size { lv_size } /Root 1 0 R >>{ cl_abap_char_utilities=>newline }|
      && |startxref{ cl_abap_char_utilities=>newline }{ lv_xref_offset }{ cl_abap_char_utilities=>newline }|
      && |%%EOF{ cl_abap_char_utilities=>newline }|.

    lo_converter = cl_abap_conv_out_ce=>create( encoding = 'UTF-8' ).
    rv_pdf = lo_converter->convert( source = lv_pdf_text ).
  ENDMETHOD.
ENDCLASS.
