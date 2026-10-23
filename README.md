# pdf2

`pdf2` is a small, standalone ABAP library that creates PDF 1.4 documents in
memory. It does not use SAP ADS, spool services, function modules, or external
libraries. Import the two global classes in `src/` with abapGit, or add them to
an ABAP package manually.

## Features

- Multiple pages with configurable page dimensions (default: 595 x 842 points).
- Text using the standard Helvetica font.
- Lines and filled or outlined rectangles.
- PDF bytes returned as an `XSTRING`, ready for the caller to store or send.
- Input text encoded as Windows-1252 and emitted as hexadecimal PDF strings.

Coordinates and dimensions are in PDF points (72 points per inch), with the
origin at the bottom-left of each page. The library uses the built-in Helvetica
font and does not embed fonts. Text must be representable in Windows-1252;
unsupported characters raise `ZCX_PDF2`. Color and image embedding are not
currently supported.

## Usage

```abap
DATA(lo_pdf) = NEW zcl_pdf2( ).

lo_pdf->add_text(
  iv_page      = 1
  iv_x          = 72
  iv_y          = 770
  iv_text       = 'Hello from ABAP'
  iv_font_size  = 18 ).

lo_pdf->add_line(
  iv_page = 1
  iv_x1   = 72
  iv_y1   = 750
  iv_x2   = 523
  iv_y2   = 750 ).

DATA(lv_pdf) = lo_pdf->to_xstring( ).
```

`ZCL_PDF2` creates its first page in the constructor. Call `ADD_PAGE` for each
additional page; it returns the 1-based page index. The constructor accepts
optional page width and height in points. Invalid dimensions, drawing
parameters, and page indices raise `ZCX_PDF2`.

The code targets ABAP 7.40 or newer. `ZCL_PDF2` and `ZCX_PDF2` are the only
application classes required.
