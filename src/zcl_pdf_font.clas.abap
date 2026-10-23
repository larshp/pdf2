"! Standard PDF fonts, these are built into every PDF viewer and not embedded in the document
"! <p>The glyph widths are taken from the Adobe Core14 AFM files,
"! Copyright (c) 1985, 1987, 1989, 1990, 1993, 1997 Adobe Systems Incorporated. All Rights Reserved.</p>
CLASS zcl_pdf_font DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        iv_name  TYPE string
        iv_index TYPE i.

    "! The standard PDF fonts, Symbol and ZapfDingbats are not supported
    CONSTANTS:
      BEGIN OF c_name,
        helvetica              TYPE string VALUE 'Helvetica',
        helvetica_bold         TYPE string VALUE 'Helvetica-Bold',
        helvetica_oblique      TYPE string VALUE 'Helvetica-Oblique',
        helvetica_bold_oblique TYPE string VALUE 'Helvetica-BoldOblique',
        times_roman            TYPE string VALUE 'Times-Roman',
        times_bold             TYPE string VALUE 'Times-Bold',
        times_italic           TYPE string VALUE 'Times-Italic',
        times_bold_italic      TYPE string VALUE 'Times-BoldItalic',
        courier                TYPE string VALUE 'Courier',
        courier_bold           TYPE string VALUE 'Courier-Bold',
        courier_oblique        TYPE string VALUE 'Courier-Oblique',
        courier_bold_oblique   TYPE string VALUE 'Courier-BoldOblique',
      END OF c_name.

    "! Returns a font by name, eg. zcl_pdf_font=&gt;c_name-helvetica_bold, case insensitive
    CLASS-METHODS get
      IMPORTING
        iv_name        TYPE string
      RETURNING
        VALUE(ro_font) TYPE REF TO zcl_pdf_font
      RAISING
        zcx_pdf_error.

    METHODS get_name
      RETURNING
        VALUE(rv_name) TYPE string.

    "! Resource name used in content streams, eg. /F1
    METHODS get_resource_name
      RETURNING
        VALUE(rv_name) TYPE string.

    "! Font dictionary for the PDF output
    METHODS get_dictionary
      RETURNING
        VALUE(rv_dictionary) TYPE string.

    "! Width of the text in points when set in the given font size
    METHODS get_text_width
      IMPORTING
        iv_text         TYPE string
        iv_size         TYPE f
      RETURNING
        VALUE(rv_width) TYPE f.

    "! Width of WinAnsiEncoding bytes in points when set in the given font size
    METHODS get_bytes_width
      IMPORTING
        iv_bytes        TYPE xstring
        iv_size         TYPE f
      RETURNING
        VALUE(rv_width) TYPE f.

    "! Distance from the baseline to the top of the font in points
    METHODS get_ascent
      IMPORTING
        iv_size          TYPE f
      RETURNING
        VALUE(rv_ascent) TYPE f.

    "! Distance from the baseline to the bottom of the font in points, negative
    METHODS get_descent
      IMPORTING
        iv_size           TYPE f
      RETURNING
        VALUE(rv_descent) TYPE f.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_font,
        name TYPE string,
        font TYPE REF TO zcl_pdf_font,
      END OF ty_font.
    TYPES ty_fonts TYPE STANDARD TABLE OF ty_font WITH DEFAULT KEY.
    TYPES ty_widths TYPE STANDARD TABLE OF i WITH DEFAULT KEY.

    CLASS-DATA gt_fonts TYPE ty_fonts.

    DATA mv_name TYPE string.
    DATA mv_index TYPE i.
    DATA mv_ascender TYPE i.
    DATA mv_descender TYPE i.
    DATA mv_fixed_width TYPE i.
    "! Glyph widths in 1/1000 em for the WinAnsiEncoding codes 32 to 255
    DATA mt_widths TYPE ty_widths.

    METHODS add_widths
      IMPORTING
        iv_widths TYPE string.

    METHODS load_helvetica.
    METHODS load_helvetica_bold.
    METHODS load_times_roman.
    METHODS load_times_bold.
    METHODS load_times_italic.
    METHODS load_times_bold_italic.
ENDCLASS.

