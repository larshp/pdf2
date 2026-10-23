"! A page in a PDF document, created via zcl_pdf_document=&gt;add_page
"! <p>Coordinates are in points, 1/72 inch, with the origin in the top left corner of the page and
"! the y axis pointing downwards. Use zcl_pdf_document=&gt;mm to convert from millimeters.</p>
CLASS zcl_pdf_page DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE
  GLOBAL FRIENDS zcl_pdf_document.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        iv_width  TYPE f
        iv_height TYPE f
      RAISING
        zcx_pdf_error.

    TYPES:
      BEGIN OF ty_point,
        x TYPE f,
        y TYPE f,
      END OF ty_point.
    TYPES ty_points TYPE STANDARD TABLE OF ty_point WITH DEFAULT KEY.

    CONSTANTS:
      BEGIN OF c_align,
        left    TYPE c LENGTH 1 VALUE 'L',
        center  TYPE c LENGTH 1 VALUE 'C',
        right   TYPE c LENGTH 1 VALUE 'R',
        justify TYPE c LENGTH 1 VALUE 'J',
      END OF c_align.

    CONSTANTS:
      BEGIN OF c_style,
        stroke      TYPE c LENGTH 1 VALUE 'S',
        fill        TYPE c LENGTH 1 VALUE 'F',
        fill_stroke TYPE c LENGTH 1 VALUE 'B',
      END OF c_style.

    METHODS get_width
      RETURNING
        VALUE(rv_width) TYPE f.

    METHODS get_height
      RETURNING
        VALUE(rv_height) TYPE f.

    "! Sets the font used for text, see zcl_pdf_font=&gt;c_name
    "! @parameter iv_name | Font name
    "! @parameter iv_size | Font size in points, keeps the current size if not supplied
    METHODS set_font
      IMPORTING
        iv_name        TYPE string
        iv_size        TYPE f OPTIONAL
      RETURNING
        VALUE(ro_page) TYPE REF TO zcl_pdf_page
      RAISING
        zcx_pdf_error.

    METHODS set_font_size
      IMPORTING
        iv_size        TYPE f
      RETURNING
        VALUE(ro_page) TYPE REF TO zcl_pdf_page.

    METHODS get_font
      RETURNING
        VALUE(ro_font) TYPE REF TO zcl_pdf_font.

    METHODS get_font_size
      RETURNING
        VALUE(rv_size) TYPE f.

    "! Sets the color used for text
    "! @parameter iv_color | Hex color, eg. '#FF0000'
    METHODS set_text_color
      IMPORTING
        iv_color       TYPE string
      RETURNING
        VALUE(ro_page) TYPE REF TO zcl_pdf_page
      RAISING
        zcx_pdf_error.

    "! Sets the color used for filling shapes
    "! @parameter iv_color | Hex color, eg. '#FF0000'
    METHODS set_fill_color
      IMPORTING
        iv_color       TYPE string
      RETURNING
        VALUE(ro_page) TYPE REF TO zcl_pdf_page
      RAISING
        zcx_pdf_error.

    "! Sets the color used for lines and shape outlines
    "! @parameter iv_color | Hex color, eg. '#FF0000'
    METHODS set_stroke_color
      IMPORTING
        iv_color       TYPE string
      RETURNING
        VALUE(ro_page) TYPE REF TO zcl_pdf_page
      RAISING
        zcx_pdf_error.

    METHODS set_line_width
      IMPORTING
        iv_width       TYPE f
      RETURNING
        VALUE(ro_page) TYPE REF TO zcl_pdf_page.

    "! Sets a dash pattern for lines, call without parameters for solid lines
    "! @parameter iv_dash | Length of dashes
    "! @parameter iv_gap | Length of gaps, defaults to the dash length
    METHODS set_line_dash
      IMPORTING
        iv_dash        TYPE f OPTIONAL
        iv_gap         TYPE f OPTIONAL
      PREFERRED PARAMETER iv_dash
      RETURNING
        VALUE(ro_page) TYPE REF TO zcl_pdf_page.

    "! Width of the text in the current font and size
    METHODS get_text_width
      IMPORTING
        iv_text         TYPE string
      RETURNING
        VALUE(rv_width) TYPE f.

    "! Writes a single line of text
    "! @parameter iv_x | Horizontal position, the left edge, center or right edge depending on alignment
    "! @parameter iv_y | Top of the text line
    "! @parameter iv_text | Text, line breaks are replaced with spaces
    "! @parameter iv_align | Alignment relative to iv_x, see c_align
    METHODS text
      IMPORTING
        iv_x           TYPE f
        iv_y           TYPE f
        iv_text        TYPE string
        iv_align       TYPE c DEFAULT c_align-left
      RETURNING
        VALUE(ro_page) TYPE REF TO zcl_pdf_page.

    "! Writes text wrapped at word boundaries to fit the width, line breaks in the text start new paragraphs
    "! @parameter iv_x | Left edge of the box
    "! @parameter iv_y | Top edge of the box
    "! @parameter iv_width | Width of the box
    "! @parameter iv_text | Text
    "! @parameter iv_align | Alignment within the box, see c_align
    "! @parameter iv_line_spacing | Line height as a multiple of the font size
    "! @parameter rv_height | Height of the written text
    METHODS text_box
      IMPORTING
        iv_x            TYPE f
        iv_y            TYPE f
        iv_width        TYPE f
        iv_text         TYPE string
        iv_align        TYPE c DEFAULT c_align-left
        iv_line_spacing TYPE f DEFAULT '1.2'
      RETURNING
        VALUE(rv_height) TYPE f.

    "! Height text_box would use for the text, without writing anything
    METHODS measure_text_box
      IMPORTING
        iv_width         TYPE f
        iv_text          TYPE string
        iv_line_spacing  TYPE f DEFAULT '1.2'
      RETURNING
        VALUE(rv_height) TYPE f.

    METHODS line
      IMPORTING
        iv_x1          TYPE f
        iv_y1          TYPE f
        iv_x2          TYPE f
        iv_y2          TYPE f
      RETURNING
        VALUE(ro_page) TYPE REF TO zcl_pdf_page.

    "! Draws a rectangle
    "! @parameter iv_x | Left edge
    "! @parameter iv_y | Top edge
    "! @parameter iv_width | Width
    "! @parameter iv_height | Height
    "! @parameter iv_style | Stroke and/or fill, see c_style
    "! @parameter iv_radius | Corner radius for rounded corners
    METHODS rectangle
      IMPORTING
        iv_x           TYPE f
        iv_y           TYPE f
        iv_width       TYPE f
        iv_height      TYPE f
        iv_style       TYPE c DEFAULT c_style-stroke
        iv_radius      TYPE f OPTIONAL
      RETURNING
        VALUE(ro_page) TYPE REF TO zcl_pdf_page.

    "! Draws a circle around the center iv_x, iv_y
    METHODS circle
      IMPORTING
        iv_x           TYPE f
        iv_y           TYPE f
        iv_radius      TYPE f
        iv_style       TYPE c DEFAULT c_style-stroke
      RETURNING
        VALUE(ro_page) TYPE REF TO zcl_pdf_page.

    "! Draws an ellipse around the center iv_x, iv_y
    METHODS ellipse
      IMPORTING
        iv_x           TYPE f
        iv_y           TYPE f
        iv_radius_x    TYPE f
        iv_radius_y    TYPE f
        iv_style       TYPE c DEFAULT c_style-stroke
      RETURNING
        VALUE(ro_page) TYPE REF TO zcl_pdf_page.

    "! Draws straight lines through the points
    "! @parameter it_points | At least two points
    "! @parameter iv_close | Connect the last point with the first point
    "! @parameter iv_style | Stroke and/or fill, see c_style
    METHODS polygon
      IMPORTING
        it_points      TYPE ty_points
        iv_close       TYPE abap_bool DEFAULT abap_true
        iv_style       TYPE c DEFAULT c_style-stroke
      RETURNING
        VALUE(ro_page) TYPE REF TO zcl_pdf_page.

    "! Draws an image, if only width or height is supplied the aspect ratio is kept,
    "! if neither is supplied one pixel equals one point
    "! @parameter io_image | Image, see zcl_pdf_image=&gt;load
    "! @parameter iv_x | Left edge
    "! @parameter iv_y | Top edge
    METHODS image
      IMPORTING
        io_image       TYPE REF TO zcl_pdf_image
        iv_x           TYPE f
        iv_y           TYPE f
        iv_width       TYPE f OPTIONAL
        iv_height      TYPE f OPTIONAL
      RETURNING
        VALUE(ro_page) TYPE REF TO zcl_pdf_page.

    "! Adds a clickable area which opens the URL
    METHODS link
      IMPORTING
        iv_x           TYPE f
        iv_y           TYPE f
        iv_width       TYPE f
        iv_height      TYPE f
        iv_url         TYPE string
      RETURNING
        VALUE(ro_page) TYPE REF TO zcl_pdf_page.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_line,
        text TYPE string,
        last TYPE abap_bool,
      END OF ty_line.
    TYPES ty_lines TYPE STANDARD TABLE OF ty_line WITH DEFAULT KEY.
    TYPES ty_fonts TYPE STANDARD TABLE OF REF TO zcl_pdf_font WITH DEFAULT KEY.
    TYPES ty_images TYPE STANDARD TABLE OF REF TO zcl_pdf_image WITH DEFAULT KEY.

    "! Bezier control point distance for approximating a quarter circle
    CONSTANTS c_kappa TYPE f VALUE '0.5522847498'.

    DATA mv_width TYPE f.
    DATA mv_height TYPE f.
    DATA mv_content TYPE string.
    DATA mt_fonts TYPE ty_fonts.
    DATA mt_images TYPE ty_images.
    DATA mt_annotations TYPE string_table.
    DATA mo_font TYPE REF TO zcl_pdf_font.
    DATA mv_font_size TYPE f.
    DATA mv_text_color TYPE string.
    DATA mv_fill_color TYPE string.
    DATA mv_current_fill TYPE string.

    METHODS append
      IMPORTING
        iv_operation TYPE string.

    "! Point in PDF coordinates, origin bottom left
    METHODS point
      IMPORTING
        iv_x            TYPE f
        iv_y            TYPE f
      RETURNING
        VALUE(rv_point) TYPE string.

    METHODS use_fill_color
      IMPORTING
        iv_color TYPE string.

    "! Graphics state changes are not allowed inside a path, call before constructing it
    METHODS begin_path
      IMPORTING
        iv_style TYPE c.

    METHODS paint
      IMPORTING
        iv_style TYPE c.

    METHODS ellipse_path
      IMPORTING
        iv_x        TYPE f
        iv_y        TYPE f
        iv_radius_x TYPE f
        iv_radius_y TYPE f.

    METHODS write_line
      IMPORTING
        iv_x            TYPE f
        iv_y            TYPE f
        iv_text         TYPE string
        iv_word_spacing TYPE f OPTIONAL.

    METHODS wrap_text
      IMPORTING
        iv_width        TYPE f
        iv_text         TYPE string
      RETURNING
        VALUE(rt_lines) TYPE ty_lines.

    METHODS split_word
      IMPORTING
        iv_width        TYPE f
      CHANGING
        cv_word         TYPE string
        ct_lines        TYPE ty_lines.
