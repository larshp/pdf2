CLASS ltcl_demo DEFINITION FOR TESTING RISK LEVEL HARMLESS DURATION SHORT FINAL.

  PRIVATE SECTION.
    METHODS build FOR TESTING RAISING zcx_pdf_error.
    METHODS readme_example FOR TESTING RAISING zcx_pdf_error.

    METHODS assert_eof
      IMPORTING
        iv_pdf TYPE xstring.
ENDCLASS.

CLASS ltcl_demo IMPLEMENTATION.

  METHOD assert_eof.
    DATA lv_eof TYPE xstring.

    lv_eof = zcl_pdf_util=>ascii( `%%EOF` ).
    FIND lv_eof IN iv_pdf IN BYTE MODE.
    cl_abap_unit_assert=>assert_subrc( ).
  ENDMETHOD.

  METHOD build.
    assert_eof( zcl_pdf_demo=>build( ) ).
  ENDMETHOD.

  METHOD readme_example.
* keep in sync with README.md
    DATA lo_document TYPE REF TO zcl_pdf_document.
    DATA lo_page TYPE REF TO zcl_pdf_page.
    DATA lv_pdf TYPE xstring.

    lo_document = zcl_pdf_document=>create( ).
    lo_document->set_title( `Hello` ).

    lo_page = lo_document->add_page( zcl_pdf_document=>c_format-a4 ).

    lo_page->set_font(
      iv_name = zcl_pdf_font=>c_name-helvetica_bold
      iv_size = 20 ).
    lo_page->text(
      iv_x    = 50
      iv_y    = 50
      iv_text = `Hello World` ).

    lo_page->set_font(
      iv_name = zcl_pdf_font=>c_name-times_roman
      iv_size = 11 ).
    lo_page->text_box(
      iv_x     = 50
      iv_y     = 90
      iv_width = lo_page->get_width( ) - 100
      iv_text  = `Long text is wrapped at word boundaries to fit the width of the box.`
      iv_align = zcl_pdf_page=>c_align-justify ).

    lo_page->set_fill_color( '#1F4E79' ).
    lo_page->rectangle(
      iv_x      = 50
      iv_y      = 150
      iv_width  = 200
      iv_height = 100
      iv_radius = 10
      iv_style  = zcl_pdf_page=>c_style-fill ).

    lv_pdf = lo_document->render( ).

    assert_eof( lv_pdf ).
  ENDMETHOD.

ENDCLASS.