CLASS zcl_pdf_font IMPLEMENTATION.

  METHOD get.
    DATA lt_names TYPE string_table.
    DATA lv_name LIKE LINE OF lt_names.
    DATA ls_font LIKE LINE OF gt_fonts.

    LOOP AT gt_fonts INTO ls_font.
      IF to_upper( ls_font-name ) = to_upper( iv_name ).
        ro_font = ls_font-font.
        RETURN.
      ENDIF.
    ENDLOOP.

    APPEND c_name-helvetica TO lt_names.
    APPEND c_name-helvetica_bold TO lt_names.
    APPEND c_name-helvetica_oblique TO lt_names.
    APPEND c_name-helvetica_bold_oblique TO lt_names.
    APPEND c_name-times_roman TO lt_names.
    APPEND c_name-times_bold TO lt_names.
    APPEND c_name-times_italic TO lt_names.
    APPEND c_name-times_bold_italic TO lt_names.
    APPEND c_name-courier TO lt_names.
    APPEND c_name-courier_bold TO lt_names.
    APPEND c_name-courier_oblique TO lt_names.
    APPEND c_name-courier_bold_oblique TO lt_names.

    LOOP AT lt_names INTO lv_name.
      IF to_upper( lv_name ) = to_upper( iv_name ).
        CREATE OBJECT ro_font
          EXPORTING
            iv_name  = lv_name
            iv_index = sy-tabix.
        ls_font-name = lv_name.
        ls_font-font = ro_font.
        APPEND ls_font TO gt_fonts.
        RETURN.
      ENDIF.
    ENDLOOP.

    zcx_pdf_error=>raise( |Unknown font "{ iv_name }"| ).
  ENDMETHOD.

  METHOD constructor.
    mv_name = iv_name.
    mv_index = iv_index.

    IF mv_name CP 'Helvetica*'.
      mv_ascender = 718.
      mv_descender = -207.
    ELSEIF mv_name CP 'Times*'.
      mv_ascender = 683.
      mv_descender = -217.
    ELSE.
      mv_ascender = 629.
      mv_descender = -157.
    ENDIF.

    CASE mv_name.
      WHEN c_name-helvetica.
        load_helvetica( ).
      WHEN c_name-helvetica_bold.
        load_helvetica_bold( ).
      WHEN c_name-helvetica_oblique.
        load_helvetica( ).
      WHEN c_name-helvetica_bold_oblique.
        load_helvetica_bold( ).
      WHEN c_name-times_roman.
        load_times_roman( ).
      WHEN c_name-times_bold.
        load_times_bold( ).
      WHEN c_name-times_italic.
        load_times_italic( ).
      WHEN c_name-times_bold_italic.
        load_times_bold_italic( ).
      WHEN c_name-courier.
        mv_fixed_width = 600.
      WHEN c_name-courier_bold.
        mv_fixed_width = 600.
      WHEN c_name-courier_oblique.
        mv_fixed_width = 600.
      WHEN c_name-courier_bold_oblique.
        mv_fixed_width = 600.
    ENDCASE.
  ENDMETHOD.

  METHOD get_name.
    rv_name = mv_name.
  ENDMETHOD.

  METHOD get_resource_name.
    rv_name = |/F{ mv_index }|.
  ENDMETHOD.

  METHOD get_dictionary.
    rv_dictionary = |<< /Type /Font /Subtype /Type1 /BaseFont /{ mv_name } /Encoding /WinAnsiEncoding >>|.
  ENDMETHOD.

  METHOD get_text_width.
    rv_width = get_bytes_width(
      iv_bytes = zcl_pdf_util=>winansi( iv_text )
      iv_size  = iv_size ).
  ENDMETHOD.

  METHOD get_bytes_width.
    DATA lv_offset TYPE i.
    DATA lv_byte TYPE x LENGTH 1.
    DATA lv_index TYPE i.
    DATA lv_width TYPE i.
    DATA lv_total TYPE i.

    IF mv_fixed_width > 0.
      lv_total = xstrlen( iv_bytes ) * mv_fixed_width.
    ELSE.
      WHILE lv_offset < xstrlen( iv_bytes ).
        lv_byte = iv_bytes+lv_offset(1).
        lv_index = lv_byte.
        lv_index = lv_index - 31.
        READ TABLE mt_widths INDEX lv_index INTO lv_width.
        IF sy-subrc = 0.
          lv_total = lv_total + lv_width.
        ENDIF.
        lv_offset = lv_offset + 1.
      ENDWHILE.
    ENDIF.

    rv_width = lv_total.
    rv_width = rv_width * iv_size / 1000.
  ENDMETHOD.

  METHOD get_ascent.
    rv_ascent = mv_ascender.
    rv_ascent = rv_ascent * iv_size / 1000.
  ENDMETHOD.

  METHOD get_descent.
    rv_descent = mv_descender.
    rv_descent = rv_descent * iv_size / 1000.
  ENDMETHOD.

  METHOD add_widths.
    DATA lt_widths TYPE string_table.
    DATA lv_width LIKE LINE OF lt_widths.
    DATA lv_int TYPE i.

    SPLIT iv_widths AT space INTO TABLE lt_widths.
    LOOP AT lt_widths INTO lv_width.
      lv_int = lv_width.
      APPEND lv_int TO mt_widths.
    ENDLOOP.
  ENDMETHOD.

  METHOD load_helvetica.
    add_widths( '278 278 355 556 556 889 667 191 333 333 389 584 278 333 278 278' ).
    add_widths( '556 556 556 556 556 556 556 556 556 556 278 278 584 584 584 556' ).
    add_widths( '1015 667 667 722 722 667 611 778 722 278 500 667 556 833 722 778' ).
    add_widths( '667 778 722 667 611 722 667 944 667 667 611 278 278 278 469 556' ).
    add_widths( '333 556 556 500 556 556 278 556 556 222 222 500 222 833 556 556' ).
    add_widths( '556 556 333 500 278 556 500 722 500 500 500 334 260 334 584 0' ).
    add_widths( '556 0 222 556 333 1000 556 556 333 1000 667 333 1000 0 611 0' ).
    add_widths( '0 222 222 333 333 350 556 1000 333 1000 500 333 944 0 500 667' ).
    add_widths( '278 333 556 556 556 556 260 556 333 737 370 556 584 333 737 333' ).
    add_widths( '400 584 333 333 333 556 537 278 333 333 365 556 834 834 834 611' ).
    add_widths( '667 667 667 667 667 667 1000 722 667 667 667 667 278 278 278 278' ).
    add_widths( '722 722 778 778 778 778 778 584 778 722 722 722 722 667 667 611' ).
    add_widths( '556 556 556 556 556 556 889 500 556 556 556 556 278 278 278 278' ).
    add_widths( '556 556 556 556 556 556 556 584 611 556 556 556 556 500 556 500' ).
  ENDMETHOD.

  METHOD load_helvetica_bold.
    add_widths( '278 333 474 556 556 889 722 238 333 333 389 584 278 333 278 278' ).
    add_widths( '556 556 556 556 556 556 556 556 556 556 333 333 584 584 584 611' ).
    add_widths( '975 722 722 722 722 667 611 778 722 278 556 722 611 833 722 778' ).
    add_widths( '667 778 722 667 611 722 667 944 667 667 611 333 278 333 584 556' ).
    add_widths( '333 556 611 556 611 556 333 611 611 278 278 556 278 889 611 611' ).
    add_widths( '611 611 389 556 333 611 556 778 556 556 500 389 280 389 584 0' ).
    add_widths( '556 0 278 556 500 1000 556 556 333 1000 667 333 1000 0 611 0' ).
    add_widths( '0 278 278 500 500 350 556 1000 333 1000 556 333 944 0 500 667' ).
    add_widths( '278 333 556 556 556 556 280 556 333 737 370 556 584 333 737 333' ).
    add_widths( '400 584 333 333 333 611 556 278 333 333 365 556 834 834 834 611' ).
    add_widths( '722 722 722 722 722 722 1000 722 667 667 667 667 278 278 278 278' ).
    add_widths( '722 722 778 778 778 778 778 584 778 722 722 722 722 667 667 611' ).
    add_widths( '556 556 556 556 556 556 889 556 556 556 556 556 278 278 278 278' ).
    add_widths( '611 611 611 611 611 611 611 584 611 611 611 611 611 556 611 556' ).
  ENDMETHOD.

  METHOD load_times_roman.
    add_widths( '250 333 408 500 500 833 778 180 333 333 500 564 250 333 250 278' ).
    add_widths( '500 500 500 500 500 500 500 500 500 500 278 278 564 564 564 444' ).
    add_widths( '921 722 667 667 722 611 556 722 722 333 389 722 611 889 722 722' ).
    add_widths( '556 722 667 556 611 722 722 944 722 722 611 333 278 333 469 500' ).
    add_widths( '333 444 500 444 500 444 333 500 500 278 278 500 278 778 500 500' ).
    add_widths( '500 500 333 389 278 500 500 722 500 500 444 480 200 480 541 0' ).
    add_widths( '500 0 333 500 444 1000 500 500 333 1000 556 333 889 0 611 0' ).
    add_widths( '0 333 333 444 444 350 500 1000 333 980 389 333 722 0 444 722' ).
    add_widths( '250 333 500 500 500 500 200 500 333 760 276 500 564 333 760 333' ).
    add_widths( '400 564 300 300 333 500 453 250 333 300 310 500 750 750 750 444' ).
    add_widths( '722 722 722 722 722 722 889 667 611 611 611 611 333 333 333 333' ).
    add_widths( '722 722 722 722 722 722 722 564 722 722 722 722 722 722 556 500' ).
    add_widths( '444 444 444 444 444 444 667 444 444 444 444 444 278 278 278 278' ).
    add_widths( '500 500 500 500 500 500 500 564 500 500 500 500 500 500 500 500' ).
  ENDMETHOD.

  METHOD load_times_bold.
    add_widths( '250 333 555 500 500 1000 833 278 333 333 500 570 250 333 250 278' ).
    add_widths( '500 500 500 500 500 500 500 500 500 500 333 333 570 570 570 500' ).
    add_widths( '930 722 667 722 722 667 611 778 778 389 500 778 667 944 722 778' ).
    add_widths( '611 778 722 556 667 722 722 1000 722 722 667 333 278 333 581 500' ).
    add_widths( '333 500 556 444 556 444 333 500 556 278 333 556 278 833 556 500' ).
    add_widths( '556 556 444 389 333 556 500 722 500 500 444 394 220 394 520 0' ).
    add_widths( '500 0 333 500 500 1000 500 500 333 1000 556 333 1000 0 667 0' ).
    add_widths( '0 333 333 500 500 350 500 1000 333 1000 389 333 722 0 444 722' ).
    add_widths( '250 333 500 500 500 500 220 500 333 747 300 500 570 333 747 333' ).
    add_widths( '400 570 300 300 333 556 540 250 333 300 330 500 750 750 750 500' ).
    add_widths( '722 722 722 722 722 722 1000 722 667 667 667 667 389 389 389 389' ).
    add_widths( '722 722 778 778 778 778 778 570 778 722 722 722 722 722 611 556' ).
    add_widths( '500 500 500 500 500 500 722 444 444 444 444 444 278 278 278 278' ).
    add_widths( '500 556 500 500 500 500 500 570 500 556 556 556 556 500 556 500' ).
  ENDMETHOD.

  METHOD load_times_italic.
    add_widths( '250 333 420 500 500 833 778 214 333 333 500 675 250 333 250 278' ).
    add_widths( '500 500 500 500 500 500 500 500 500 500 333 333 675 675 675 500' ).
    add_widths( '920 611 611 667 722 611 611 722 722 333 444 667 556 833 667 722' ).
    add_widths( '611 722 611 500 556 722 611 833 611 556 556 389 278 389 422 500' ).
    add_widths( '333 500 500 444 500 444 278 500 500 278 278 444 278 722 500 500' ).
    add_widths( '500 500 389 389 278 500 444 667 444 444 389 400 275 400 541 0' ).
    add_widths( '500 0 333 500 556 889 500 500 333 1000 500 333 944 0 556 0' ).
    add_widths( '0 333 333 556 556 350 500 889 333 980 389 333 667 0 389 556' ).
    add_widths( '250 389 500 500 500 500 275 500 333 760 276 500 675 333 760 333' ).
    add_widths( '400 675 300 300 333 500 523 250 333 300 310 500 750 750 750 500' ).
    add_widths( '611 611 611 611 611 611 889 667 611 611 611 611 333 333 333 333' ).
    add_widths( '722 667 722 722 722 722 722 675 722 722 722 722 722 556 611 500' ).
    add_widths( '500 500 500 500 500 500 667 444 444 444 444 444 278 278 278 278' ).
    add_widths( '500 500 500 500 500 500 500 675 500 500 500 500 500 444 500 444' ).
  ENDMETHOD.

  METHOD load_times_bold_italic.
    add_widths( '250 389 555 500 500 833 778 278 333 333 500 570 250 333 250 278' ).
    add_widths( '500 500 500 500 500 500 500 500 500 500 333 333 570 570 570 500' ).
    add_widths( '832 667 667 667 722 667 667 722 778 389 500 667 611 889 722 722' ).
    add_widths( '611 722 667 556 611 722 667 889 667 611 611 333 278 333 570 500' ).
    add_widths( '333 500 500 444 500 444 333 500 556 278 278 500 278 778 556 500' ).
    add_widths( '500 500 389 389 278 556 444 667 500 444 389 348 220 348 570 0' ).
    add_widths( '500 0 333 500 500 1000 500 500 333 1000 556 333 944 0 611 0' ).
    add_widths( '0 333 333 500 500 350 500 1000 333 1000 389 333 722 0 389 611' ).
    add_widths( '250 389 500 500 500 500 220 500 333 747 266 500 606 333 747 333' ).
    add_widths( '400 570 300 300 333 576 500 250 333 300 300 500 750 750 750 500' ).
    add_widths( '667 667 667 667 667 667 944 667 667 667 667 667 389 389 389 389' ).
    add_widths( '722 722 722 722 722 722 722 570 722 722 722 722 722 611 611 500' ).
    add_widths( '500 500 500 500 500 500 722 444 444 444 444 444 278 278 278 278' ).
    add_widths( '500 556 500 500 500 500 500 570 500 556 556 556 556 444 500 444' ).
  ENDMETHOD.

ENDCLASS.