ENDCLASS.

CLASS zcl_pdf_page IMPLEMENTATION.

  METHOD constructor.
    mv_width = iv_width.
    mv_height = iv_height.
    mo_font = zcl_pdf_font=>get( zcl_pdf_font=>c_name-helvetica ).
    mv_font_size = 12.
    mv_text_color = '0 0 0'.
    mv_fill_color = '0 0 0'.
    mv_current_fill = '0 0 0'.
  ENDMETHOD.

  METHOD get_width.
    rv_width = mv_width.
  ENDMETHOD.

  METHOD get_height.
    rv_height = mv_height.
  ENDMETHOD.

  METHOD append.
    mv_content = mv_content && iv_operation && cl_abap_char_utilities=>newline.
  ENDMETHOD.

  METHOD point.
    rv_point = zcl_pdf_util=>number( iv_x ) && ` ` && zcl_pdf_util=>number( mv_height - iv_y ).
  ENDMETHOD.

  METHOD set_font.
    mo_font = zcl_pdf_font=>get( iv_name ).
    IF iv_size IS SUPPLIED.
      mv_font_size = iv_size.
    ENDIF.
    ro_page = me.
  ENDMETHOD.

  METHOD set_font_size.
    mv_font_size = iv_size.
    ro_page = me.
  ENDMETHOD.

  METHOD get_font.
    ro_font = mo_font.
  ENDMETHOD.

  METHOD get_font_size.
    rv_size = mv_font_size.
  ENDMETHOD.

  METHOD set_text_color.
    mv_text_color = zcl_pdf_util=>color( iv_color ).
    ro_page = me.
  ENDMETHOD.

  METHOD set_fill_color.
    mv_fill_color = zcl_pdf_util=>color( iv_color ).
    ro_page = me.
  ENDMETHOD.

  METHOD set_stroke_color.
    append( zcl_pdf_util=>color( iv_color ) && ` RG` ).
    ro_page = me.
  ENDMETHOD.

  METHOD set_line_width.
    append( zcl_pdf_util=>number( iv_width ) && ` w` ).
    ro_page = me.
  ENDMETHOD.

  METHOD set_line_dash.
    DATA lv_gap TYPE f.

    IF iv_dash <= 0.
      append( `[] 0 d` ).
    ELSE.
      lv_gap = iv_gap.
      IF lv_gap <= 0.
        lv_gap = iv_dash.
      ENDIF.
      append( |[{ zcl_pdf_util=>number( iv_dash ) } { zcl_pdf_util=>number( lv_gap ) }] 0 d| ).
    ENDIF.
    ro_page = me.
  ENDMETHOD.

  METHOD use_fill_color.
    IF iv_color <> mv_current_fill.
      append( iv_color && ` rg` ).
      mv_current_fill = iv_color.
    ENDIF.
  ENDMETHOD.

  METHOD begin_path.
    IF iv_style = c_style-fill OR iv_style = c_style-fill_stroke.
      use_fill_color( mv_fill_color ).
    ENDIF.
  ENDMETHOD.

  METHOD paint.
    CASE iv_style.
      WHEN c_style-fill.
        append( `f` ).
      WHEN c_style-fill_stroke.
        append( `B` ).
      WHEN OTHERS.
        append( `S` ).
    ENDCASE.
  ENDMETHOD.

  METHOD get_text_width.
    rv_width = mo_font->get_text_width(
      iv_text = iv_text
      iv_size = mv_font_size ).
  ENDMETHOD.

  METHOD write_line.
    DATA lv_bytes TYPE xstring.
    DATA lv_operation TYPE string.

    lv_bytes = zcl_pdf_util=>winansi( iv_text ).
    IF lv_bytes IS INITIAL.
      RETURN.
    ENDIF.

    READ TABLE mt_fonts WITH KEY table_line = mo_font TRANSPORTING NO FIELDS.
    IF sy-subrc <> 0.
      APPEND mo_font TO mt_fonts.
    ENDIF.

    use_fill_color( mv_text_color ).

    lv_operation = |BT { mo_font->get_resource_name( ) } { zcl_pdf_util=>number( mv_font_size ) } Tf | &&
      |{ point( iv_x = iv_x
                iv_y = iv_y ) } Td |.
    IF iv_word_spacing <> 0.
      lv_operation = lv_operation && zcl_pdf_util=>number( iv_word_spacing ) && ` Tw `.
    ENDIF.
    lv_operation = lv_operation && zcl_pdf_util=>hex( lv_bytes ) && ` Tj`.
    IF iv_word_spacing <> 0.
      lv_operation = lv_operation && ` 0 Tw`.
    ENDIF.
    append( lv_operation && ` ET` ).
  ENDMETHOD.

  METHOD text.
    DATA lv_text TYPE string.
    DATA lv_x TYPE f.

    lv_text = iv_text.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN lv_text WITH ` `.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>newline IN lv_text WITH ` `.

    lv_x = iv_x.
    CASE iv_align.
      WHEN c_align-center.
        lv_x = lv_x - get_text_width( lv_text ) / 2.
      WHEN c_align-right.
        lv_x = lv_x - get_text_width( lv_text ).
    ENDCASE.

    write_line(
      iv_x    = lv_x
      iv_y    = iv_y + mo_font->get_ascent( mv_font_size )
      iv_text = lv_text ).
    ro_page = me.
  ENDMETHOD.

  METHOD split_word.
