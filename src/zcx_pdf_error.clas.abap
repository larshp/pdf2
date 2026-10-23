CLASS zcx_pdf_error DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  CREATE PUBLIC.

  PUBLIC SECTION.
    DATA mv_text TYPE string READ-ONLY.

    METHODS constructor
      IMPORTING
        textid      LIKE textid OPTIONAL
        previous    LIKE previous OPTIONAL
        iv_text     TYPE string OPTIONAL.

    CLASS-METHODS raise
      IMPORTING
        iv_text TYPE string
      RAISING
        zcx_pdf_error.

    METHODS get_text REDEFINITION.
ENDCLASS.

CLASS zcx_pdf_error IMPLEMENTATION.

  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor(
      textid   = textid
      previous = previous ).
    mv_text = iv_text.
  ENDMETHOD.

  METHOD raise.
    RAISE EXCEPTION TYPE zcx_pdf_error
      EXPORTING
        iv_text = iv_text.
  ENDMETHOD.

  METHOD get_text.
    result = mv_text.
  ENDMETHOD.

ENDCLASS.
