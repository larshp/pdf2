CLASS ltcl_font DEFINITION FOR TESTING RISK LEVEL HARMLESS DURATION SHORT FINAL.

  PRIVATE SECTION.
    METHODS helvetica_width FOR TESTING RAISING zcx_pdf_error.
    METHODS oblique_width FOR TESTING RAISING zcx_pdf_error.
    METHODS courier_width FOR TESTING RAISING zcx_pdf_error.
    METHODS times_width FOR TESTING RAISING zcx_pdf_error.
    METHODS case_insensitive FOR TESTING RAISING zcx_pdf_error.
    METHODS same_instance FOR TESTING RAISING zcx_pdf_error.
    METHODS unknown_font FOR TESTING.
    METHODS dictionary FOR TESTING RAISING zcx_pdf_error.
    METHODS ascent FOR TESTING RAISING zcx_pdf_error.
ENDCLASS.

CLASS ltcl_font IMPLEMENTATION.

  METHOD helvetica_width.
* H 722, e 556, l 222, l 222, o 556
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_font=>get( zcl_pdf_font=>c_name-helvetica )->get_text_width(
        iv_text = `Hello`
        iv_size = 12 )
      exp = '27.336'
      tol = '0.0001' ).
  ENDMETHOD.

  METHOD oblique_width.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_font=>get( zcl_pdf_font=>c_name-helvetica_bold_oblique )->get_text_width(
        iv_text = `Hello`
        iv_size = 10 )
      exp = zcl_pdf_font=>get( zcl_pdf_font=>c_name-helvetica_bold )->get_text_width(
        iv_text = `Hello`
        iv_size = 10 ) ).
  ENDMETHOD.

  METHOD courier_width.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_font=>get( zcl_pdf_font=>c_name-courier_bold )->get_text_width(
        iv_text = `abc`
        iv_size = 10 )
      exp = 18
      tol = '0.001' ).
  ENDMETHOD.

  METHOD times_width.
* space 250, W 944
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_font=>get( zcl_pdf_font=>c_name-times_roman )->get_text_width(
        iv_text = ` W`
        iv_size = 1000 )
      exp = 1194
      tol = '0.001' ).
  ENDMETHOD.

  METHOD case_insensitive.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_font=>get( 'times-bold' )->get_name( )
      exp = zcl_pdf_font=>c_name-times_bold ).
  ENDMETHOD.

  METHOD same_instance.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_font=>get( zcl_pdf_font=>c_name-courier )
      exp = zcl_pdf_font=>get( 'COURIER' ) ).
  ENDMETHOD.

  METHOD unknown_font.
    TRY.
        zcl_pdf_font=>get( 'Comic Sans' ).
        cl_abap_unit_assert=>fail( ).
      CATCH zcx_pdf_error ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.

  METHOD dictionary.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_font=>get( zcl_pdf_font=>c_name-times_italic )->get_dictionary( )
      exp = '<< /Type /Font /Subtype /Type1 /BaseFont /Times-Italic /Encoding /WinAnsiEncoding >>' ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_font=>get( zcl_pdf_font=>c_name-times_italic )->get_resource_name( )
      exp = '/F7' ).
  ENDMETHOD.

  METHOD ascent.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_font=>get( zcl_pdf_font=>c_name-helvetica )->get_ascent( 10 )
      exp = '7.18'
      tol = '0.0001' ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_font=>get( zcl_pdf_font=>c_name-helvetica )->get_descent( 10 )
      exp = '-2.07'
      tol = '0.0001' ).
  ENDMETHOD.

ENDCLASS.
