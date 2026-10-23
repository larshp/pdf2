CLASS ltcl_image DEFINITION FOR TESTING RISK LEVEL HARMLESS DURATION SHORT FINAL.

  PRIVATE SECTION.
    METHODS jpeg FOR TESTING RAISING zcx_pdf_error.
    METHODS jpeg_grayscale FOR TESTING RAISING zcx_pdf_error.
    METHODS jpeg_truncated FOR TESTING.
    METHODS png_rgb FOR TESTING RAISING zcx_pdf_error.
    METHODS png_palette FOR TESTING RAISING zcx_pdf_error.
    METHODS png_alpha FOR TESTING.
    METHODS unknown_format FOR TESTING.
    METHODS resource_names FOR TESTING RAISING zcx_pdf_error.

    METHODS build_jpeg
      IMPORTING
        iv_components  TYPE xstring
      RETURNING
        VALUE(rv_data) TYPE xstring.

    METHODS build_png
      IMPORTING
        iv_color_type  TYPE xstring
        iv_extra       TYPE xstring OPTIONAL
      RETURNING
        VALUE(rv_data) TYPE xstring.

    METHODS assert_contains
      IMPORTING
        iv_text TYPE string
        iv_sub  TYPE string.
ENDCLASS.

CLASS ltcl_image IMPLEMENTATION.

  METHOD build_jpeg.
    DATA lv_part TYPE xstring.
* SOI, APP0 JFIF
    rv_data = 'FFD8FFE000104A46494600010100000100010000'.
* SOF0, 8 bits, height 32, width 64
    lv_part = 'FFC000110800200040'.
    CONCATENATE rv_data lv_part iv_components INTO rv_data IN BYTE MODE.
    lv_part = '012200021101031101FFD9'.
    CONCATENATE rv_data lv_part INTO rv_data IN BYTE MODE.
  ENDMETHOD.

  METHOD build_png.
    DATA lv_part TYPE xstring.
* signature, IHDR width 2 height 1, 8 bits
    rv_data = '89504E470D0A1A0A0000000D49484452000000020000000108'.
    lv_part = '00000000000000'.
    CONCATENATE rv_data iv_color_type lv_part iv_extra INTO rv_data IN BYTE MODE.
* IDAT, IEND
    lv_part = '0000000349444154010203000000000000000049454E4400000000'.
    CONCATENATE rv_data lv_part INTO rv_data IN BYTE MODE.
  ENDMETHOD.

  METHOD assert_contains.
    IF iv_text NS iv_sub.
      cl_abap_unit_assert=>fail( |"{ iv_sub }" not found in "{ iv_text }"| ).
    ENDIF.
  ENDMETHOD.

  METHOD jpeg.
    DATA lo_image TYPE REF TO zcl_pdf_image.
    DATA lv_data TYPE xstring.

    lv_data = build_jpeg( '03' ).
    lo_image = zcl_pdf_image=>load( lv_data ).

    cl_abap_unit_assert=>assert_equals(
      act = lo_image->get_width( )
      exp = 64 ).
    cl_abap_unit_assert=>assert_equals(
      act = lo_image->get_height( )
      exp = 32 ).
    cl_abap_unit_assert=>assert_equals(
      act = lo_image->get_data( )
      exp = lv_data ).
    assert_contains(
      iv_text = lo_image->get_dictionary( )
      iv_sub  = |/Width 64 /Height 32 /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode /Length {
        xstrlen( lv_data ) } >>| ).
  ENDMETHOD.

  METHOD jpeg_grayscale.
    DATA lo_image TYPE REF TO zcl_pdf_image.

    lo_image = zcl_pdf_image=>from_jpeg( build_jpeg( '01' ) ).
    assert_contains(
      iv_text = lo_image->get_dictionary( )
      iv_sub  = '/ColorSpace /DeviceGray' ).
  ENDMETHOD.

  METHOD jpeg_truncated.
    TRY.
        zcl_pdf_image=>from_jpeg( 'FFD8FFE00010' ).
        cl_abap_unit_assert=>fail( ).
      CATCH zcx_pdf_error ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.

  METHOD png_rgb.
    DATA lo_image TYPE REF TO zcl_pdf_image.
    DATA lv_expected TYPE xstring.

    lo_image = zcl_pdf_image=>load( build_png( '02' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = lo_image->get_width( )
      exp = 2 ).
    cl_abap_unit_assert=>assert_equals(
      act = lo_image->get_height( )
      exp = 1 ).
    lv_expected = '010203'.
    cl_abap_unit_assert=>assert_equals(
      act = lo_image->get_data( )
      exp = lv_expected ).
    assert_contains(
      iv_text = lo_image->get_dictionary( )
      iv_sub  = '/ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /FlateDecode' &&
                ' /DecodeParms << /Predictor 15 /Colors 3 /BitsPerComponent 8 /Columns 2 >> /Length 3 >>' ).
  ENDMETHOD.

  METHOD png_palette.
    DATA lo_image TYPE REF TO zcl_pdf_image.

* PLTE chunk with two colors
    lo_image = zcl_pdf_image=>from_png( build_png(
      iv_color_type = '03'
      iv_extra      = '00000006504C5445FF000000FF0000000000' ) ).
    assert_contains(
      iv_text = lo_image->get_dictionary( )
      iv_sub  = '/ColorSpace [/Indexed /DeviceRGB 1 <FF000000FF00>]' ).
  ENDMETHOD.

  METHOD png_alpha.
    TRY.
        zcl_pdf_image=>from_png( build_png( '06' ) ).
        cl_abap_unit_assert=>fail( ).
      CATCH zcx_pdf_error ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.

  METHOD unknown_format.
    TRY.
        zcl_pdf_image=>load( '474946383961' ).
        cl_abap_unit_assert=>fail( ).
      CATCH zcx_pdf_error ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.

  METHOD resource_names.
    DATA lo_first TYPE REF TO zcl_pdf_image.
    DATA lo_second TYPE REF TO zcl_pdf_image.

    lo_first = zcl_pdf_image=>load( build_png( '00' ) ).
    lo_second = zcl_pdf_image=>load( build_png( '00' ) ).
    cl_abap_unit_assert=>assert_differs(
      act = lo_first->get_resource_name( )
      exp = lo_second->get_resource_name( ) ).
    assert_contains(
      iv_text = lo_first->get_resource_name( )
      iv_sub  = '/Im' ).
  ENDMETHOD.

ENDCLASS.
