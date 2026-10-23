CLASS ltcl_util DEFINITION FOR TESTING RISK LEVEL HARMLESS DURATION SHORT FINAL.

  PRIVATE SECTION.
    METHODS number FOR TESTING.
    METHODS number_rounding FOR TESTING.
    METHODS winansi_ascii FOR TESTING.
    METHODS winansi_latin1 FOR TESTING.
    METHODS winansi_special FOR TESTING.
    METHODS winansi_unmapped FOR TESTING.
    METHODS winansi_control FOR TESTING.
    METHODS text_string FOR TESTING.
    METHODS color FOR TESTING RAISING zcx_pdf_error.
    METHODS color_invalid FOR TESTING.
ENDCLASS.

CLASS ltcl_util IMPLEMENTATION.

  METHOD number.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_util=>number( '12.5' )
      exp = '12.5' ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_util=>number( 100 )
      exp = '100' ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_util=>number( 0 )
      exp = '0' ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_util=>number( -20 )
      exp = '-20' ).
  ENDMETHOD.

  METHOD number_rounding.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_util=>number( '-3.14159' )
      exp = '-3.142' ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_util=>number( '0.0001' )
      exp = '0' ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_util=>number( '-0.0001' )
      exp = '0' ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_util=>number( '841.89' )
      exp = '841.89' ).
  ENDMETHOD.

  METHOD winansi_ascii.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_util=>winansi( `Hello (World)` )
      exp = '48656C6C6F2028576F726C6429' ).
  ENDMETHOD.

  METHOD winansi_latin1.
    DATA lv_text TYPE string.
    lv_text = cl_abap_conv_in_ce=>uccp( '00E6' ) && cl_abap_conv_in_ce=>uccp( '00F8' ) && cl_abap_conv_in_ce=>uccp( '00E5' ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_util=>winansi( lv_text )
      exp = 'E6F8E5' ).
  ENDMETHOD.

  METHOD winansi_special.
    DATA lv_text TYPE string.
    lv_text = cl_abap_conv_in_ce=>uccp( '20AC' ) && cl_abap_conv_in_ce=>uccp( '2014' ) && cl_abap_conv_in_ce=>uccp( '0178' ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_util=>winansi( lv_text )
      exp = '80979F' ).
  ENDMETHOD.

  METHOD winansi_unmapped.
    DATA lv_text TYPE string.
    lv_text = `a` && cl_abap_conv_in_ce=>uccp( '4E2D' ) && `b`.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_util=>winansi( lv_text )
      exp = '613F62' ).
  ENDMETHOD.

  METHOD winansi_control.
    DATA lv_text TYPE string.
    lv_text = `a` && cl_abap_char_utilities=>horizontal_tab && `b` && cl_abap_char_utilities=>newline.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_util=>winansi( lv_text )
      exp = '612062' ).
  ENDMETHOD.

  METHOD text_string.
    DATA lv_text TYPE string.
    lv_text = `Ab` && cl_abap_conv_in_ce=>uccp( '20AC' ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_util=>text_string( lv_text )
      exp = '<FEFF0041006220AC>' ).
  ENDMETHOD.

  METHOD color.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_util=>color( '#FF8000' )
      exp = '1 0.502 0' ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_pdf_util=>color( '0000ff' )
      exp = '0 0 1' ).
  ENDMETHOD.

  METHOD color_invalid.
    TRY.
        zcl_pdf_util=>color( 'red' ).
        cl_abap_unit_assert=>fail( ).
      CATCH zcx_pdf_error ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
