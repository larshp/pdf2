CLASS ltcl_pdf2 DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS creates_pdf FOR TESTING RAISING zcx_pdf2.
    METHODS rejects_invalid_page FOR TESTING RAISING zcx_pdf2.
ENDCLASS.

CLASS ltcl_pdf2 IMPLEMENTATION.
  METHOD creates_pdf.
    DATA(lo_pdf) = NEW zcl_pdf2( ).
    DATA lv_pdf TYPE xstring.

    lo_pdf->add_text(
      iv_page = 1
      iv_x     = 72
      iv_y     = 700
      iv_text  = 'Hello PDF' ).
    lv_pdf = lo_pdf->to_xstring( ).

    cl_abap_unit_assert=>assert_equals(
      act = lv_pdf+0(8)
      exp = x'255044462D312E34' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( xstrlen( lv_pdf ) > 100 ) ).
  ENDMETHOD.

  METHOD rejects_invalid_page.
    DATA(lo_pdf) = NEW zcl_pdf2( ).

    TRY.
        lo_pdf->add_line(
          iv_page = 2
          iv_x1   = 0
          iv_y1   = 0
          iv_x2   = 10
          iv_y2   = 10 ).
        cl_abap_unit_assert=>fail( ).
      CATCH zcx_pdf2.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
