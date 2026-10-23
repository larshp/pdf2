"! PDF document, add pages, draw on them, and render to binary PDF data
CLASS zcl_pdf_document DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CONSTANTS:
      BEGIN OF c_format,
        a3     TYPE string VALUE 'A3',
        a4     TYPE string VALUE 'A4',
        a5     TYPE string VALUE 'A5',
        letter TYPE string VALUE 'LETTER',
        legal  TYPE string VALUE 'LEGAL',
      END OF c_format.

    CONSTANTS c_producer TYPE string VALUE 'abap-pdf'.

    CLASS-METHODS create
      RETURNING
        VALUE(ro_document) TYPE REF TO zcl_pdf_document.

    "! Converts millimeters to points
    CLASS-METHODS mm
      IMPORTING
        iv_mm            TYPE f
      RETURNING
        VALUE(rv_points) TYPE f.

    "! Adds a page at the end of the document
    "! @parameter iv_format | Page format, see c_format, ignored if iv_width and iv_height are supplied
    "! @parameter iv_landscape | Landscape orientation
    "! @parameter iv_width | Custom page width in points
    "! @parameter iv_height | Custom page height in points
    METHODS add_page
      IMPORTING
        iv_format      TYPE string DEFAULT c_format-a4
        iv_landscape   TYPE abap_bool DEFAULT abap_false
        iv_width       TYPE f OPTIONAL
        iv_height      TYPE f OPTIONAL
      PREFERRED PARAMETER iv_format
      RETURNING
        VALUE(ro_page) TYPE REF TO zcl_pdf_page
      RAISING
        zcx_pdf_error.

    "! Returns a page, the first page has index 1
    METHODS get_page
      IMPORTING
        iv_index       TYPE i
      RETURNING
        VALUE(ro_page) TYPE REF TO zcl_pdf_page
      RAISING
        zcx_pdf_error.

    METHODS get_page_count
      RETURNING
        VALUE(rv_count) TYPE i.

    METHODS set_title
      IMPORTING
        iv_title           TYPE string
      RETURNING
        VALUE(ro_document) TYPE REF TO zcl_pdf_document.

    METHODS set_author
      IMPORTING
        iv_author          TYPE string
      RETURNING
        VALUE(ro_document) TYPE REF TO zcl_pdf_document.

    METHODS set_subject
      IMPORTING
        iv_subject         TYPE string
      RETURNING
        VALUE(ro_document) TYPE REF TO zcl_pdf_document.

    METHODS set_keywords
      IMPORTING
        iv_keywords        TYPE string
      RETURNING
        VALUE(ro_document) TYPE REF TO zcl_pdf_document.

    METHODS set_creator
      IMPORTING
        iv_creator         TYPE string
      RETURNING
        VALUE(ro_document) TYPE REF TO zcl_pdf_document.

    "! Sets the creation date, it is not written to the document if not set
    METHODS set_creation_date
      IMPORTING
        iv_date            TYPE d
        iv_time            TYPE t OPTIONAL
      RETURNING
        VALUE(ro_document) TYPE REF TO zcl_pdf_document.

    "! Renders the document as binary PDF data
    METHODS render
      RETURNING
        VALUE(rv_pdf) TYPE xstring.

  PRIVATE SECTION.
    TYPES ty_pages TYPE STANDARD TABLE OF REF TO zcl_pdf_page WITH DEFAULT KEY.
    TYPES ty_offsets TYPE STANDARD TABLE OF i WITH DEFAULT KEY.
    TYPES:
      BEGIN OF ty_resource,
        name   TYPE string,
        number TYPE i,
      END OF ty_resource.
    TYPES ty_resources TYPE SORTED TABLE OF ty_resource WITH UNIQUE KEY name.

    DATA mt_pages TYPE ty_pages.
    DATA mv_title TYPE string.
    DATA mv_author TYPE string.
    DATA mv_subject TYPE string.
    DATA mv_keywords TYPE string.
    DATA mv_creator TYPE string.
    DATA mv_creation_date TYPE string.

    DATA mv_output TYPE xstring.
    DATA mt_offsets TYPE ty_offsets.

    METHODS write
      IMPORTING
        iv_text TYPE string.

    METHODS write_object
      IMPORTING
        iv_dictionary TYPE string
        iv_stream     TYPE xstring OPTIONAL.

    METHODS info_dictionary
      RETURNING
        VALUE(rv_dictionary) TYPE string.

    METHODS page_dictionary
      IMPORTING
        io_page              TYPE REF TO zcl_pdf_page
        it_resources         TYPE ty_resources
        iv_contents          TYPE i
      RETURNING
        VALUE(rv_dictionary) TYPE string.