* breaks a word which is wider than the available width
    DATA lv_length TYPE i.
    DATA ls_line LIKE LINE OF ct_lines.

    WHILE strlen( cv_word ) > 1 AND get_text_width( cv_word ) > iv_width.
      lv_length = 1.
      WHILE lv_length + 1 < strlen( cv_word ) AND get_text_width( substring( val = cv_word
                                                                             len = lv_length + 1 ) ) <= iv_width.
        lv_length = lv_length + 1.
      ENDWHILE.
      ls_line-text = cv_word(lv_length).
      APPEND ls_line TO ct_lines.
      cv_word = cv_word+lv_length.
    ENDWHILE.
  ENDMETHOD.

  METHOD wrap_text.
    DATA lv_text TYPE string.
    DATA lt_paragraphs TYPE string_table.
    DATA lv_paragraph LIKE LINE OF lt_paragraphs.
    DATA lt_words TYPE string_table.
    DATA lv_word LIKE LINE OF lt_words.
    DATA lv_candidate TYPE string.
    DATA ls_line LIKE LINE OF rt_lines.

    lv_text = iv_text.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN lv_text WITH cl_abap_char_utilities=>newline.
    SPLIT lv_text AT cl_abap_char_utilities=>newline INTO TABLE lt_paragraphs.

    LOOP AT lt_paragraphs INTO lv_paragraph.
      CLEAR ls_line.
      SPLIT lv_paragraph AT space INTO TABLE lt_words.
      LOOP AT lt_words INTO lv_word.
        IF lv_word IS INITIAL.
          CONTINUE.
        ENDIF.

        IF ls_line-text IS INITIAL.
          lv_candidate = lv_word.
        ELSE.
          lv_candidate = ls_line-text && ` ` && lv_word.
        ENDIF.

        IF iv_width <= 0 OR get_text_width( lv_candidate ) <= iv_width.
          ls_line-text = lv_candidate.
        ELSE.
          IF ls_line-text IS NOT INITIAL.
            APPEND ls_line TO rt_lines.
          ENDIF.
          split_word(
            EXPORTING
              iv_width = iv_width
            CHANGING
              cv_word  = lv_word
              ct_lines = rt_lines ).
          ls_line-text = lv_word.
        ENDIF.
      ENDLOOP.

      ls_line-last = abap_true.
      APPEND ls_line TO rt_lines.
    ENDLOOP.
  ENDMETHOD.

  METHOD text_box.
    DATA lt_lines TYPE ty_lines.
    DATA ls_line LIKE LINE OF lt_lines.
    DATA lv_line_height TYPE f.
    DATA lv_baseline TYPE f.
    DATA lv_line_width TYPE f.
    DATA lv_x TYPE f.
    DATA lv_spaces TYPE i.
    DATA lv_word_spacing TYPE f.

    lt_lines = wrap_text(
      iv_width = iv_width
      iv_text  = iv_text ).

    lv_line_height = mv_font_size * iv_line_spacing.
    lv_baseline = iv_y + mo_font->get_ascent( mv_font_size ).

    LOOP AT lt_lines INTO ls_line.
      lv_line_width = get_text_width( ls_line-text ).
      lv_x = iv_x.
      CLEAR lv_word_spacing.

      CASE iv_align.
        WHEN c_align-center.
          lv_x = iv_x + ( iv_width - lv_line_width ) / 2.
        WHEN c_align-right.
          lv_x = iv_x + iv_width - lv_line_width.
        WHEN c_align-justify.
          IF ls_line-last = abap_false.
            FIND ALL OCCURRENCES OF ` ` IN ls_line-text MATCH COUNT lv_spaces.
            IF lv_spaces > 0.
              lv_word_spacing = ( iv_width - lv_line_width ) / lv_spaces.
            ENDIF.
          ENDIF.
      ENDCASE.

      write_line(
        iv_x            = lv_x
        iv_y            = lv_baseline
        iv_text         = ls_line-text
        iv_word_spacing = lv_word_spacing ).

      lv_baseline = lv_baseline + lv_line_height.
    ENDLOOP.

    rv_height = lines( lt_lines ) * lv_line_height.
  ENDMETHOD.

  METHOD measure_text_box.
    DATA lt_lines TYPE ty_lines.
    DATA lv_line_height TYPE f.

    lt_lines = wrap_text(
      iv_width = iv_width
      iv_text  = iv_text ).
    lv_line_height = mv_font_size * iv_line_spacing.
    rv_height = lines( lt_lines ) * lv_line_height.
  ENDMETHOD.

  METHOD line.
    append( |{ point( iv_x = iv_x1
                      iv_y = iv_y1 ) } m { point( iv_x = iv_x2
                                                  iv_y = iv_y2 ) } l S| ).
    ro_page = me.
  ENDMETHOD.

  METHOD rectangle.
    DATA lv_radius TYPE f.
    DATA lv_k TYPE f.
    DATA lv_x0 TYPE f.
    DATA lv_y0 TYPE f.
    DATA lv_x1 TYPE f.
    DATA lv_y1 TYPE f.

    lv_radius = iv_radius.
    IF lv_radius > iv_width / 2.
      lv_radius = iv_width / 2.
    ENDIF.
    IF lv_radius > iv_height / 2.
      lv_radius = iv_height / 2.
    ENDIF.

    begin_path( iv_style ).
    IF lv_radius <= 0.
      append( |{ point( iv_x = iv_x
                        iv_y = iv_y + iv_height ) } { zcl_pdf_util=>number( iv_width ) } {
              zcl_pdf_util=>number( iv_height ) } re| ).
    ELSE.
