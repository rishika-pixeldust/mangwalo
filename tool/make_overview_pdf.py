#!/usr/bin/env python3
"""Render docs/technical-overview.md to docs/technical-overview.pdf.

ReportLab (not wkhtmltopdf): embeds the bundled Plus Jakarta Sans TTFs with
proper ToUnicode maps, so the PDF is selectable/searchable and on-brand.
Handles the markdown subset the overview uses: #/##/### headings, paragraphs,
bullets, tables, fenced code, inline bold/italic/code/links.
"""
import re
import sys
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (KeepTogether, Paragraph, Preformatted,
                                SimpleDocTemplate, Spacer, Table, TableStyle)

ROOT = Path(__file__).resolve().parent.parent
FONTS = ROOT / "assets" / "fonts"

CREAM = colors.HexColor("#F3EEE6")
SURFACE = colors.HexColor("#F7F3EC")
FRAME = colors.HexColor("#E3DACC")
FRAME_SOFT = colors.HexColor("#EFE8DD")
INK = colors.HexColor("#201B16")
INK_SOFT = colors.HexColor("#6E6459")
ACCENT_DEEP = colors.HexColor("#B85A28")

for name, file in [("PJS", "PlusJakartaSans-Regular.ttf"),
                   ("PJS-Medium", "PlusJakartaSans-Medium.ttf"),
                   ("PJS-SemiBold", "PlusJakartaSans-SemiBold.ttf"),
                   ("PJS-Bold", "PlusJakartaSans-Bold.ttf"),
                   ("PJS-XBold", "PlusJakartaSans-ExtraBold.ttf")]:
    pdfmetrics.registerFont(TTFont(name, str(FONTS / file)))
pdfmetrics.registerFontFamily("PJS", normal="PJS", bold="PJS-Bold",
                              italic="PJS", boldItalic="PJS-Bold")
try:
    pdfmetrics.registerFont(
        TTFont("Mono", "/System/Library/Fonts/Menlo.ttc", subfontIndex=0))
    MONO = "Mono"
except Exception:
    MONO = "Courier"

body = ParagraphStyle("body", fontName="PJS", fontSize=9.6, leading=14.6,
                      textColor=INK, spaceAfter=5)
lede = ParagraphStyle("lede", parent=body, fontSize=10.4, leading=15.5,
                      textColor=INK_SOFT)
h1 = ParagraphStyle("h1", fontName="PJS-XBold", fontSize=22, leading=26,
                    textColor=INK, spaceAfter=6)
h2 = ParagraphStyle("h2", fontName="PJS-Bold", fontSize=13.5, leading=17,
                    textColor=ACCENT_DEEP, spaceBefore=14, spaceAfter=5)
h3 = ParagraphStyle("h3", fontName="PJS-Bold", fontSize=11, leading=14,
                    textColor=INK, spaceBefore=10, spaceAfter=3)
bullet = ParagraphStyle("bullet", parent=body, leftIndent=14,
                        bulletIndent=4, spaceAfter=3)
codestyle = ParagraphStyle("code", fontName=MONO, fontSize=7.6, leading=10.6,
                           textColor=INK)
cell = ParagraphStyle("cell", parent=body, fontSize=8.8, leading=12.4,
                      spaceAfter=0)
cellhead = ParagraphStyle("cellhead", parent=cell, fontName="PJS-Bold")


def esc(s: str) -> str:
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def inline(s: str) -> str:
    s = esc(s)
    # Stash code spans first so bold/italic markers inside them (e.g. *.env)
    # can't be misparsed as styling.
    codes: list[str] = []

    def stash(m):
        codes.append(m.group(1))
        return f"\x00{len(codes) - 1}\x00"

    s = re.sub(r"`([^`]+)`", stash, s)
    s = re.sub(r"\*\*([^*]+)\*\*", r"<b>\1</b>", s)
    s = re.sub(r"(?<!\*)\*([^*\n]+)\*(?!\*)", r"<i>\1</i>", s)
    s = re.sub(r"\[([^\]]+)\]\(([^)]+)\)",
               r'<link href="\2" color="#B85A28">\1</link>', s)
    s = re.sub(r"\x00(\d+)\x00", lambda m: (
        f'<font face="{MONO}" size="8.2" backColor="#F3EEE6"> '
        f'{codes[int(m.group(1))]} </font>'), s)
    return s


