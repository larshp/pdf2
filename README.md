# pdf2

Standalone ABAP library for generating PDF files.

- Plain ABAP, 7.02 syntax, no dependencies, only standard classes like `CL_ABAP_CONV_OUT_CE` are used
- The 12 standard PDF fonts (Helvetica, Times, Courier, with bold and italic variants) with exact glyph metrics
- Text in WinAnsiEncoding, covering Western European characters, `€`, typographic quotes and dashes
- Single line text with left, center and right alignment
- Text boxes with word wrapping, paragraphs, and left, center, right or justified alignment
- Lines, rectangles, rounded rectangles, circles, ellipses and polygons, stroked and/or filled
- Colors, line widths and dash patterns
- JPEG images, grayscale, RGB and CMYK
- PNG images, grayscale, RGB and palette, without alpha channel and not interlaced
- Links to URLs
- Document metadata, title, author, subject, keywords, creator, creation date
- Page formats A3, A4, A5, Letter, Legal, or custom sizes, portrait or landscape

Install via [abapGit](https://abapgit.org).

## Example

```abap
DATA lo_document TYPE REF TO zcl_pdf_document.
DATA lo_page TYPE REF TO zcl_pdf_page.
DATA lv_pdf TYPE xstring.

lo_document = zcl_pdf_document=>create( ).
lo_document->set_title( `Hello` ).

lo_page = lo_document->add_page( zcl_pdf_document=>c_format-a4 ).

lo_page->set_font(
  iv_name = zcl_pdf_font=>c_name-helvetica_bold
  iv_size = 20 ).
lo_page->text(
  iv_x    = 50
  iv_y    = 50
  iv_text = `Hello World` ).

lo_page->set_font(
  iv_name = zcl_pdf_font=>c_name-times_roman
  iv_size = 11 ).
lo_page->text_box(
  iv_x     = 50
  iv_y     = 90
  iv_width = lo_page->get_width( ) - 100
  iv_text  = `Long text is wrapped at word boundaries to fit the width of the box.`
  iv_align = zcl_pdf_page=>c_align-justify ).

lo_page->set_fill_color( '#1F4E79' ).
lo_page->rectangle(
  iv_x      = 50
  iv_y      = 150
  iv_width  = 200
  iv_height = 100
  iv_radius = 10
  iv_style  = zcl_pdf_page=>c_style-fill ).

lv_pdf = lo_document->render( ).
```

[`ZCL_PDF_DEMO`](src/zcl_pdf_demo.clas.abap) builds a document using all features.

## Coordinates

All positions and sizes are in points, 1/72 inch. The origin is the top left corner of the page, and the y axis
points downwards. For text, `iv_y` is the top of the line. Use `zcl_pdf_document=>mm( )` to convert from
millimeters.

## Classes

| Class | Description |
|-------|-------------|
| `ZCL_PDF_DOCUMENT` | Pages, metadata, and rendering to `xstring` |
| `ZCL_PDF_PAGE` | Drawing text, shapes and images on a page |
| `ZCL_PDF_FONT` | Standard fonts and text measurement |
| `ZCL_PDF_IMAGE` | Loading JPEG and PNG images, an image can be drawn any number of times, it is stored once |
| `ZCL_PDF_UTIL` | Encoding helpers |
| `ZCX_PDF_ERROR` | Exception |

## Limitations

- No font embedding, so characters outside WinAnsiEncoding are replaced with `?`
- Content streams are not compressed
- No automatic page breaks, use `measure_text_box( )` and `add_page( )`

## Development

```
npm install
npm test
```

Runs [abaplint](https://abaplint.org), the unit tests via the [transpiler](https://github.com/abaplint/transpiler),
and an integration test which renders the demo document to `output/` and checks it with `qpdf` and `pdftotext`
when installed.

Glyph widths are taken from the Adobe Core14 AFM files, Copyright (c) 1985, 1987, 1989, 1990, 1993, 1997 Adobe
Systems Incorporated.
