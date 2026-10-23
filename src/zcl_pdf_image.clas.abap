CLASS zcl_pdf_image DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        iv_width   TYPE i
        iv_height  TYPE i
        iv_entries TYPE string
        iv_data    TYPE xstring.

    "! Loads a JPEG or PNG image, the format is detected from the data
    CLASS-METHODS load
      IMPORTING
        iv_data         TYPE xstring
      RETURNING
        VALUE(ro_image) TYPE REF TO zcl_pdf_image
      RAISING
        zcx_pdf_error.

    "! Loads a baseline or progressive JPEG image, grayscale, RGB or CMYK
    CLASS-METHODS from_jpeg
      IMPORTING
        iv_data         TYPE xstring
      RETURNING
        VALUE(ro_image) TYPE REF TO zcl_pdf_image
      RAISING
        zcx_pdf_error.

    "! Loads a non-interlaced PNG image, grayscale, RGB or palette, without alpha channel
    CLASS-METHODS from_png
      IMPORTING
        iv_data         TYPE xstring
      RETURNING
        VALUE(ro_image) TYPE REF TO zcl_pdf_image
      RAISING
        zcx_pdf_error.

    "! Width in pixels
    METHODS get_width
      RETURNING
        VALUE(rv_width) TYPE i.

    "! Height in pixels
    METHODS get_height
      RETURNING
        VALUE(rv_height) TYPE i.

    "! Resource name used in content streams, eg. /Im1
    METHODS get_resource_name
      RETURNING
        VALUE(rv_name) TYPE string.

    "! Image XObject dictionary for the PDF output
    METHODS get_dictionary
      RETURNING
        VALUE(rv_dictionary) TYPE string.

    "! Image XObject stream data for the PDF output
    METHODS get_data
      RETURNING
        VALUE(rv_data) TYPE xstring.

  PRIVATE SECTION.
    CLASS-DATA gv_counter TYPE i.

    DATA mv_id TYPE i.
    DATA mv_width TYPE i.
    DATA mv_height TYPE i.
    DATA mv_entries TYPE string.
    DATA mv_data TYPE xstring.

    CLASS-METHODS read_uint
      IMPORTING
        iv_data         TYPE xstring
        iv_offset       TYPE i
        iv_length       TYPE i
      RETURNING
        VALUE(rv_value) TYPE i
      RAISING
        zcx_pdf_error.
ENDCLASS.

CLASS zcl_pdf_image IMPLEMENTATION.

  METHOD constructor.
    gv_counter = gv_counter + 1.
    mv_id = gv_counter.
    mv_width = iv_width.
    mv_height = iv_height.
    mv_entries = iv_entries.
    mv_data = iv_data.
  ENDMETHOD.

  METHOD load.
    IF xstrlen( iv_data ) >= 2 AND iv_data(2) = 'FFD8'.
      ro_image = from_jpeg( iv_data ).
    ELSEIF xstrlen( iv_data ) >= 8 AND iv_data(8) = '89504E470D0A1A0A'.
      ro_image = from_png( iv_data ).
    ELSE.
      zcx_pdf_error=>raise( 'Unsupported image format, expected JPEG or PNG' ).
    ENDIF.
  ENDMETHOD.

  METHOD from_jpeg.
    DATA lv_length TYPE i.
    DATA lv_offset TYPE i.
    DATA lv_marker TYPE i.
    DATA lv_segment TYPE i.
    DATA lv_bits TYPE i.
    DATA lv_height TYPE i.
    DATA lv_width TYPE i.
    DATA lv_components TYPE i.
    DATA lv_colorspace TYPE string.

    lv_length = xstrlen( iv_data ).
    IF lv_length < 4 OR iv_data(2) <> 'FFD8'.
      zcx_pdf_error=>raise( 'Not a JPEG image' ).
    ENDIF.

    lv_offset = 2.
    WHILE lv_offset + 4 <= lv_length.
      IF read_uint( iv_data   = iv_data
                    iv_offset = lv_offset
                    iv_length = 1 ) <> 255.
        zcx_pdf_error=>raise( 'Invalid JPEG marker' ).
      ENDIF.
      lv_marker = read_uint( iv_data   = iv_data
                             iv_offset = lv_offset + 1
                             iv_length = 1 ).

      IF lv_marker = 255.
