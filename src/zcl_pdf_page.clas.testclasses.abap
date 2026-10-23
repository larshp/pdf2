CLASS ltcl_page DEFINITION DEFERRED.
CLASS zcl_pdf_page DEFINITION LOCAL FRIENDS ltcl_page.

CLASS ltcl_page DEFINITION FOR TESTING RISK LEVEL HARMLESS DURATION SHORT FINAL.

  PRIVATE SECTION.
    DATA mo_page TYPE REF TO zcl_pdf_page.

    METHODS setup RAISING zcx_pdf_error.
    METHODS text FOR TESTING.
    METHODS text_align_right FOR TESTING.
    METHODS text_color FOR TESTING RAISING zcx_pdf_error.
    METHODS set_font FOR TESTING RAISING zcx_pdf_error.
    METHODS text_box_wraps FOR TESTING RAISING zcx_pdf_error.
    METHODS text_box_paragraphs FOR TESTING.
    METHODS text_box_long_word FOR TESTING RAISING zcx_pdf_error.
    METHODS text_box_justify FOR TESTING RAISING zcx_pdf_error.
    METHODS text_box_empty FOR TESTING.
    METHODS measure_text_box FOR TESTING.
    METHODS line FOR TESTING.
    METHODS rectangle FOR TESTING RAISING zcx_pdf_error.
    METHODS rounded_rectangle FOR TESTING.
    METHODS circle FOR TESTING.
    METHODS polygon FOR TESTING.
    METHODS line_style FOR TESTING RAISING zcx_pdf_error.
    METHODS image FOR TESTING RAISING zcx_pdf_error.
    METHODS link FOR TESTING.
    METHODS invalid_color FOR TESTING.

    METHODS assert_content
      IMPORTING
        iv_sub TYPE string.

    METHODS count_operations
      IMPORTING
        iv_operation    TYPE string
      RETURNING
        VALUE(rv_count) TYPE i.
ENDCLASS.

CLASS ltcl_page IMPLEMENTATION.

  METHOD setup.
    mo_page = zcl_pdf_document=>create( )->add_page(
      iv_width  = 200
      iv_height = 100 ).
  ENDMETHOD.

  METHOD assert_content.
    IF mo_page->mv_content NS iv_sub.
      cl_abap_unit_assert=>fail( |"{ iv_sub }" not found in "{ mo_page->mv_content }"| ).
    ENDIF.
  ENDMETHOD.

  METHOD count_operations.
    FIND ALL OCCURRENCES OF iv_operation IN mo_page->mv_content MATCH COUNT rv_count.
  ENDMETHOD.

  METHOD text.
* baseline is at the top plus the ascent, 10 + 12 * 0.718
    mo_page->text(
      iv_x    = 10
      iv_y    = 10
      iv_text = `Hello` ).
    assert_content( 'BT /F1 12 Tf 10 81.384 Td <48656C6C6F> Tj ET' ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( mo_page->mt_fonts )
      exp = 1 ).
  ENDMETHOD.

  METHOD text_align_right.
    mo_page->text(
      iv_x     = 100
      iv_y     = 10
      iv_text  = `Hello`
      iv_align = zcl_pdf_page=>c_align-right ).
    assert_content( 'Tf 72.664 81.384 Td' ).
  ENDMETHOD.

  METHOD text_color.
    mo_page->set_text_color( '#FF0000' ).
    mo_page->set_fill_color( '#0000FF' ).
    mo_page->text(
      iv_x    = 10
      iv_y    = 10
      iv_text = `a` ).
    mo_page->rectangle(
      iv_x      = 0
      iv_y      = 0
      iv_width  = 10
      iv_height = 10
      iv_style  = zcl_pdf_page=>c_style-fill ).
    assert_content( |1 0 0 rg\nBT| ).
    assert_content( |0 0 1 rg\n0 90 10 10 re\nf| ).
  ENDMETHOD.

  METHOD set_font.
    mo_page->set_font(
      iv_name = zcl_pdf_font=>c_name-courier_bold
      iv_size = 20 ).
    mo_page->set_font( zcl_pdf_font=>c_name-courier ).
    cl_abap_unit_assert=>assert_equals(
      act = mo_page->get_font_size( )
      exp = 20
      tol = '0.001' ).
    cl_abap_unit_assert=>assert_equals(
      act = mo_page->get_text_width( `abc` )
      exp = 36
      tol = '0.001' ).
  ENDMETHOD.

  METHOD text_box_wraps.
    DATA lv_height TYPE f.

