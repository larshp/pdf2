CLASS zcl_pdf_util DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS class_constructor.

    "! Formats a number for PDF output, at most 3 decimals, no exponent
    CLASS-METHODS number
      IMPORTING
        iv_value       TYPE f
      RETURNING
        VALUE(rv_text) TYPE string.

    "! Converts 7 bit ASCII text to bytes
    CLASS-METHODS ascii
      IMPORTING
        iv_text        TYPE string
      RETURNING
        VALUE(rv_data) TYPE xstring.

    "! Converts text to WinAnsiEncoding, characters which cannot be mapped become '?'
    CLASS-METHODS winansi
      IMPORTING
        iv_text        TYPE string
      RETURNING
        VALUE(rv_data) TYPE xstring.

    "! Bytes as PDF hex string, eg. &lt;48656C6C6F&gt;
    CLASS-METHODS hex
      IMPORTING
        iv_data       TYPE xstring
      RETURNING
        VALUE(rv_pdf) TYPE string.

    "! Unicode text as PDF text string, UTF-16BE with byte order mark
    CLASS-METHODS text_string
      IMPORTING
        iv_text       TYPE string
      RETURNING
        VALUE(rv_pdf) TYPE string.

    "! Converts a hex color, eg. '#FF8000', to PDF color operands, eg. '1 0.502 0'
    CLASS-METHODS color
      IMPORTING
        iv_color      TYPE string
      RETURNING
        VALUE(rv_pdf) TYPE string
      RAISING
        zcx_pdf_error.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_special,
        codepoint TYPE i,
        code      TYPE x LENGTH 1,
      END OF ty_special.
    TYPES ty_specials TYPE HASHED TABLE OF ty_special WITH UNIQUE KEY codepoint.

    " Unicode code point (4 hex digits) followed by its WinAnsiEncoding byte, for the range 0x80 to 0x9F
    CONSTANTS c_specials TYPE string VALUE
      '20AC80201A82019283201E84202685202086202187' &
      '02C68820308901608A20398B01528C017D8E201891' &
      '201992201C93201D9420229520139620149702DC98' &
      '21229901619A203A9B01539C017E9E01789F'.

    CLASS-DATA gt_specials TYPE ty_specials.
    CLASS-DATA go_utf8 TYPE REF TO cl_abap_conv_out_ce.
    CLASS-DATA go_utf16 TYPE REF TO cl_abap_conv_out_ce.

    CLASS-METHODS add_specials
      IMPORTING
        iv_list TYPE string.

    CLASS-METHODS utf16le
      IMPORTING
        iv_text        TYPE string
      RETURNING
        VALUE(rv_data) TYPE xstring.
ENDCLASS.

