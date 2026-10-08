"""Render the project's Korean README and actual screenshots to a printable PDF."""

from __future__ import annotations

import re
from pathlib import Path
from xml.sax.saxutils import escape

from PIL import Image as PILImage
from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    BaseDocTemplate, Flowable, Frame, Image, NextPageTemplate, PageBreak,
    PageTemplate, Paragraph, Spacer, Table, TableStyle,
)

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / 'output' / 'pdf' / 'Readme.pdf'
FONT = Path('C:/Windows/Fonts')
pdfmetrics.registerFont(TTFont('Korean', str(FONT / 'malgun.ttf')))
pdfmetrics.registerFont(TTFont('KoreanBold', str(FONT / 'malgunbd.ttf')))
pdfmetrics.registerFont(TTFont('CodeMono', str(FONT / 'consola.ttf')))
pdfmetrics.registerFontFamily('Korean', normal='Korean', bold='KoreanBold')
TEAL = colors.HexColor('#174D4B')
MUTED = colors.HexColor('#64736F')
styles = getSampleStyleSheet()
styles.add(ParagraphStyle('KRBody', fontName='Korean', fontSize=9.5, leading=14.5,
                          textColor=colors.HexColor('#263D37'), spaceAfter=6,
                          wordWrap='CJK'))
styles.add(ParagraphStyle('KRTitle', fontName='KoreanBold', fontSize=25, leading=34,
                          textColor=TEAL, spaceAfter=18, wordWrap='CJK'))
styles.add(ParagraphStyle('KRH2', fontName='KoreanBold', fontSize=15, leading=22,
                          textColor=TEAL, spaceBefore=0, spaceAfter=10,
                          keepWithNext=True, wordWrap='CJK'))
styles.add(ParagraphStyle('KRH3', fontName='KoreanBold', fontSize=11, leading=17,
                          textColor=TEAL, spaceBefore=6, spaceAfter=5,
                          keepWithNext=True, wordWrap='CJK'))
styles.add(ParagraphStyle('KRCode', fontName='CodeMono', fontSize=8.4, leading=12,
                          backColor=colors.HexColor('#EFF3F0'), borderPadding=8,
                          spaceBefore=3, spaceAfter=9, wordWrap='CJK'))
styles.add(ParagraphStyle('KRCell', parent=styles['KRBody'], fontSize=8.0,
                          leading=12, spaceAfter=0))
styles.add(ParagraphStyle('KRCaption', parent=styles['KRBody'], fontSize=8.8,
                          leading=14, textColor=MUTED, spaceAfter=9))
styles.add(ParagraphStyle('KRBullet', parent=styles['KRBody'], leading=13,
                          spaceAfter=3))


class CodeParagraph(Paragraph):
    """Keep the project's short command and structure blocks on one page."""

    def split(self, availWidth, availHeight):
        return []


def code_line(text: str) -> str:
    text = escape(text).replace(' ', '&nbsp;')
    text = re.sub(r'([가-힣]+)', r'<font name="Korean">\1</font>', text)
    return text


class FlowDiagram(Flowable):
    """Show the state update path and native app connection as small diagrams."""

    def __init__(self, kind: str):
        super().__init__()
        self.nodes = {
            'state': [
                ('사용자 동작', '추가·삭제·완료'),
                ('TodoNotifier', 'ref.read로 요청'),
                ('새 List<Todo>', 'state에 대입'),
                ('TodoScreen', 'ref.watch로 재구성'),
            ],
            'connection': [
                ('Windows 앱', 'native 프로세스'),
                ('Dart VM Service', '실행 데이터 연결'),
                ('DevTools', '브라우저의 검사 화면'),
            ],
        }[kind]
        self.height = 76

    def wrap(self, availWidth, availHeight):
        self.width = availWidth
        return self.width, self.height

    def draw(self):
        canvas = self.canv
        gap = 16
        node_width = (self.width - gap * (len(self.nodes) - 1)) / len(self.nodes)
        canvas.saveState()
        for index, (title, detail) in enumerate(self.nodes):
            x = index * (node_width + gap)
            canvas.setFillColor(colors.HexColor('#EFF5F1'))
            canvas.setStrokeColor(colors.HexColor('#B6CDC2'))
            canvas.roundRect(x, 14, node_width, 50, 5, stroke=1, fill=1)
            canvas.setFillColor(TEAL)
            canvas.setFont('KoreanBold', 9.3)
            canvas.drawCentredString(x + node_width / 2, 43, title)
            canvas.setFillColor(MUTED)
            canvas.setFont('Korean', 8)
            canvas.drawCentredString(x + node_width / 2, 26, detail)
            if index < len(self.nodes) - 1:
                start = x + node_width + 2
                end = x + node_width + gap - 2
                canvas.setStrokeColor(TEAL)
                canvas.line(start, 39, end, 39)
                canvas.line(end - 4, 42, end, 39)
                canvas.line(end - 4, 36, end, 39)
        canvas.restoreState()


