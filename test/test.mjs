// Integration test: renders the demo document with each image fixture, then validates the PDF
// structure, and if available checks the files with qpdf and pdftotext
import * as fs from "node:fs";
import * as path from "node:path";
import {execFileSync} from "node:child_process";

await import("../output/init.mjs");

const fixtures = ["image.jpg", "image.png", "palette.png", "gray.png"];

function fail(message) {
  console.error("FAIL: " + message);
  process.exit(1);
}

function validateStructure(name, pdf) {
  const text = pdf.toString("latin1");
  if (!text.startsWith("%PDF-1.4\n")) fail(name + ": header");
  if (!text.endsWith("%%EOF\n")) fail(name + ": trailer");

  const startxref = Number(/startxref\n(\d+)\n%%EOF\n$/.exec(text)?.[1]);
  if (text.substring(startxref, startxref + 5) !== "xref\n") fail(name + ": startxref does not point to xref");

  const xref = /^xref\n0 (\d+)\n/.exec(text.substring(startxref));
  const size = Number(xref[1]);
  let offset = startxref + xref[0].length;
  for (let i = 0; i < size; i++) {
    const entry = text.substring(offset, offset + 20);
    offset += 20;
    if (i === 0) continue;
    const match = /^(\d{10}) 00000 n \n$/.exec(entry);
    if (match === null) fail(name + ": invalid xref entry " + JSON.stringify(entry));
    const object = Number(match[1]);
    if (!text.startsWith(i + " 0 obj\n", object)) fail(name + ": xref entry " + i + " points to wrong offset");
  }

  for (const match of text.matchAll(/\/Length (\d+) >>\nstream\n/g)) {
    const start = match.index + match[0].length;
    const end = start + Number(match[1]);
    if (text.substring(end, end + 11) !== "\nendstream\n") fail(name + ": stream length mismatch at " + match.index);
  }
}

function toolAvailable(tool) {
  try {
    execFileSync(tool, ["-v"], {stdio: "ignore"});
  } catch (e) {
    return e.code !== "ENOENT";
  }
  return true;
}

function external(name, file) {
  for (const tool of ["qpdf", "pdftotext"]) {
    if (!toolAvailable(tool)) {
      if (process.env.CI) fail(tool + " not installed");
      console.log("  " + tool + " not installed, skipping");
      continue;
    }
    if (tool === "qpdf") {
      const out = execFileSync("qpdf", ["--check", file]).toString();
      if (!out.includes("No syntax or stream encoding errors found")) fail(name + ": qpdf\n" + out);
      console.log("  qpdf --check ok");
    } else {
      const out = execFileSync("pdftotext", ["-enc", "UTF-8", file, "-"]).toString();
      for (const expected of ["abap-pdf", "Standard fonts", "Times-BoldItalic", "ÆØÅ", "€ 100",
        "“quoted”", "Page 1 of 2", "Page 2 of 2", "delivered in boxes"]) {
        if (!out.includes(expected)) fail(name + ": text not found: " + expected + "\n" + out);
      }
      console.log("  pdftotext ok");
    }
  }
}

console.log("Integration testing");
for (const fixture of fixtures) {
  const data = fs.readFileSync(path.join("test", "fixtures", fixture));
  const image = new abap.types.XString();
  image.set(data.toString("hex").toUpperCase());

  const result = await abap.Classes["ZCL_PDF_DEMO"].build({iv_image: image});
  const pdf = Buffer.from(result.get(), "hex");
  const file = path.join("output", "demo_" + fixture.replace(".", "_") + ".pdf");
  fs.writeFileSync(file, pdf);
  console.log(file + ", " + pdf.length + " bytes");

  validateStructure(fixture, pdf);
  console.log("  structure ok");
  external(fixture, file);
}
console.log("OK");