CLASS zcl_pdf_util IMPLEMENTATION.

  METHOD class_constructor.
    go_utf8 = cl_abap_conv_out_ce=>create( encoding = 'UTF-8' ).
    go_utf16 = cl_abap_conv_out_ce=>create( encoding = '4103' ).
    add_specials( c_specials ).
  ENDMETHOD.

  METHOD add_specials.
    DATA ls_special TYPE ty_special.
    DATA lv_entry TYPE string.
    DATA lv_codepoint TYPE x LENGTH 2.
    DATA lv_offset TYPE i.

    WHILE lv_offset < strlen( iv_list ).
      lv_entry = iv_list+lv_offset(6).
      lv_codepoint = lv_entry(4).
      ls_special-codepoint = lv_codepoint.
      ls_special-code = lv_entry+4(2).
      INSERT ls_special INTO TABLE gt_specials.
      lv_offset = lv_offset + 6.
    ENDWHILE.
  ENDMETHOD.

  METHOD number.
    DATA lv_packed TYPE p LENGTH 16 DECIMALS 3.

    lv_packed = iv_value.
    rv_text = |{ lv_packed }|.
    REPLACE REGEX '\.?0+$' IN rv_text WITH ''.
    IF rv_text = '-0'.
      rv_text = '0'.
    ENDIF.
  ENDMETHOD.

  METHOD ascii.
    go_utf8->convert(
      EXPORTING
        data   = iv_text
      IMPORTING
        buffer = rv_data ).
  ENDMETHOD.

  METHOD utf16le.
    go_utf16->convert(
      EXPORTING
        data   = iv_text
      IMPORTING
        buffer = rv_data ).
  ENDMETHOD.

  METHOD winansi.
    DATA lv_utf16 TYPE xstring.
    DATA lv_offset TYPE i.
    DATA lv_length TYPE i.
    DATA lv_low TYPE x LENGTH 1.
    DATA lv_high TYPE x LENGTH 1.
    DATA lv_codepoint TYPE i.
    DATA lv_code TYPE x LENGTH 1.
    DATA ls_special LIKE LINE OF gt_specials.

    lv_utf16 = utf16le( iv_text ).
    lv_length = xstrlen( lv_utf16 ).

    WHILE lv_offset < lv_length.
      lv_low = lv_utf16+lv_offset(1).
      lv_offset = lv_offset + 1.
      lv_high = lv_utf16+lv_offset(1).
      lv_offset = lv_offset + 1.
      lv_codepoint = lv_high.
      lv_codepoint = lv_codepoint * 256.
      lv_codepoint = lv_codepoint + lv_low.

      IF ( lv_codepoint >= 32 AND lv_codepoint <= 126 ) OR ( lv_codepoint >= 160 AND lv_codepoint <= 255 ).
        lv_code = lv_codepoint.
      ELSEIF lv_codepoint = 9.
        lv_code = '20'.
      ELSEIF lv_codepoint < 32.
        CONTINUE.
      ELSE.
        READ TABLE gt_specials INTO ls_special WITH TABLE KEY codepoint = lv_codepoint.
        IF sy-subrc = 0.
          lv_code = ls_special-code.
        ELSE.
          lv_code = '3F'.
        ENDIF.
        IF lv_codepoint >= 55296 AND lv_codepoint <= 56319.
* high surrogate, skip the low surrogate
          lv_offset = lv_offset + 2.
        ENDIF.
      ENDIF.

      CONCATENATE rv_data lv_code INTO rv_data IN BYTE MODE.
    ENDWHILE.
  ENDMETHOD.

  METHOD hex.
    DATA lv_hex TYPE string.
    lv_hex = iv_data.
    rv_pdf = |<{ lv_hex }>|.
  ENDMETHOD.

  METHOD text_string.
    DATA lv_utf16 TYPE xstring.
    DATA lv_swapped TYPE xstring.
    DATA lv_offset TYPE i.
    DATA lv_low TYPE x LENGTH 1.
    DATA lv_high TYPE x LENGTH 1.

    lv_utf16 = utf16le( iv_text ).
    lv_swapped = 'FEFF'.
    WHILE lv_offset < xstrlen( lv_utf16 ).
      lv_low = lv_utf16+lv_offset(1).
      lv_offset = lv_offset + 1.
      lv_high = lv_utf16+lv_offset(1).
      lv_offset = lv_offset + 1.
      CONCATENATE lv_swapped lv_high lv_low INTO lv_swapped IN BYTE MODE.
    ENDWHILE.
    rv_pdf = hex( lv_swapped ).
  ENDMETHOD.

  METHOD color.
    DATA lv_color TYPE string.
    DATA lv_byte TYPE x LENGTH 1.
    DATA lv_value TYPE f.
    DATA lv_offset TYPE i.

    lv_color = to_upper( iv_color ).
    IF strlen( lv_color ) = 7 AND lv_color(1) = '#'.
      lv_color = lv_color+1.
    ENDIF.
    IF strlen( lv_color ) <> 6 OR lv_color CN '0123456789ABCDEF'.
      zcx_pdf_error=>raise( |Invalid color "{ iv_color }", expected format #RRGGBB| ).
    ENDIF.

    DO 3 TIMES.
      lv_byte = lv_color+lv_offset(2).
      lv_value = lv_byte.
      lv_value = lv_value / 255.
      IF rv_pdf IS INITIAL.
        rv_pdf = number( lv_value ).
      ELSE.
        rv_pdf = rv_pdf && ` ` && number( lv_value ).
      ENDIF.
      lv_offset = lv_offset + 2.
    ENDDO.
  ENDMETHOD.

ENDCLASS.
