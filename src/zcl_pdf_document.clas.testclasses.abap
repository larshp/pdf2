CLASS ltcl_document DEFINITION FOR TESTING RISK LEVEL HARMLESS DURATION SHORT FINAL.

  PRIVATE SECTION.
    "! Length of the header, '%PDF-1.4', a comment with 4 binary bytes, and newlines
    CONSTANTS c_header_length TYPE i VALUE 15.

    METHODS empty_document FOR TESTING.
    METHODS header_and_trailer FOR TESTING RAISING zcx_pdf_error.
    METHODS object_structure FOR TESTING RAISING zcx_pdf_error.
    METHODS xref_offsets FOR TESTING RAISING zcx_pdf_error.
    METHODS shared_font FOR TESTING RAISING zcx_pdf_error.
    METHODS image_object FOR TESTING RAISING zcx_pdf_error.
    METHODS annotations FOR TESTING RAISING zcx_pdf_error.
    METHODS metadata FOR TESTING.
    METHODS page_formats FOR TESTING RAISING zcx_pdf_error.
    METHODS unknown_format FOR TESTING.
    METHODS get_page FOR TESTING RAISING zcx_pdf_error.
    METHODS mm FOR TESTING.

    "! Renders the document, and returns everything after the binary header as text
    METHODS render
      IMPORTING
        io_document    TYPE REF TO zcl_pdf_document
      RETURNING
        VALUE(rv_text) TYPE string.

    METHODS assert_contains
      IMPORTING
        iv_text TYPE string
        iv_sub  TYPE string.

    METHODS count_occurrences
      IMPORTING
        iv_text         TYPE string
        iv_sub          TYPE string
      RETURNING
        VALUE(rv_count) TYPE i.
ENDCLASS.