ENDCLASS.

CLASS zcl_pdf_document IMPLEMENTATION.

  METHOD create.
    CREATE OBJECT ro_document.
  ENDMETHOD.

  METHOD mm.
    rv_points = iv_mm * 72 / '25.4'.
  ENDMETHOD.

  METHOD add_page.
    DATA lv_width TYPE f.
    DATA lv_height TYPE f.
    DATA lv_swap TYPE f.
    DATA lv_format TYPE string.

    IF iv_width > 0 AND iv_height > 0.
      lv_width = iv_width.
      lv_height = iv_height.
    ELSE.
      lv_format = to_upper( iv_format ).
      CASE lv_format.
        WHEN c_format-a3.
          lv_width = '841.89'.
          lv_height = '1190.55'.
        WHEN c_format-a4.
          lv_width = '595.28'.
          lv_height = '841.89'.
        WHEN c_format-a5.
          lv_width = '419.53'.
          lv_height = '595.28'.
        WHEN c_format-letter.
          lv_width = 612.
          lv_height = 792.
        WHEN c_format-legal.
          lv_width = 612.
          lv_height = 1008.
        WHEN OTHERS.
          zcx_pdf_error=>raise( |Unknown page format "{ iv_format }"| ).
      ENDCASE.
    ENDIF.

    IF iv_landscape = abap_true AND lv_width < lv_height.
      lv_swap = lv_width.
      lv_width = lv_height.
      lv_height = lv_swap.
    ENDIF.

    CREATE OBJECT ro_page
      EXPORTING
        iv_width  = lv_width
        iv_height = lv_height.
    APPEND ro_page TO mt_pages.
  ENDMETHOD.

  METHOD get_page.
    READ TABLE mt_pages INDEX iv_index INTO ro_page.
    IF sy-subrc <> 0.
      zcx_pdf_error=>raise( |Page { iv_index } does not exist| ).
    ENDIF.
  ENDMETHOD.

  METHOD get_page_count.
    rv_count = lines( mt_pages ).
  ENDMETHOD.

  METHOD set_title.
    mv_title = iv_title.
    ro_document = me.
  ENDMETHOD.

  METHOD set_author.
    mv_author = iv_author.
    ro_document = me.
  ENDMETHOD.

  METHOD set_subject.
    mv_subject = iv_subject.
    ro_document = me.
  ENDMETHOD.

  METHOD set_keywords.
    mv_keywords = iv_keywords.
    ro_document = me.
  ENDMETHOD.

  METHOD set_creator.
    mv_creator = iv_creator.
    ro_document = me.
  ENDMETHOD.

  METHOD set_creation_date.
    mv_creation_date = |D:{ iv_date }{ iv_time }|.
    ro_document = me.
  ENDMETHOD.

  METHOD write.
    DATA lv_data TYPE xstring.
    lv_data = zcl_pdf_util=>ascii( iv_text ).
    CONCATENATE mv_output lv_data INTO mv_output IN BYTE MODE.
  ENDMETHOD.

  METHOD write_object.
    DATA lv_offset TYPE i.
    DATA lv_number TYPE i.

    lv_offset = xstrlen( mv_output ).
    APPEND lv_offset TO mt_offsets.
    lv_number = lines( mt_offsets ).

    write( |{ lv_number } 0 obj\n{ iv_dictionary }\n| ).
    IF iv_stream IS SUPPLIED.
      write( |stream\n| ).
      CONCATENATE mv_output iv_stream INTO mv_output IN BYTE MODE.
      write( |\nendstream\n| ).
    ENDIF.
    write( |endobj\n| ).
  ENDMETHOD.

  METHOD info_dictionary.
    rv_dictionary = |<< /Producer { zcl_pdf_util=>text_string( c_producer ) }|.
    IF mv_title IS NOT INITIAL.
      rv_dictionary = rv_dictionary && | /Title { zcl_pdf_util=>text_string( mv_title ) }|.
    ENDIF.
    IF mv_author IS NOT INITIAL.
      rv_dictionary = rv_dictionary && | /Author { zcl_pdf_util=>text_string( mv_author ) }|.
    ENDIF.
    IF mv_subject IS NOT INITIAL.
      rv_dictionary = rv_dictionary && | /Subject { zcl_pdf_util=>text_string( mv_subject ) }|.
    ENDIF.
    IF mv_keywords IS NOT INITIAL.
      rv_dictionary = rv_dictionary && | /Keywords { zcl_pdf_util=>text_string( mv_keywords ) }|.
    ENDIF.
    IF mv_creator IS NOT INITIAL.
      rv_dictionary = rv_dictionary && | /Creator { zcl_pdf_util=>text_string( mv_creator ) }|.
    ENDIF.
    IF mv_creation_date IS NOT INITIAL.
      rv_dictionary = rv_dictionary && | /CreationDate { zcl_pdf_util=>hex( zcl_pdf_util=>ascii( mv_creation_date ) ) }|.
    ENDIF.
    rv_dictionary = rv_dictionary && ` >>`.
  ENDMETHOD.

  METHOD page_dictionary.
    DATA lo_font TYPE REF TO zcl_pdf_font.
    DATA lo_image TYPE REF TO zcl_pdf_image.
    DATA ls_resource LIKE LINE OF it_resources.
    DATA lv_annotation TYPE string.
    DATA lv_fonts TYPE string.
    DATA lv_images TYPE string.
    DATA lv_annotations TYPE string.

    LOOP AT io_page->mt_fonts INTO lo_font.
      READ TABLE it_resources INTO ls_resource WITH TABLE KEY name = lo_font->get_resource_name( ).
      ASSERT sy-subrc = 0.
      lv_fonts = lv_fonts && | { ls_resource-name } { ls_resource-number } 0 R|.
    ENDLOOP.
    LOOP AT io_page->mt_images INTO lo_image.
      READ TABLE it_resources INTO ls_resource WITH TABLE KEY name = lo_image->get_resource_name( ).
      ASSERT sy-subrc = 0.
      lv_images = lv_images && | { ls_resource-name } { ls_resource-number } 0 R|.
    ENDLOOP.
    LOOP AT io_page->mt_annotations INTO lv_annotation.
      lv_annotations = lv_annotations && ` ` && lv_annotation.
    ENDLOOP.

    rv_dictionary = |<< /Type /Page /Parent 2 0 R /MediaBox [0 0 { zcl_pdf_util=>number( io_page->mv_width ) } {
      zcl_pdf_util=>number( io_page->mv_height ) }] /Resources <<|.
    IF lv_fonts IS NOT INITIAL.
      rv_dictionary = rv_dictionary && | /Font <<{ lv_fonts } >>|.
    ENDIF.
    IF lv_images IS NOT INITIAL.
      rv_dictionary = rv_dictionary && | /XObject <<{ lv_images } >>|.
    ENDIF.
    rv_dictionary = rv_dictionary && | >> /Contents { iv_contents } 0 R|.
    IF lv_annotations IS NOT INITIAL.
      rv_dictionary = rv_dictionary && | /Annots [{ lv_annotations } ]|.
    ENDIF.
    rv_dictionary = rv_dictionary && ` >>`.
  ENDMETHOD.

  METHOD render.