def md_table(rows):
    data = []
    for i, row in enumerate(rows):
        cells = [c.strip() for c in row.strip().strip("|").split("|")]
        style = cellhead if i == 0 else cell
        data.append([Paragraph(inline(c), style) for c in cells])
    t = Table(data, hAlign="LEFT", colWidths=None, repeatRows=1)
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), CREAM),
        ("LINEBELOW", (0, 0), (-1, 0), 1, FRAME),
        ("LINEBELOW", (0, 1), (-1, -1), 0.4, FRAME_SOFT),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("TOPPADDING", (0, 0), (-1, -1), 4),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
        ("LEFTPADDING", (0, 0), (-1, -1), 6),
        ("RIGHTPADDING", (0, 0), (-1, -1), 6),
    ]))
    return t


def build(md_path: Path, pdf_path: Path):
    lines = md_path.read_text().splitlines()
    story, i, first_para_done = [], 0, False
    while i < len(lines):
        line = lines[i]
        if line.startswith("```"):
            block, i = [], i + 1
            while i < len(lines) and not lines[i].startswith("```"):
                block.append(lines[i]); i += 1
            i += 1
            pre = Preformatted("\n".join(block), codestyle)
            t = Table([[pre]], colWidths=[None])
            t.setStyle(TableStyle([
                ("BACKGROUND", (0, 0), (-1, -1), SURFACE),
                ("BOX", (0, 0), (-1, -1), 0.6, FRAME_SOFT),
                ("TOPPADDING", (0, 0), (-1, -1), 7),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 7),
                ("LEFTPADDING", (0, 0), (-1, -1), 9),
                ("RIGHTPADDING", (0, 0), (-1, -1), 9),
            ]))
            story += [Spacer(1, 3), t, Spacer(1, 6)]
        elif line.startswith("|"):
            rows = []
            while i < len(lines) and lines[i].startswith("|"):
                if not re.match(r"^\|[\s:\-|]+\|$", lines[i]):
                    rows.append(lines[i])
                i += 1
            story += [Spacer(1, 3), md_table(rows), Spacer(1, 6)]
        elif line.startswith("# "):
            story.append(Paragraph(inline(line[2:]), h1)); i += 1
        elif line.startswith("## "):
            story.append(Paragraph(inline(line[3:]), h2)); i += 1
        elif line.startswith("### "):
            story.append(Paragraph(inline(line[4:]), h3)); i += 1
        elif line.startswith("- "):
            item, i = line[2:], i + 1
            while i < len(lines) and lines[i].startswith("  ") \
                    and not lines[i].lstrip().startswith("- "):
                item += " " + lines[i].strip(); i += 1
            story.append(Paragraph(inline(item), bullet, bulletText="•"))
        elif line.strip() == "":
            i += 1
        else:
            para, i = line, i + 1
            while i < len(lines) and lines[i].strip() != "" and not \
                    re.match(r"^(#|\||- |```)", lines[i]):
                para += " " + lines[i].strip(); i += 1
            style = body
            if not first_para_done and para.startswith("*"):
                para, style, first_para_done = para.strip("*"), lede, True
            story.append(Paragraph(inline(para), style))

    def footer(canvas, doc):
        canvas.saveState()
        canvas.setFont("PJS", 7.5)
        canvas.setFillColor(INK_SOFT)
        canvas.drawString(46, 26, "MangWalo — Technical Overview")
        canvas.drawRightString(A4[0] - 46, 26, f"{doc.page}")
        canvas.restoreState()

    doc = SimpleDocTemplate(str(pdf_path), pagesize=A4,
                            leftMargin=46, rightMargin=46,
                            topMargin=48, bottomMargin=46,
                            title="MangWalo — Technical Overview",
                            author="Rishika / MangWalo")
    doc.build(story, onFirstPage=footer, onLaterPages=footer)
    print(f"wrote {pdf_path} ({pdf_path.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    build(ROOT / "docs" / "technical-overview.md",
          ROOT / "docs" / "technical-overview.pdf")