CLASS ltcl_document IMPLEMENTATION.

  METHOD render.
    DATA lv_pdf TYPE xstring.
    DATA lv_body TYPE xstring.
    DATA lo_conv TYPE REF TO cl_abap_conv_in_ce.

    lv_pdf = io_document->render( ).
    lv_body = lv_pdf+c_header_length.
    lo_conv = cl_abap_conv_in_ce=>create(
      encoding = 'UTF-8'
      input    = lv_body ).
    lo_conv->read( IMPORTING data = rv_text ).
  ENDMETHOD.

  METHOD assert_contains.
    IF iv_text NS iv_sub.
      cl_abap_unit_assert=>fail( |"{ iv_sub }" not found in "{ iv_text }"| ).
    ENDIF.
  ENDMETHOD.

  METHOD count_occurrences.
    FIND ALL OCCURRENCES OF iv_sub IN iv_text MATCH COUNT rv_count.
  ENDMETHOD.

  METHOD empty_document.
    DATA lv_text TYPE string.

    lv_text = render( zcl_pdf_document=>create( ) ).
    assert_contains(
      iv_text = lv_text
      iv_sub  = '<< /Type /Pages /Kids [ ] /Count 0 >>' ).
    assert_contains(
      iv_text = lv_text
      iv_sub  = |xref\n0 4\n0000000000 65535 f \n0000000015 00000 n \n| ).
  ENDMETHOD.

  METHOD header_and_trailer.
    DATA lo_document TYPE REF TO zcl_pdf_document.
    DATA lv_pdf TYPE xstring.
    DATA lv_expected TYPE xstring.
    DATA lv_actual TYPE xstring.
    DATA lv_length TYPE i.
    DATA lv_offset TYPE i.

    lo_document = zcl_pdf_document=>create( ).
    lo_document->add_page( ).
    lv_pdf = lo_document->render( ).

    lv_expected = zcl_pdf_util=>ascii( |%PDF-1.4\n%| ).
    lv_actual = lv_pdf(10).
    cl_abap_unit_assert=>assert_equals(
      act = lv_actual
      exp = lv_expected ).

    lv_expected = zcl_pdf_util=>ascii( |%%EOF\n| ).
    lv_length = xstrlen( lv_expected ).
    lv_offset = xstrlen( lv_pdf ) - lv_length.
    lv_actual = lv_pdf+lv_offset(lv_length).
    cl_abap_unit_assert=>assert_equals(
      act = lv_actual
      exp = lv_expected ).
  ENDMETHOD.

  METHOD object_structure.
    DATA lo_document TYPE REF TO zcl_pdf_document.
    DATA lv_text TYPE string.

    lo_document = zcl_pdf_document=>create( ).
    lo_document->add_page( )->text(
      iv_x    = 10
      iv_y    = 10
      iv_text = `Hello` ).
    lv_text = render( lo_document ).

    assert_contains(
      iv_text = lv_text
      iv_sub  = |1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n| ).
    assert_contains(
      iv_text = lv_text
      iv_sub  = |2 0 obj\n<< /Type /Pages /Kids [ 5 0 R ] /Count 1 >>\nendobj\n| ).
    assert_contains(
      iv_text = lv_text
      iv_sub  = |4 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>| ).
    assert_contains(
      iv_text = lv_text
      iv_sub  = |5 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595.28 841.89]| &&
                | /Resources << /Font << /F1 4 0 R >> >> /Contents 6 0 R >>| ).
    assert_contains(
      iv_text = lv_text
      iv_sub  = |6 0 obj\n<< /Length 46 >>\nstream\nBT /F1 12 Tf 10 823.274 Td <48656C6C6F> Tj ET\n\nendstream| ).
    assert_contains(
      iv_text = lv_text
      iv_sub  = |trailer\n<< /Size 7 /Root 1 0 R /Info 3 0 R >>\nstartxref\n| ).
  ENDMETHOD.

  METHOD xref_offsets.
    DATA lo_document TYPE REF TO zcl_pdf_document.
    DATA lo_page TYPE REF TO zcl_pdf_page.
    DATA lv_text TYPE string.
    DATA lv_xref TYPE i.
    DATA lv_startxref TYPE string.
    DATA lt_lines TYPE string_table.
    DATA lv_line LIKE LINE OF lt_lines.
    DATA lv_offset TYPE i.
    DATA lv_number TYPE i.
    DATA lv_object TYPE string.

    lo_document = zcl_pdf_document=>create( ).
    lo_document->set_title( `Offsets` ).
    lo_page = lo_document->add_page( ).
    lo_page->text(
      iv_x    = 10
      iv_y    = 10
      iv_text = `First` ).
    lo_page = lo_document->add_page( ).
    lo_page->set_font( zcl_pdf_font=>c_name-times_bold ).
    lo_page->text(
      iv_x    = 10
      iv_y    = 10
      iv_text = `Second` ).
    lv_text = render( lo_document ).

    FIND REGEX 'startxref\s+(\d+)' IN lv_text SUBMATCHES lv_startxref.
    cl_abap_unit_assert=>assert_subrc( ).
    lv_xref = lv_startxref.
    lv_xref = lv_xref - c_header_length.
    cl_abap_unit_assert=>assert_equals(
      act = substring( val = lv_text
                       off = lv_xref
                       len = 4 )
      exp = 'xref' ).

    SPLIT lv_text+lv_xref AT cl_abap_char_utilities=>newline INTO TABLE lt_lines.
    LOOP AT lt_lines INTO lv_line FROM 4.
      IF lv_line NP '++++++++++ 00000 n*'.
        EXIT.
      ENDIF.
      lv_number = lv_number + 1.
      lv_offset = lv_line(10).
      lv_offset = lv_offset - c_header_length.
      lv_object = |{ lv_number } 0 obj\n|.
      cl_abap_unit_assert=>assert_equals(
        act = substring( val = lv_text
                         off = lv_offset
                         len = strlen( lv_object ) )
        exp = lv_object ).
    ENDLOOP.

    cl_abap_unit_assert=>assert_equals(
      act = lv_number
      exp = 9 ).
  ENDMETHOD.

  METHOD shared_font.
    DATA lo_document TYPE REF TO zcl_pdf_document.
    DATA lv_text TYPE string.

    lo_document = zcl_pdf_document=>create( ).
    lo_document->add_page( )->text(
      iv_x    = 10
      iv_y    = 10
      iv_text = `One` ).
    lo_document->add_page( )->text(
      iv_x    = 10
      iv_y    = 10
      iv_text = `Two` ).
    lo_document->add_page( ).
    lv_text = render( lo_document ).

    cl_abap_unit_assert=>assert_equals(
      act = count_occurrences( iv_text = lv_text
                   iv_sub              = '/Type /Font' )
      exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = count_occurrences( iv_text = lv_text
                   iv_sub              = '/Font << /F1 4 0 R >>' )
      exp = 2 ).
    assert_contains(
      iv_text = lv_text
      iv_sub  = '/Kids [ 5 0 R 7 0 R 9 0 R ] /Count 3' ).
    assert_contains(
      iv_text = lv_text
      iv_sub  = '/Resources << >> /Contents 10 0 R' ).
  ENDMETHOD.

  METHOD image_object.
    DATA lo_document TYPE REF TO zcl_pdf_document.
    DATA lo_image TYPE REF TO zcl_pdf_image.
    DATA lv_text TYPE string.
    DATA lv_png TYPE xstring.
    DATA lv_end TYPE xstring.

    lv_png = '89504E470D0A1A0A0000000D49484452000000040000000208000000000000000000000003494441544142430000000000000000'.
    lv_end = '49454E4400000000'.
    CONCATENATE lv_png lv_end INTO lv_png IN BYTE MODE.
    lo_image = zcl_pdf_image=>load( lv_png ).
    lo_document = zcl_pdf_document=>create( ).
    lo_document->add_page( )->image(
      io_image = lo_image
      iv_x     = 0
      iv_y     = 0 ).
    lv_text = render( lo_document ).

    assert_contains(
      iv_text = lv_text
      iv_sub  = |4 0 obj\n<< /Type /XObject /Subtype /Image /Width 4 /Height 2 /ColorSpace /DeviceGray| ).
    assert_contains(
      iv_text = lv_text
      iv_sub  = |/Length 3 >>\nstream\nABC\nendstream\nendobj\n| ).
    assert_contains(
      iv_text = lv_text
      iv_sub  = |/Resources << /XObject << { lo_image->get_resource_name( ) } 4 0 R >> >>| ).
  ENDMETHOD.

  METHOD annotations.
    DATA lo_document TYPE REF TO zcl_pdf_document.
    DATA lv_text TYPE string.

    lo_document = zcl_pdf_document=>create( ).
    lo_document->add_page( )->link(
      iv_x      = 0
      iv_y      = 0
      iv_width  = 10
      iv_height = 10
      iv_url    = 'https://example.com' )->link(
      iv_x      = 0
      iv_y      = 20
      iv_width  = 10
      iv_height = 10
      iv_url    = 'https://example.org' ).
    lv_text = render( lo_document ).

    assert_contains(
      iv_text = lv_text
      iv_sub  = '/Contents 5 0 R /Annots [ << /Type /Annot' ).
    cl_abap_unit_assert=>assert_equals(
      act = count_occurrences( iv_text = lv_text
                   iv_sub              = '/Subtype /Link' )
      exp = 2 ).
  ENDMETHOD.

  METHOD metadata.
    DATA lo_document TYPE REF TO zcl_pdf_document.
    DATA lv_text TYPE string.

    lo_document = zcl_pdf_document=>create( ).
    lo_document->set_title( `T` )->set_author( `A` )->set_subject( `S` )->set_keywords( `K` )->set_creator( `C` ).
    lo_document->set_creation_date(
      iv_date = '20261023'
      iv_time = '153000' ).
    lv_text = render( lo_document ).

    assert_contains(
      iv_text = lv_text
      iv_sub  = |3 0 obj\n<< /Producer <FEFF0061006200610070002D007000640066> /Title <FEFF0054>| &&
                | /Author <FEFF0041> /Subject <FEFF0053> /Keywords <FEFF004B> /Creator <FEFF0043>| &&
                | /CreationDate <443A3230323631303233313533303030> >>| ).
  ENDMETHOD.

  METHOD page_formats.
    DATA lo_document TYPE REF TO zcl_pdf_document.
    DATA lo_page TYPE REF TO zcl_pdf_page.

    lo_document = zcl_pdf_document=>create( ).

    lo_page = lo_document->add_page( ).
    cl_abap_unit_assert=>assert_equals(
      act = lo_page->get_width( )
      exp = '595.28'
      tol = '0.001' ).
    cl_abap_unit_assert=>assert_equals(
      act = lo_page->get_height( )
      exp = '841.89'
      tol = '0.001' ).

    lo_page = lo_document->add_page(
      iv_format    = zcl_pdf_document=>c_format-letter
      iv_landscape = abap_true ).
    cl_abap_unit_assert=>assert_equals(
      act = lo_page->get_width( )
      exp = 792
      tol = '0.001' ).
    cl_abap_unit_assert=>assert_equals(
      act = lo_page->get_height( )
      exp = 612
      tol = '0.001' ).

    lo_page = lo_document->add_page( 'a5' ).
    cl_abap_unit_assert=>assert_equals(
      act = lo_page->get_width( )
      exp = '419.53'
      tol = '0.001' ).

    lo_page = lo_document->add_page(
      iv_width  = 100
      iv_height = 50 ).
    cl_abap_unit_assert=>assert_equals(
      act = lo_page->get_width( )
      exp = 100
      tol = '0.001' ).

    cl_abap_unit_assert=>assert_equals(
      act = lo_document->get_page_count( )
      exp = 4 ).
  ENDMETHOD.

  METHOD unknown_format.
    TRY.
        zcl_pdf_document=>create( )->add_page( 'B7' ).
        cl_abap_unit_assert=>fail( ).
      CATCH zcx_pdf_error ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.

  METHOD get_page.
    DATA lo_document TYPE REF TO zcl_pdf_document.
    DATA lo_page TYPE REF TO zcl_pdf_page.

    lo_document = zcl_pdf_document=>create( ).
    lo_page = lo_document->add_page( ).
    cl_abap_unit_assert=>assert_equals(
      act = lo_document->get_page( 1 )
      exp = lo_page ).

    TRY.
        lo_document->get_page( 2 ).
        cl_abap_unit_assert=>fail( ).
      CATCH zcx_pdf_error ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.

  METHOD mm.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_document=>mm( '25.4' )
      exp = 72
      tol = '0.0001' ).
  ENDMETHOD.

ENDCLASS.