* fill byte
        lv_offset = lv_offset + 1.
        CONTINUE.
      ELSEIF lv_marker = 1 OR ( lv_marker >= 208 AND lv_marker <= 217 ).
* markers without payload
        lv_offset = lv_offset + 2.
        CONTINUE.
      ENDIF.

      lv_segment = read_uint( iv_data   = iv_data
                              iv_offset = lv_offset + 2
                              iv_length = 2 ).

      IF lv_marker >= 192 AND lv_marker <= 207 AND lv_marker <> 196 AND lv_marker <> 200 AND lv_marker <> 204.
* start of frame
        lv_bits = read_uint( iv_data   = iv_data
                             iv_offset = lv_offset + 4
                             iv_length = 1 ).
        lv_height = read_uint( iv_data   = iv_data
                               iv_offset = lv_offset + 5
                               iv_length = 2 ).
        lv_width = read_uint( iv_data   = iv_data
                              iv_offset = lv_offset + 7
                              iv_length = 2 ).
        lv_components = read_uint( iv_data   = iv_data
                                   iv_offset = lv_offset + 9
                                   iv_length = 1 ).
        CASE lv_components.
          WHEN 1.
            lv_colorspace = '/DeviceGray'.
          WHEN 3.
            lv_colorspace = '/DeviceRGB'.
          WHEN 4.
* Adobe applications write inverted CMYK JPEGs
            lv_colorspace = '/DeviceCMYK /Decode [1 0 1 0 1 0 1 0]'.
          WHEN OTHERS.
            zcx_pdf_error=>raise( |Unsupported number of JPEG color components: { lv_components }| ).
        ENDCASE.

        CREATE OBJECT ro_image
          EXPORTING
            iv_width   = lv_width
            iv_height  = lv_height
            iv_entries = |/ColorSpace { lv_colorspace } /BitsPerComponent { lv_bits } /Filter /DCTDecode|
            iv_data    = iv_data.
        RETURN.
      ENDIF.

      lv_offset = lv_offset + 2 + lv_segment.
    ENDWHILE.

    zcx_pdf_error=>raise( 'JPEG frame header not found' ).
  ENDMETHOD.

  METHOD from_png.
    DATA lv_length TYPE i.
    DATA lv_offset TYPE i.
    DATA lv_chunk_length TYPE i.
    DATA lv_chunk_type TYPE x LENGTH 4.
    DATA lv_data_offset TYPE i.
    DATA lv_width TYPE i.
    DATA lv_height TYPE i.
    DATA lv_bits TYPE i.
    DATA lv_color_type TYPE i.
    DATA lv_interlace TYPE i.
    DATA lv_palette TYPE xstring.
    DATA lv_idat TYPE xstring.
    DATA lv_colors TYPE i.
    DATA lv_colorspace TYPE string.
    DATA lv_entries TYPE string.

    lv_length = xstrlen( iv_data ).
    IF lv_length < 8 OR iv_data(8) <> '89504E470D0A1A0A'.
      zcx_pdf_error=>raise( 'Not a PNG image' ).
    ENDIF.

    lv_offset = 8.
    WHILE lv_offset + 8 <= lv_length.
      lv_chunk_length = read_uint( iv_data   = iv_data
                                   iv_offset = lv_offset
                                   iv_length = 4 ).
      lv_data_offset = lv_offset + 4.
      lv_chunk_type = iv_data+lv_data_offset(4).
      lv_data_offset = lv_offset + 8.
      IF lv_data_offset + lv_chunk_length > lv_length.
        zcx_pdf_error=>raise( 'Unexpected end of PNG data' ).
      ENDIF.

      CASE lv_chunk_type.
        WHEN '49484452'.