def embedded_images(entries, layout):
    page_size = A4 if layout == 'Portrait' else landscape(A4)
    available = page_size[0] - 92
    paired = len(entries) == 2
    image_width = (available - 24) / 2 if paired else available
    image_height = 335 if paired else (500 if layout == 'Portrait' else 355)
    images, captions = [], []
    for caption, relative_path in entries:
        path = (ROOT / relative_path).resolve()
        path.relative_to((ROOT / 'docs' / 'screenshots').resolve())
        if not path.is_file():
            raise FileNotFoundError(f'Required screenshot is missing: {path}')
        with PILImage.open(path) as source_image:
            width, height = source_image.size
        scale = min(image_width / width, image_height / height)
        images.append(Image(str(path), width=width * scale, height=height * scale,
                            hAlign='CENTER'))
        captions.append(Paragraph(inline(caption), styles['KRCaption']))
    if paired:
        table = Table([captions, images], colWidths=[available / 2] * 2,
                      hAlign='CENTER')
        table.setStyle(TableStyle([
            ('VALIGN', (0, 0), (-1, -1), 'TOP'),
            ('ALIGN', (0, 1), (-1, 1), 'CENTER'),
            ('LEFTPADDING', (0, 0), (-1, -1), 6),
            ('RIGHTPADDING', (0, 0), (-1, -1), 6),
            ('TOPPADDING', (0, 0), (-1, -1), 0),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
        ]))
        return [table, Spacer(1, 8)]
    return [images[0], Spacer(1, 6), captions[0]]


def inline(text: str) -> str:
    text = escape(text)
    text = re.sub(r'\[([^\]]+)\]\((https?://[^)]+)\)',
                  r'<link href="\2" color="#176B60">\1</link>', text)
    text = re.sub(r'\*\*(.+?)\*\*', r'<b>\1</b>', text)
    text = re.sub(r'`([^`]+)`', r'<font color="#176B60">\1</font>', text)
    return text


def footer(canvas, document):
    width, height = canvas._pagesize
    canvas.saveState()
    canvas.setStrokeColor(colors.HexColor('#DCE5DF'))
    canvas.line(40, 38, width - 40, 38)
    canvas.setFont('Korean', 8)
    canvas.setFillColor(MUTED)
    canvas.drawString(40, 24, '오늘 할 일 | Flutter + Riverpod | v1.1')
    canvas.drawRightString(width - 40, 24, str(document.page))
    canvas.restoreState()


def table_flow(rows):
    content = [[Paragraph(inline(cell), styles['KRCell']) for cell in row]
               for row in rows]
    columns = len(rows[0])
    available = A4[0] - 80
    fractions = {2: [0.32, 0.68], 3: [0.24, 0.33, 0.43],
                 4: [0.16, 0.31, 0.38, 0.15]}.get(columns,
                                               [1 / columns] * columns)
    table = Table(content, colWidths=[available * x for x in fractions],
                  repeatRows=1, hAlign='LEFT')
    table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#E5ECE7')),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('LEFTPADDING', (0, 0), (-1, -1), 7),
        ('RIGHTPADDING', (0, 0), (-1, -1), 7),
        ('TOPPADDING', (0, 0), (-1, -1), 7),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 7),
        ('LINEBELOW', (0, 0), (-1, 0), 0.7, colors.HexColor('#B6CDC2')),
        ('LINEBELOW', (0, 1), (-1, -1), 0.3, colors.HexColor('#DCE5DF')),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1),
         [colors.white, colors.HexColor('#F7F9F7')]),
    ]))
    return [table, Spacer(1, 9)]