* corners in page coordinates, y pointing downwards
      lv_k = lv_radius * c_kappa.
      lv_x0 = iv_x.
      lv_y0 = iv_y.
      lv_x1 = iv_x + iv_width.
      lv_y1 = iv_y + iv_height.
      append( |{ point( iv_x = lv_x0 + lv_radius
                        iv_y = lv_y0 ) } m| ).
      append( |{ point( iv_x = lv_x1 - lv_radius
                        iv_y = lv_y0 ) } l| ).
      append( |{ point( iv_x = lv_x1 - lv_radius + lv_k
                        iv_y = lv_y0 ) } { point( iv_x = lv_x1
                                                  iv_y = lv_y0 + lv_radius - lv_k ) } {
              point( iv_x = lv_x1
                     iv_y = lv_y0 + lv_radius ) } c| ).
      append( |{ point( iv_x = lv_x1
                        iv_y = lv_y1 - lv_radius ) } l| ).
      append( |{ point( iv_x = lv_x1
                        iv_y = lv_y1 - lv_radius + lv_k ) } { point( iv_x = lv_x1 - lv_radius + lv_k
                                                                     iv_y = lv_y1 ) } {
              point( iv_x = lv_x1 - lv_radius
                     iv_y = lv_y1 ) } c| ).
      append( |{ point( iv_x = lv_x0 + lv_radius
                        iv_y = lv_y1 ) } l| ).
      append( |{ point( iv_x = lv_x0 + lv_radius - lv_k
                        iv_y = lv_y1 ) } { point( iv_x = lv_x0
                                                  iv_y = lv_y1 - lv_radius + lv_k ) } {
              point( iv_x = lv_x0
                     iv_y = lv_y1 - lv_radius ) } c| ).
      append( |{ point( iv_x = lv_x0
                        iv_y = lv_y0 + lv_radius ) } l| ).
      append( |{ point( iv_x = lv_x0
                        iv_y = lv_y0 + lv_radius - lv_k ) } { point( iv_x = lv_x0 + lv_radius - lv_k
                                                                     iv_y = lv_y0 ) } {
              point( iv_x = lv_x0 + lv_radius
                     iv_y = lv_y0 ) } c h| ).
    ENDIF.

    paint( iv_style ).
    ro_page = me.
  ENDMETHOD.

  METHOD ellipse_path.
    DATA lv_kx TYPE f.
    DATA lv_ky TYPE f.

    lv_kx = iv_radius_x * c_kappa.
    lv_ky = iv_radius_y * c_kappa.

    append( |{ point( iv_x = iv_x + iv_radius_x
                      iv_y = iv_y ) } m| ).
    append( |{ point( iv_x = iv_x + iv_radius_x
                      iv_y = iv_y + lv_ky ) } { point( iv_x = iv_x + lv_kx
                                                       iv_y = iv_y + iv_radius_y ) } {
            point( iv_x = iv_x
                   iv_y = iv_y + iv_radius_y ) } c| ).
    append( |{ point( iv_x = iv_x - lv_kx
                      iv_y = iv_y + iv_radius_y ) } { point( iv_x = iv_x - iv_radius_x
                                                             iv_y = iv_y + lv_ky ) } {
            point( iv_x = iv_x - iv_radius_x
                   iv_y = iv_y ) } c| ).
    append( |{ point( iv_x = iv_x - iv_radius_x
                      iv_y = iv_y - lv_ky ) } { point( iv_x = iv_x - lv_kx
                                                       iv_y = iv_y - iv_radius_y ) } {
            point( iv_x = iv_x
                   iv_y = iv_y - iv_radius_y ) } c| ).
    append( |{ point( iv_x = iv_x + lv_kx
                      iv_y = iv_y - iv_radius_y ) } { point( iv_x = iv_x + iv_radius_x
                                                             iv_y = iv_y - lv_ky ) } {
            point( iv_x = iv_x + iv_radius_x
                   iv_y = iv_y ) } c h| ).
  ENDMETHOD.

  METHOD circle.
    begin_path( iv_style ).
    ellipse_path(
      iv_x        = iv_x
      iv_y        = iv_y
      iv_radius_x = iv_radius
      iv_radius_y = iv_radius ).
    paint( iv_style ).
    ro_page = me.
  ENDMETHOD.

  METHOD ellipse.
    begin_path( iv_style ).
    ellipse_path(
      iv_x        = iv_x
      iv_y        = iv_y
      iv_radius_x = iv_radius_x
      iv_radius_y = iv_radius_y ).
    paint( iv_style ).
    ro_page = me.
  ENDMETHOD.

  METHOD polygon.
    DATA ls_point LIKE LINE OF it_points.
    DATA lv_path TYPE string.

    ro_page = me.
    IF lines( it_points ) < 2.
      RETURN.
    ENDIF.

    LOOP AT it_points INTO ls_point.
      IF sy-tabix = 1.
        lv_path = point( iv_x = ls_point-x
                         iv_y = ls_point-y ) && ` m`.
      ELSE.
        lv_path = lv_path && ` ` && point( iv_x = ls_point-x
                                           iv_y = ls_point-y ) && ` l`.
      ENDIF.
    ENDLOOP.
    IF iv_close = abap_true.
      lv_path = lv_path && ` h`.
    ENDIF.
    begin_path( iv_style ).
    append( lv_path ).

    paint( iv_style ).
  ENDMETHOD.

  METHOD image.
    DATA lv_width TYPE f.
    DATA lv_height TYPE f.

    lv_width = iv_width.
    lv_height = iv_height.
    IF lv_width <= 0 AND lv_height <= 0.
      lv_width = io_image->get_width( ).
      lv_height = io_image->get_height( ).
    ELSEIF lv_width <= 0.
      lv_width = lv_height * io_image->get_width( ) / io_image->get_height( ).
    ELSEIF lv_height <= 0.
      lv_height = lv_width * io_image->get_height( ) / io_image->get_width( ).
    ENDIF.

    READ TABLE mt_images WITH KEY table_line = io_image TRANSPORTING NO FIELDS.
    IF sy-subrc <> 0.
      APPEND io_image TO mt_images.
    ENDIF.

    append( |q { zcl_pdf_util=>number( lv_width ) } 0 0 { zcl_pdf_util=>number( lv_height ) } {
            point( iv_x = iv_x
                   iv_y = iv_y + lv_height ) } cm { io_image->get_resource_name( ) } Do Q| ).
    ro_page = me.
  ENDMETHOD.

  METHOD link.
    DATA lv_annotation TYPE string.

    lv_annotation = |<< /Type /Annot /Subtype /Link /Rect [{ point( iv_x = iv_x
                                                                   iv_y  = iv_y + iv_height ) } {
      point( iv_x = iv_x + iv_width
             iv_y = iv_y ) }] /Border [0 0 0] /A << /S /URI /URI {
      zcl_pdf_util=>hex( zcl_pdf_util=>ascii( iv_url ) ) } >> >>|.
    APPEND lv_annotation TO mt_annotations.
    ro_page = me.
  ENDMETHOD.

ENDCLASS.
