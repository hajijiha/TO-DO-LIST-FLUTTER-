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
    BaseDocTemplate, Frame, Image, KeepTogether, NextPageTemplate, PageBreak,
    PageTemplate, Paragraph, Spacer, Table, TableStyle,
)

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / 'output' / 'pdf' / 'Readme.pdf'
FONT = Path('C:/Windows/Fonts')
pdfmetrics.registerFont(TTFont('Korean', str(FONT / 'malgun.ttf')))
pdfmetrics.registerFont(TTFont('KoreanBold', str(FONT / 'malgunbd.ttf')))
pdfmetrics.registerFontFamily('Korean', normal='Korean', bold='KoreanBold')
TEAL = colors.HexColor('#174D4B')
MUTED = colors.HexColor('#64736F')
styles = getSampleStyleSheet()
styles.add(ParagraphStyle('KRBody', fontName='Korean', fontSize=9.2, leading=15,
                          textColor=colors.HexColor('#263D37'), spaceAfter=6,
                          wordWrap='CJK'))
styles.add(ParagraphStyle('KRTitle', fontName='KoreanBold', fontSize=25, leading=34,
                          textColor=TEAL, spaceAfter=18, wordWrap='CJK'))
styles.add(ParagraphStyle('KRH2', fontName='KoreanBold', fontSize=15, leading=22,
                          textColor=TEAL, spaceBefore=14, spaceAfter=9,
                          keepWithNext=True, wordWrap='CJK'))
styles.add(ParagraphStyle('KRH3', fontName='KoreanBold', fontSize=11, leading=17,
                          textColor=TEAL, spaceBefore=9, spaceAfter=5,
                          keepWithNext=True, wordWrap='CJK'))
styles.add(ParagraphStyle('KRCode', fontName='Korean', fontSize=8.0, leading=12,
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
    while index < len(lines):
        line = lines[index].strip()
        if not line:
            index += 1
            continue
        if line.startswith('```'):
            index += 1
            code = []
            while index < len(lines) and not lines[index].strip().startswith('```'):
                code.append(escape(lines[index]).replace(' ', '&nbsp;'))
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
            # Images are collected as large, labeled appendix pages below.
            match = re.match(r'!\[(.*?)\]\((.*?)\)', line)
            if match:
                result.append(Paragraph('실행 화면: ' + inline(match[1]) +
                                        ' (뒤의 실제 캡처 부록 참조)', styles['KRCaption']))
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


def screenshot_flow():
    captions = [
        ('01_list.png', '리스트', 'Windows 네이티브 앱의 할 일 3개 목록. 강의 복습을 완료 체크하여 취소선과 체크 상태를 확인한다.'),
        ('02_add_input.png', '추가 전 입력', '새 제목 "README 작성"을 입력한 화면.'),
        ('03_add_result.png', '추가 결과', 'README 작성 항목이 추가되어 전체 목록이 4개가 된 화면.'),
        ('04_delete_before.png', '삭제 전', '삭제 대상 "운동하기"가 포함된 4개 항목.'),
        ('05_delete_after.png', '삭제 결과', '운동하기가 삭제되고 다른 3개 항목이 남은 화면.'),
        ('06_devtools_inspector.jpg', 'DevTools Inspector', 'Windows debug 앱에서 Column을 선택해 트리와 레이아웃을 검사했다. 너비 648.0, 높이 554.7, padding 16.'),
        ('07_devtools_timeline.jpg', 'DevTools Timeline', 'Windows profile 앱의 Performance > Timeline Events. todo.add 20건 검색 중 선택한 이벤트의 Category는 Dart, Duration은 116us다.'),
        ('08_devtools_memory.jpg', 'DevTools Memory', '20개 추가 후 10개 삭제, 완료 체크 1회 수행. GC와 Refresh 후 Todo 10개, TodoTile 10개를 확인했다. 짧은 관찰로 메모리 누수 여부를 단정하지 않는다.'),
        ('09_devtools_performance.jpg', 'DevTools Performance', '선택 프레임 390의 UI 0.3ms, Raster 8.0ms, Paint 0.1ms. Raster Jank Detected가 표시됐다. 촬영용 프레임 호출을 포함하므로 표시 FPS는 일반 사용 평균 성능으로 해석하지 않는다.'),
    ]
    result = []
    for filename, title, caption in captions:
        path = ROOT / 'docs' / 'screenshots' / filename
        if not path.exists():
            raise FileNotFoundError(f'Required screenshot is missing: {path}')
        with PILImage.open(path) as source_image:
            width, height = source_image.size
        page_size = A4 if height > width else landscape(A4)
        page_template = 'Portrait' if height > width else 'Landscape'
        available_width = page_size[0] - 80
        available_height = page_size[1] - 190
        result.extend([NextPageTemplate(page_template), PageBreak(),
                       Paragraph('실제 실행 캡처 | ' + title, styles['KRH2']),
                       Paragraph(caption, styles['KRCaption'])])
        scale = min(available_width / width, available_height / height)
        result.append(Image(str(path), width=width * scale, height=height * scale,
                            hAlign='CENTER'))
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
    document.build(markdown_flow(source) + screenshot_flow())
    print(OUTPUT)


if __name__ == '__main__':
    main()