* Courier 10, each character is 6 points wide, 5 characters per line
    mo_page->set_font(
      iv_name = zcl_pdf_font=>c_name-courier
      iv_size = 10 ).
    lv_height = mo_page->text_box(
      iv_x     = 0
      iv_y     = 0
      iv_width = 30
      iv_text  = `aa bb cc dd` ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_height
      exp = 24
      tol = '0.0001' ).
    assert_content( '<6161206262> Tj' ).
    assert_content( '<6363206464> Tj' ).
  ENDMETHOD.

  METHOD text_box_paragraphs.
    DATA lv_height TYPE f.

    lv_height = mo_page->text_box(
      iv_x            = 0
      iv_y            = 0
      iv_width        = 150
      iv_text         = |one\ntwo\n\nfour|
      iv_line_spacing = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_height
      exp = 48
      tol = '0.0001' ).
    cl_abap_unit_assert=>assert_equals(
      act = count_operations( ' Tj' )
      exp = 3 ).
  ENDMETHOD.

  METHOD text_box_long_word.
    DATA lv_height TYPE f.

    mo_page->set_font(
      iv_name = zcl_pdf_font=>c_name-courier
      iv_size = 10 ).
    lv_height = mo_page->text_box(
      iv_x            = 0
      iv_y            = 0
      iv_width        = 30
      iv_text         = `abcdefghijkl`
      iv_line_spacing = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_height
      exp = 30
      tol = '0.0001' ).
    assert_content( '<6162636465> Tj' ).
    assert_content( '<666768696A> Tj' ).
    assert_content( '<6B6C> Tj' ).
  ENDMETHOD.

  METHOD text_box_justify.
    mo_page->set_font(
      iv_name = zcl_pdf_font=>c_name-courier
      iv_size = 10 ).
    mo_page->text_box(
      iv_x     = 0
      iv_y     = 0
      iv_width = 50
      iv_text  = `a b c ddddd`
      iv_align = zcl_pdf_page=>c_align-justify ).