* object numbers: 1 catalog, 2 page tree, 3 info, then fonts, images, and page/content pairs
    DATA lo_page TYPE REF TO zcl_pdf_page.
    DATA lo_font TYPE REF TO zcl_pdf_font.
    DATA lo_image TYPE REF TO zcl_pdf_image.
    DATA lt_fonts TYPE STANDARD TABLE OF REF TO zcl_pdf_font WITH DEFAULT KEY.
    DATA lt_images TYPE STANDARD TABLE OF REF TO zcl_pdf_image WITH DEFAULT KEY.
    DATA lt_resources TYPE ty_resources.
    DATA ls_resource LIKE LINE OF lt_resources.
    DATA lv_number TYPE i.
    DATA lv_first_page TYPE i.
    DATA lv_kids TYPE string.
    DATA lv_content TYPE xstring.
    DATA lv_offset TYPE i.
    DATA lv_xref TYPE i.
    DATA lv_count TYPE i.
    DATA lv_padded TYPE n LENGTH 10.
    DATA lv_table TYPE string.
    DATA lv_header TYPE xstring.

    CLEAR mv_output.
    CLEAR mt_offsets.

    lv_number = 3.
    LOOP AT mt_pages INTO lo_page.
      LOOP AT lo_page->mt_fonts INTO lo_font.
        READ TABLE lt_resources WITH TABLE KEY name = lo_font->get_resource_name( ) TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          lv_number = lv_number + 1.
          ls_resource-name = lo_font->get_resource_name( ).
          ls_resource-number = lv_number.
          INSERT ls_resource INTO TABLE lt_resources.
          APPEND lo_font TO lt_fonts.
        ENDIF.
      ENDLOOP.
      LOOP AT lo_page->mt_images INTO lo_image.
        READ TABLE lt_resources WITH TABLE KEY name = lo_image->get_resource_name( ) TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          lv_number = lv_number + 1.
          ls_resource-name = lo_image->get_resource_name( ).
          ls_resource-number = lv_number.
          INSERT ls_resource INTO TABLE lt_resources.
          APPEND lo_image TO lt_images.
        ENDIF.
      ENDLOOP.
    ENDLOOP.

    lv_first_page = lv_number + 1.
    lv_number = lv_first_page.
    LOOP AT mt_pages INTO lo_page.
      lv_kids = lv_kids && | { lv_number } 0 R|.
      lv_number = lv_number + 2.
    ENDLOOP.