* IHDR
          lv_width = read_uint( iv_data   = iv_data
                                iv_offset = lv_data_offset
                                iv_length = 4 ).
          lv_height = read_uint( iv_data   = iv_data
                                 iv_offset = lv_data_offset + 4
                                 iv_length = 4 ).
          lv_bits = read_uint( iv_data   = iv_data
                               iv_offset = lv_data_offset + 8
                               iv_length = 1 ).
          lv_color_type = read_uint( iv_data   = iv_data
                                     iv_offset = lv_data_offset + 9
                                     iv_length = 1 ).
          lv_interlace = read_uint( iv_data   = iv_data
                                    iv_offset = lv_data_offset + 12
                                    iv_length = 1 ).
        WHEN '504C5445'.
* PLTE
          lv_palette = iv_data+lv_data_offset(lv_chunk_length).
        WHEN '49444154'.
* IDAT
          CONCATENATE lv_idat iv_data+lv_data_offset(lv_chunk_length) INTO lv_idat IN BYTE MODE.
        WHEN '49454E44'.
* IEND
          EXIT.
      ENDCASE.

* skip data and CRC
      lv_offset = lv_data_offset + lv_chunk_length + 4.
    ENDWHILE.

    IF lv_width = 0 OR lv_height = 0.
      zcx_pdf_error=>raise( 'PNG header not found' ).
    ELSEIF lv_interlace <> 0.
      zcx_pdf_error=>raise( 'Interlaced PNG images are not supported' ).
    ELSEIF lv_bits > 8.
      zcx_pdf_error=>raise( 'PNG images with 16 bits per channel are not supported' ).
    ELSEIF lv_idat IS INITIAL.
      zcx_pdf_error=>raise( 'PNG image data not found' ).
    ENDIF.

    CASE lv_color_type.
      WHEN 0.
        lv_colors = 1.
        lv_colorspace = '/DeviceGray'.
      WHEN 2.
        lv_colors = 3.
        lv_colorspace = '/DeviceRGB'.
      WHEN 3.
        IF lv_palette IS INITIAL.
          zcx_pdf_error=>raise( 'PNG palette not found' ).
        ENDIF.
        lv_colors = 1.
        lv_colorspace = |[/Indexed /DeviceRGB { xstrlen( lv_palette ) / 3 - 1 } { zcl_pdf_util=>hex( lv_palette ) }]|.
      WHEN 4 OR 6.
        zcx_pdf_error=>raise( 'PNG images with alpha channel are not supported' ).
      WHEN OTHERS.
        zcx_pdf_error=>raise( |Unsupported PNG color type { lv_color_type }| ).
    ENDCASE.

    lv_entries = |/ColorSpace { lv_colorspace } /BitsPerComponent { lv_bits } /Filter /FlateDecode| &&
      | /DecodeParms << /Predictor 15 /Colors { lv_colors } /BitsPerComponent { lv_bits } /Columns { lv_width } >>|.

    CREATE OBJECT ro_image
      EXPORTING
        iv_width   = lv_width
        iv_height  = lv_height
        iv_entries = lv_entries
        iv_data    = lv_idat.
  ENDMETHOD.

  METHOD read_uint.
    DATA lv_offset TYPE i.
    DATA lv_byte TYPE x LENGTH 1.
    DATA lv_int TYPE i.

    IF iv_offset + iv_length > xstrlen( iv_data ).
      zcx_pdf_error=>raise( 'Unexpected end of image data' ).
    ENDIF.

    lv_offset = iv_offset.
    DO iv_length TIMES.
      lv_byte = iv_data+lv_offset(1).
      lv_int = lv_byte.
      rv_value = rv_value * 256 + lv_int.
      lv_offset = lv_offset + 1.
    ENDDO.
  ENDMETHOD.

  METHOD get_width.
    rv_width = mv_width.
  ENDMETHOD.

  METHOD get_height.
    rv_height = mv_height.
  ENDMETHOD.

  METHOD get_resource_name.
    rv_name = |/Im{ mv_id }|.
  ENDMETHOD.

  METHOD get_dictionary.
    rv_dictionary = |<< /Type /XObject /Subtype /Image /Width { mv_width } /Height { mv_height } { mv_entries }| &&
      | /Length { xstrlen( mv_data ) } >>|.
  ENDMETHOD.

  METHOD get_data.
    rv_data = mv_data.
  ENDMETHOD.

ENDCLASS.