* first line "a b c" is 30 wide, 20 points distributed on 2 spaces, the last line is not justified
    assert_content( '10 Tw <6120622063> Tj 0 Tw' ).
    assert_content( '<6464646464> Tj ET' ).
  ENDMETHOD.

  METHOD text_box_empty.
    cl_abap_unit_assert=>assert_equals(
      act = mo_page->text_box(
        iv_x     = 0
        iv_y     = 0
        iv_width = 100
        iv_text  = `` )
      exp = 0
      tol = '0.001' ).
    cl_abap_unit_assert=>assert_initial( mo_page->mv_content ).
  ENDMETHOD.

  METHOD measure_text_box.
    DATA lv_text TYPE string.
    DATA lv_measured TYPE f.
    DATA lv_lines TYPE i.

    lv_text = `The quick brown fox jumps over the lazy dog, again and again and again.`.
    lv_measured = mo_page->measure_text_box(
      iv_width = 80
      iv_text  = lv_text ).
    cl_abap_unit_assert=>assert_initial( mo_page->mv_content ).
    cl_abap_unit_assert=>assert_equals(
      act = mo_page->text_box(
        iv_x     = 0
        iv_y     = 0
        iv_width = 80
        iv_text  = lv_text )
      exp = lv_measured ).
    lv_lines = lv_measured / '14.4'.
    cl_abap_unit_assert=>assert_equals(
      act = count_operations( ' Tj' )
      exp = lv_lines ).
  ENDMETHOD.

  METHOD line.
    mo_page->line(
      iv_x1 = 10
      iv_y1 = 0
      iv_x2 = 50
      iv_y2 = 75 ).
    assert_content( '10 100 m 50 25 l S' ).
  ENDMETHOD.

  METHOD rectangle.
    mo_page->set_fill_color( '#808080' ).
    mo_page->rectangle(
      iv_x      = 10
      iv_y      = 20
      iv_width  = 30
      iv_height = 40
      iv_style  = zcl_pdf_page=>c_style-fill_stroke ).
    assert_content( |0.502 0.502 0.502 rg\n10 40 30 40 re\nB| ).
  ENDMETHOD.

  METHOD rounded_rectangle.
    mo_page->rectangle(
      iv_x      = 0
      iv_y      = 0
      iv_width  = 100
      iv_height = 50
      iv_radius = 10 ).
    assert_content( |10 100 m\n90 100 l\n| ).
    cl_abap_unit_assert=>assert_equals(
      act = count_operations( | c| )
      exp = 4 ).
  ENDMETHOD.

  METHOD circle.
    mo_page->circle(
      iv_x      = 50
      iv_y      = 50
      iv_radius = 10
      iv_style  = zcl_pdf_page=>c_style-fill ).
    assert_content( |60 50 m\n| ).
    assert_content( |50 40 c\n| ).
    assert_content( |60 50 c h\nf| ).
  ENDMETHOD.

  METHOD polygon.
    DATA lt_points TYPE zcl_pdf_page=>ty_points.
    DATA ls_point LIKE LINE OF lt_points.

    ls_point-x = 0.
    ls_point-y = 0.
    APPEND ls_point TO lt_points.
    ls_point-x = 10.
    ls_point-y = 20.
    APPEND ls_point TO lt_points.
    ls_point-x = 20.
    ls_point-y = 0.
    APPEND ls_point TO lt_points.

    mo_page->polygon( lt_points ).
    assert_content( |0 100 m 10 80 l 20 100 l h\nS| ).
  ENDMETHOD.

  METHOD line_style.
    mo_page->set_line_width( '0.5' ).
    mo_page->set_line_dash( 3 ).
    mo_page->set_line_dash( ).
    mo_page->set_stroke_color( '#00FF00' ).
    assert_content( |0.5 w\n[3 3] 0 d\n[] 0 d\n0 1 0 RG\n| ).
  ENDMETHOD.

  METHOD image.
    DATA lo_image TYPE REF TO zcl_pdf_image.
    DATA lv_png TYPE xstring.
    DATA lv_end TYPE xstring.

* PNG, 4 x 2 pixels, RGB
    lv_png = '89504E470D0A1A0A0000000D49484452000000040000000208020000000000000000000003494441540102030000000000000000'.
    lv_end = '49454E4400000000'.
    CONCATENATE lv_png lv_end INTO lv_png IN BYTE MODE.
    lo_image = zcl_pdf_image=>load( lv_png ).
    mo_page->image(
      io_image = lo_image
      iv_x     = 10
      iv_y     = 10
      iv_width = 40 ).
    mo_page->image(
      io_image = lo_image
      iv_x     = 0
      iv_y     = 0 ).

    assert_content( |q 40 0 0 20 10 70 cm { lo_image->get_resource_name( ) } Do Q| ).
    assert_content( |q 4 0 0 2 0 98 cm { lo_image->get_resource_name( ) } Do Q| ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( mo_page->mt_images )
      exp = 1 ).
  ENDMETHOD.

  METHOD link.
    DATA lv_annotation TYPE string.

    mo_page->link(
      iv_x      = 10
      iv_y      = 10
      iv_width  = 20
      iv_height = 5
      iv_url    = 'https://abap.org' ).
    READ TABLE mo_page->mt_annotations INDEX 1 INTO lv_annotation.
    cl_abap_unit_assert=>assert_subrc( ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_annotation
      exp = `<< /Type /Annot /Subtype /Link /Rect [10 85 30 90] /Border [0 0 0] /A << /S /URI /URI ` &&
            `<68747470733A2F2F616261702E6F7267> >> >>` ).
  ENDMETHOD.

  METHOD invalid_color.
    TRY.
        mo_page->set_fill_color( '#12345' ).
        cl_abap_unit_assert=>fail( ).
      CATCH zcx_pdf_error ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