* header, the comment with bytes above 127 marks the file as binary
    write( |%PDF-1.4\n%| ).
    lv_header = 'E2E3CFD30A'.
    CONCATENATE mv_output lv_header INTO mv_output IN BYTE MODE.

    write_object( `<< /Type /Catalog /Pages 2 0 R >>` ).
    write_object( |<< /Type /Pages /Kids [{ lv_kids } ] /Count { lines( mt_pages ) } >>| ).
    write_object( info_dictionary( ) ).

    LOOP AT lt_fonts INTO lo_font.
      write_object( lo_font->get_dictionary( ) ).
    ENDLOOP.

    LOOP AT lt_images INTO lo_image.
      write_object(
        iv_dictionary = lo_image->get_dictionary( )
        iv_stream     = lo_image->get_data( ) ).
    ENDLOOP.

    lv_number = lv_first_page.
    LOOP AT mt_pages INTO lo_page.
      write_object( page_dictionary(
        io_page      = lo_page
        it_resources = lt_resources
        iv_contents  = lv_number + 1 ) ).
      lv_content = zcl_pdf_util=>ascii( lo_page->mv_content ).
      write_object(
        iv_dictionary = |<< /Length { xstrlen( lv_content ) } >>|
        iv_stream     = lv_content ).
      lv_number = lv_number + 2.
    ENDLOOP.

* cross reference table, each entry is exactly 20 bytes
    lv_xref = xstrlen( mv_output ).
    lv_count = lines( mt_offsets ) + 1.
    lv_table = |xref\n0 { lv_count }\n0000000000 65535 f \n|.
    LOOP AT mt_offsets INTO lv_offset.
      lv_padded = lv_offset.
      lv_table = lv_table && |{ lv_padded } 00000 n \n|.
    ENDLOOP.
    write( lv_table ).
    write( |trailer\n<< /Size { lv_count } /Root 1 0 R /Info 3 0 R >>\nstartxref\n{ lv_xref }\n%%EOF\n| ).

    rv_pdf = mv_output.
    CLEAR mv_output.
    CLEAR mt_offsets.
  ENDMETHOD.

ENDCLASS.