def markdown_flow(source):
    result = []
    lines = source.splitlines()
    index = 0
    layout = 'Portrait'
    while index < len(lines):
        line = lines[index].strip()
        if not line:
            index += 1
            continue
        page = re.fullmatch(r'<!-- page: (portrait|landscape) -->', line)
        diagram = re.fullmatch(r'<!-- diagram: (state|connection) -->', line)
        if page:
            layout = page[1].title()
            result.extend([NextPageTemplate(layout), PageBreak()])
        elif diagram:
            result.append(FlowDiagram(diagram[1]))
        elif line.startswith('```'):
            index += 1
            code = []
            while index < len(lines) and not lines[index].strip().startswith('```'):
                code.append(code_line(lines[index]))
                index += 1
            result.append(CodeParagraph('<br/>'.join(code), styles['KRCode']))
        elif line.startswith('|'):
            rows = []
            while index < len(lines) and lines[index].strip().startswith('|'):
                cells = [item.strip() for item in lines[index].strip().strip('|').split('|')]
                if not all(re.fullmatch(r'[:\-\s]+', item) for item in cells):
                    rows.append(cells)
                index += 1
            result.extend(table_flow(rows))
            continue
        elif line.startswith('!['):
            entries = []
            while index < len(lines) and lines[index].strip().startswith('!['):
                match = re.fullmatch(r'!\[(.*?)\]\((.*?)\)', lines[index].strip())
                if not match:
                    raise ValueError(f'Invalid screenshot reference: {lines[index]}')
                entries.append((match[1], match[2]))
                index += 1
            if not 1 <= len(entries) <= 2:
                raise ValueError('Place one screenshot or a before/after pair together.')
            result.extend(embedded_images(entries, layout))
            continue
        elif line.startswith('# '):
            result.append(Paragraph(inline(line[2:]), styles['KRTitle']))
        elif line.startswith('## '):
            result.append(Paragraph(inline(line[3:]), styles['KRH2']))
        elif line.startswith('### '):
            result.append(Paragraph(inline(line[4:]), styles['KRH3']))
        elif re.match(r'^[-*] ', line):
            bullets = []
            while index < len(lines) and re.match(r'^[-*] ', lines[index].strip()):
                bullets.append('• ' + inline(lines[index].strip()[2:]))
                index += 1
            result.append(Paragraph('<br/>'.join(bullets), styles['KRBullet']))
            continue
        elif re.match(r'^\d+\. ', line):
            result.append(Paragraph(inline(line), styles['KRBody']))
        elif line == '---':
            result.append(Spacer(1, 6))
        else:
            result.append(Paragraph(inline(line), styles['KRBody']))
        index += 1
    return result


def main():
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    document = BaseDocTemplate(str(OUTPUT), pagesize=A4, title='오늘 할 일 - Readme',
                               author='Flutter To Do Project', leftMargin=40,
                               rightMargin=40, topMargin=42, bottomMargin=52)
    portrait = Frame(40, 52, A4[0] - 80, A4[1] - 94, id='PortraitFrame')
    wide = landscape(A4)
    landscape_frame = Frame(40, 52, wide[0] - 80, wide[1] - 94, id='LandscapeFrame')
    document.addPageTemplates([
        PageTemplate(id='Portrait', frames=[portrait], pagesize=A4, onPage=footer),
        PageTemplate(id='Landscape', frames=[landscape_frame], pagesize=wide, onPage=footer),
    ])
    source = (ROOT / 'README.md').read_text(encoding='utf-8-sig')
    if len(re.findall(r'^!\[', source, re.MULTILINE)) != 9:
        raise ValueError('The assignment README must contain all nine screenshots.')
    document.build(markdown_flow(source))
    print(OUTPUT)


if __name__ == '__main__':
    main()
